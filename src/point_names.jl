# Return one string name per utm position.
# Local storage prioritized.
# 

"""
    point_names(vsutm; locmarker = '·', koordsys = 25833, radius = 150, online = true,
        accept = ["Fjell", "Fjell i dagen", "Fjellkant", "Fjellområde", "Fjellside", "Fjelltopp i sjø", 
        "Annen terrengdetalj", "Berg", "Egg", "Haug", "Hei", "Høyde", "Rygg", 
        "Stein", "Topp", "Utmark", "Varde", "Vidde", "Ås"])
    ---> Vector{String}

Fetches a string name or empty string for each coordinate in `vsutm` within the specified `radius`, using data from:
- Primarily file homedir()/$LOCAL_FNAM. 
- Secondary online database $BASE_URL.

# Arguments
- `vsutm`: List of coordinates (positions) to search for, each given as a string in the format `"3232,343223"`.
- `koordsys`: Coordinate system identifier, where `25833` corresponds to UTM33N.
- `radius`: A distance threshold within which a name must fall to be considered relevant.
- `online`: If false, avoids requesting names from online API.
- 'accept': Acceptable name object types from '/punkt'. To find schema 'accept' values: `get_stadnamn_data("/navneobjekttyper", Dict{Symbol, Any}())`. The schema is incomplete.
- 'locmarker': Prefix for names taken from $LOCAL_FNAM. '' means no prefix.

# Data Sources and Priority
- **Local Source (CSV File)**:
  - Primary source, preferred over the API.
  - The closest name within the radius is returned.
  - **Conflict Handling**:
    - If two names are equally close, raises an error with feedback.

- **API Source (Online Database)**:
  - Secondary source, used only if no unique name is found within the radius from the local source, and `online` = true.
  - **Filtering Rules**:
    - Obeys 'radius' from the inpu location.
    - Returns point names according to argument `accept`. Note that the database has types not in its own schema.
    - Unique (considering the online request) candidates are elected first.
    - Prefers the candidate closest to the request position.

# Behavior with no match
If no name is found within the radius, an empty string is returned for that coordinate.

# Example
Given a 150-meter radius and three input positions from Online Database:
1. **Input Position 1**:
   - Closest names within 150m are "Storebakken" at 120m, "Marafallet" at 130m and a generic "Gårdsplass" at 80m.
2. **Input Position 2**:
   - Closest name within 150m is the generic "Gårdsplass" at 130m.
3. **Input Position 3**:
   - Closest name within 150m is "Lillehaugen" at 90m.

**Result**:
- Position 1 returns "Storebakken" (unique name preferred over generic "Gårdsplass" and farther "Marafallet").
- Position 2 returns "Gårdsplass" (generic name chosen as no unique name is available).
- Position 3 returns "Lillehaugen" (unique name within the radius).

*Note*: The choice of name for Position 1 and Position 2 is not affected by the availability of "Storebakken" or any other name for Position 3. Each position is evaluated independently based on its closest name within the radius.

# Errors
- Errors are raised if:
  - Two positions in $LOCAL_FNAM are equal.
  - Two positions in $LOCAL_FNAM are equidistant from an input position.
  - A name in $LOCAL_FNAM contains ','.
"""
function point_names(vsutm; locmarker = '·', koordsys = 25833, radius = 150, online = true,
    accept = ["Fjell", "Fjell i dagen", "Fjellkant", "Fjellområde", "Fjellside", "Fjelltopp i sjø", 
        "Annen terrengdetalj", "Berg", "Egg", "Haug", "Hei", "Høyde", "Rygg", 
        "Stein", "Topp", "Utmark", "Varde", "Vidde", "Ås"])
    # If a point name is defined in local data, we don't need to retrieve anything online.
    lpn = local_points_names(vsutm::Vector{String}; radius, locmarker)
    ind_nf = findall(isempty, lpn)
    if online
        opn = online_points_names(vsutm[ind_nf]; koordsys , radius, accept)
    else
        opn = ["" for i in ind_nf]
    end
    map(enumerate(lpn)) do (i, lnam)
        lnam == ""
    end
    # Mix the two name lists, using opn where lpn is lacking
    online_i = 0
    map(lpn) do lnam
        if lnam == ""
            online_i += 1
            opn[online_i]
        else
            lnam 
        end
    end
end

function local_points_names(vsutm; radius = 150, locmarker = '·')
    # Assign output, the selected name for each position
    elected_names = similar(vsutm)
    # Read local data
    ffnam = joinpath(homedir(), LOCAL_FNAM)
    if ! isfile(ffnam)
        @warn "Could not find any local name and positions file, $ffnam"
        fill!(elected_names, "")
        return elected_names
    end
    data = readdlm(ffnam, '\t') # No header, tab separated
    @assert size(data, 2) == 2
    # Candidate names
    vnam = strip.(data[:, 1])
    if any(contains.(vnam, ','))
        throw(ArgumentError("Illegal character ',' found, check input $ffnam"))
    end
    # Candidate positions
    vpos = map(enumerate(data[:, 2])) do (line, spos)
        t = Tuple(tryparse.(Int64, split(spos)))
        if isempty(t)
            throw("Could not interprete position in $ffnam line no. $line: \"$spos\"")
        end
        t
    end
    # Check for duplicate positions defined
    if length(unique(vpos)) < length(vpos)
        # Find the non-uniqe positions
        countpos = Dict{eltype(vpos), Int64}()
        foreach(pos -> push!(countpos, pos => get(countpos, pos, 0) + 1), vpos)
        non_unique = [k for (k, count) in countpos if count > 1]
        msg = "Duplicate positions detected, check input $ffnam: "
        println(msg)
        @show non_unique vpos
        println.(map(pos -> "$(pos[1]) $(pos[2])",non_unique))
        throw(ArgumentError(msg))
    end
    # Euclidean distance point to point, up to max radius
    fdist = (easting, northing, pos) -> hypot(pos[1] - easting, pos[2] - northing)
    # Find the minimum distance indices (there should be only one, but check)
    fclosest_index = (easting, northing) -> let vpos = vpos, vnam = vnam, radius = radius
        mindist, minind = findmin(pos -> fdist(easting, northing, pos), vpos)
        # Return if none found close enough
        mindist > radius && return 0
        # Find all indices at this mininum distance
        minima_indices = findall(pos-> fdist(easting, northing, pos) == mindist, vpos)
        # Warn about multiple closest points
        if length(minima_indices) > 1
            msg = "Could not determine one closest position and name to ($easting $northing)\n"
            for i in minima_indices
                msg *= "\t $(vpos[i])   $(vpos[i]) \n"
            end
            throw(ErrorException(msg))
        end
        minind
    end
    closest_indices = map(vsutm) do sutm
        easting = tryparse(Int, strip(split(sutm, ',')[1]))
        northing = tryparse(Int, strip(split(sutm, ',')[2]))
        fclosest_index(easting, northing)
    end
    # Return the corresponding names (or empty string for index 0)
    map(closest_indices) do i
        i == 0 ? "" : locmarker * vnam[i]
    end
end

function online_points_names(vsutm::Vector{String}; koordsys = 25833, radius = 150,
    accept = ["Fjell", "Fjell i dagen", "Fjellkant", "Fjellområde", "Fjellside", "Fjelltopp i sjø", 
        "Annen terrengdetalj", "Berg", "Egg", "Haug", "Hei", "Høyde", "Rygg", 
        "Stein", "Topp", "Utmark", "Varde", "Vidde", "Ås"])
    # Assign output, the selected name for each position
    elected_names = similar(vsutm)
    # Remaining unresolved indices
    indices = collect(1:length(vsutm))
    resolved = Int64[]
    # Assign intermediate dictionary
    # Get the candidates with metadata
    nested_candidates = online_points_nested_objects(vsutm; radius, koordsys, accept)
    @assert length(nested_candidates) == length(vsutm)
    # Dictionary namestring => [applicable position numbers]
    cdic = candidates_dic(nested_candidates)
    #
    # Algorithm to pick a single name per position 
    #
    #
    # Elect from the candidates that do not apply to more than one position,
    # and truncate 'cdic' for better debugging overview.
    #
    for (i, l1) in zip(indices, nested_candidates) # i is position no
        point_radius = radius
        point_candidate = ""
        for l2 in l1
            r = l2.meterFraPunkt
            l3 = l2.stedsnavn
            for l4 in l3
                # We're not using this field, actually (but might)
                writing = l4.skrivemåte
                if length(cdic[writing]) == 1
                    # If a position has multiple unique candidates, prefer
                    # the closest, or simply the first.
                    if r < point_radius
                        point_candidate = writing
                        point_radius = r
                    end
                end
            end
        end
        elected_names[i] = point_candidate
        # Did we pick an actual name for i?
        if point_candidate !== ""
            # Truncate cdic.
            pop!(cdic, point_candidate)
            # Mark position i as resolved, for future loops
            push!(resolved, i)
        end
    end
    # Drop resolved positions from the following loop
    setdiff!(indices, resolved)
    #
    for i in indices  # i is position no without a nominee
        l1 = nested_candidates[i]
        point_candidate = ""
        for l2 in l1
            l3 = l2.stedsnavn
            if length(l3) == 1
                l4 = first(l3)
                writing = l4.skrivemåte
                point_candidate = writing
            end
        end
        elected_names[i] = point_candidate
        # Did we pick an actual name for i?
        if point_candidate !== ""
            # Also drop i from the list of places to apply point_candidate.
            shortenedlist = setdiff(cdic[point_candidate], i)
            if length(shortenedlist) > 0
                push!(cdic, point_candidate => shortenedlist)
            else
                pop!(cdic, point_candidate)
            end
        end
        # Mark i as resolved
        push!(resolved, i)
    end
    # Drop i 
    setdiff!(indices, resolved)
    if length(indices) > 0
        @show indices cdic
        throw("Consider why some remain....")
    end
    elected_names
end


function candidates_dic(nested_candidates)
    dic = Dict{String, Vector{Int}}()
    for (i, l1) in enumerate(nested_candidates)
        foreach(l1) do l2
            l3 = l2.stedsnavn
            foreach(l3) do l4
                l5 = l4.skrivemåte
                if haskey(dic, l5)
                    push!(dic, l5 => vcat(dic[l5], i))
                else
                    push!(dic, l5 => [i])
                end
            end
        end
    end
    dic
end



"""
    online_points_nested_objects(vsutm::Vector{String}; koordsys = 25833, radius = 150,
        accept = ["Fjell", "Fjell i dagen", "Fjellkant", "Fjellområde", "Fjellside", "Fjelltopp i sjø", 
            "Annen terrengdetalj", "Berg", "Egg", "Haug", "Hei", "Høyde", "Rygg", 
            "Stein", "Topp", "Utmark", "Varde", "Vidde", "Ås"])
    --> Vector{Vector{JSON3.Object}}


"""
function online_points_nested_objects(vsutm::Vector{String}; koordsys = 25833, radius = 150,
    accept = ["Fjell", "Fjell i dagen", "Fjellkant", "Fjellområde", "Fjellside", "Fjelltopp i sjø", 
        "Annen terrengdetalj", "Berg", "Egg", "Haug", "Hei", "Høyde", "Rygg", 
        "Stein", "Topp", "Utmark", "Varde", "Vidde", "Ås"])
    map(vsutm) do sutm
        easting = tryparse(Int, strip(split(sutm, ',')[1]))
        northing = tryparse(Int, strip(split(sutm, ',')[2]))
        online_point_objects(easting, northing; radius, koordsys, accept)
    end
end

"""
    online_point_objects(easting::Int64, northing::Int64; radius::Int64 = 150, koordsys = 25833,
            accept = ["Fjell", "Fjell i dagen", "Fjellkant", "Fjellområde", "Fjellside", "Fjelltopp i sjø", 
                "Annen terrengdetalj", "Berg", "Egg", "Haug", "Hei", "Høyde", "Rygg", 
                "Stein", "Topp", "Utmark", "Varde", "Vidde", "Ås"])
   --->  Vector{JSON3.Object}

Return a vector of name objects for one point.

# Example
```
julia> Stadnamn.online_point_objects(47965, 6911108)
1-element Vector{JSON3.Object}:
 {
     "meterFraPunkt": 26,
   "navneobjekttype": "Ås",
         "stedsnavn": [
                        {
                                 "navnestatus": "hovednavn",
                                  "skrivemåte": "Reiteåsane",
                            "skrivemåtestatus": "godkjent og prioritert",
                                       "språk": "Norsk",
                             "stedsnavnnummer": 1
                        }
                      ]
}
```
"""
function online_point_objects(easting::Int64, northing::Int64; radius::Int64 = 150, koordsys = 25833,
    accept = ["Fjell", "Fjell i dagen", "Fjellkant", "Fjellområde", "Fjellside", "Fjelltopp i sjø", 
        "Annen terrengdetalj", "Berg", "Egg", "Haug", "Hei", "Høyde", "Rygg", 
        "Stein", "Topp", "Utmark", "Varde", "Vidde", "Ås"])
    endpoint = "/punkt"
    params = Dict{Symbol, Any}(:koordsys => koordsys,
                        :utkoordsys => koordsys,
                        :nord => northing,
                        :ost => easting,
                        :radius => radius,
                        :filtrer => "navn.stedsnavn,navn.meterFraPunkt,navn.navneobjekttype")
    jsono = get_stadnamn_data(endpoint, params)
    if isempty(jsono)
        # Something went wrong. Don't error!
        return JSON3.Object[]
    end
    lv1 = jsono.navn
    if isempty(lv1)
        return JSON3.Object[]
    else
        @assert first(lv1) isa JSON3.Object{Vector{UInt8}, SubArray{UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}}
        return filter(lv1) do obj
            obj.navneobjekttype ∈ accept
        end
    end
end


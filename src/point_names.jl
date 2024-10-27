# Return one string name per utm position.
# Local storage prioritized.
# 

"""
    point_names(vsutm; koordsys = 25833, radius = 150) -> Vector{String}

Fetches names for each coordinate in `vsutm` within the specified `radius`, using data from two sources:
a local CSV file and an online API. Returns a list with names or empty strings if no name is found.

# Arguments
- `vsutm`: List of coordinates (positions) to search for, each given as a string in the format `"3232,343223"`.
- `koordsys`: Coordinate system identifier, where `25833` corresponds to UTM33N.
- `radius`: A distance threshold within which a name must fall to be considered relevant.
- 'accept': Acceptable name object types. To find possible 'accept' values: `get_stadnamn_data("/navneobjekttyper", Dict{Symbol, Any}())` 

# Data Sources and Priority
- **Local Source (CSV File)**:
  - Primary source, preferred over the API.
  - The closest name within the radius for each input coordinate is returned.
  - **Conflict Handling**:
    - If two names are equally close, raises an error with feedback.
    - If two names occupy the same exact position, raises an error with feedback.

- **API Source (Online Database)**:
  - Secondary source, used only if no unique name is found within the radius from the local source.
  - **Filtering Rules**:
    - Returns only point names, excluding regional and path names.
    - Avoids generic names if a unique name is available within the radius.


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
  - Two names in the local source are equidistant from an input position.
  - Two names in the local source occupy the same exact position.
"""
function point_names(vsutm; koordsys = 25833, radius = 150,
    accept = ["Fjell", "Fjell i dagen", "Fjellkant", "Fjellområde", "Fjellside", "Fjelltopp i sjø", 
        "Annen terrengdetalj", "Berg", "Egg", "Haug", "Hei", "Høyde", "Rygg", 
        "Stein", "Topp", "Utmark", "Varde", "Vidde", "Ås"])
    # If a point name is defined in local data, we don't need to retrieve anything online.
    # The local part is not yet implemented.
    online_points_names(vsutm::Vector{String}; koordsys , radius, accept)
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


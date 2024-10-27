# Stadnamn.jl
Minimal interface to the name register API https://api.kartverket.no/stedsnavn/v1


# What does it do?

- High level function selects one name per position from a local and online data.
- Low level functions return a JSON3 Object, which will be empty if an error occured. Errors will print to stdout.


# Functions

## `point_names`

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


## `get_stadnamn_data`

Based on info retrieved with 'explore', we'll use that endpoint:

```
julia> endpoint = "/punkt";

julia> params = Dict(:koordsys => 25833,
                     :utkoordsys => 25833,
                     :nord => 6939589,
                     :ost => 51796,
                     :radius => 50,
                     :filtrer => "navn.stedsnavn");

julia> o = get_stadnamn_data(endpoint, params)
JSON3.Object{Vector{UInt8}, Vector{UInt64}} with 2 entries:
  :metadata => {…
  :navn     => Object[{…
... 

julia> get.(o.navn[1].stedsnavn, "skrivemåte")
2-element Vector{String}:
 "Jønshornet"
 "Ramoen"
```


## `explore`

This function is for digging into the open API specficiation, a JSON object we retrieve online. Use this for constructing your requests (you will have to build a dictionary with the parameters).

```
julia> explore();
https://api.kartverket.no/stedsnavn/v1/openapi.json
   components
   info
   openapi
   paths
   servers

julia> explore("paths");
   paths
      /navn
      /navneobjekttyper
      /punkt
      /sprak
      /sted

julia> explore("paths/punkt");
      paths/punkt
         get

julia> explore("paths/punkt/get");
         paths/punkt/get
            description
            parameters
            responses
            summary

julia> oparams = explore("paths/punkt/get/parameters");
...
julia> explore("paths/punkt/get/parameters/3");
...

julia> oparams
...
```

See inline docs; you can use explore to dig into other json objects, like 'oparams'.

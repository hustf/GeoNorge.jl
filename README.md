# Stadnamn.jl
Minimal interface to the name register API https://api.kartverket.no/stedsnavn/v1


# What does it do?

Every function returns a JSON3 Object, which will be empty if an error occured. Errors will print to stdout.

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

# Onlne-only API functions here
"""
    get_stadnamn_data(url::String)
    get_stadnamn_data(endpoint, params::Dict)
    ---> JSONO

# Example

```
julia> endpoint = "/punkt"
"/punkt"

julia> sutm = "26053,6910869" # UTM easting, northing
"26053,6910869"

julia> params = Dict(:koordsys => 25833,                                                                                                                                                                                                                                                                                                 
           :utkoordsys => 25833,                                                                                                                                                                                                                                                                                                         
           :nord => split(sutm, ',')[2],                                                                                                                                                                                                                                                                                                 
           :ost => split(sutm, ',')[1],                                                                                                                                                                                                                                                                                                  
           :radius => 150,                                                                                                                                                                                                                                                                                                               
           :filtrer => "navn.stedsnavn,navn.meterFraPunkt")
Dict{Symbol, Any} with 6 entries:
  :ost        => "26053"
  :koordsys   => 25833
  :utkoordsys => 25833
  :radius     => 150
  :filtrer    => "navn.stedsnavn,navn.meterFraPunkt"
  :nord       => "6910869"

julia> get_stadnamn_data(endpoint, params)
JSON3.Object{Vector{UInt8}, Vector{UInt64}} with 1 entry:
  :navn => Object[{…
```

"""
get_stadnamn_data(endpoint, params::Dict) = get_stadnamn_data(get_stadnamn_url(endpoint, params))
function get_stadnamn_data(url::String)
    response = try
         HTTP.get(url)
    catch e
        # Catch HTTP errors like 404, 500, etc.
        printstyled("HTTP request failed \n", color = :green)
        printstyled("    Request url: $url", "\n", color = :green)
        @show e  # Display the full error object for debugging
        return JSON3.Object()  # Return an empty JSON object to signify failure
    end
    if response.status == 200
        try
            return JSON3.read(response.body)
        catch e
            printstyled("Failed to parse JSON. Response body: \n\t", color = :green)
            printstyled(String(response.body), "\n", color = :yellow)
            return JSON3.Object()
        end
    else
        printstyled("Error: Received status code ", response.status, "\n\t", color = :green)
        printstyled("Response body: ", String(response.body), "\n\t", color = :yellow)
        return JSON3.Object()
    end
end

function construct_url(base_url::String, endpoint::String, params::Dict)
    query_string = "?" * join([string(k) * "=" * string(v) for (k, v) in params], "&")
    base_url * endpoint * query_string
end
function get_stadnamn_url(endpoint, params::Dict; base_url = BASE_URL)
    startswith(endpoint, "/") || throw(ArgumentError("endpoint must start with '/'. Got: $endpoint"))
    endswith(endpoint, "/") && throw(ArgumentError("endpoint can't end with '/'. Got: $endpoint"))
    construct_url(base_url, endpoint, params)
end


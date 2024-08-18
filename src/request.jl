function get_stadnamn_data(url::String)
    try
        response = HTTP.get(url)
    catch e
        # Catch HTTP errors like 404, 500, etc.
        printstyled("HTTP request failed: ", color = :green)
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
get_stadnamn_data(params::Dict) = get_stadnamn_data(get_stadnamn_url(params))

function construct_url(base_url::String, endpoint::String, params::Dict{String, String})
    query_string = "?" * join([k * "=" * v for (k, v) in params], "&")
    return base_url * endpoint * query_string
end
function get_stadnamn_url(params::Dict{String, String})
    base_url = "https://api.kartverket.no/stedsnavn/v1"
    endpoint = "/stedsnavn"
    return construct_url(base_url, endpoint, params)
end
module Stadnamn
    using HTTP
    using JSON3
    export get_stadnamn_url, get_stadnamn_data, explore
    include("request.jl")
    include("utils.jl")

end

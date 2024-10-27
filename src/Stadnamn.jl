module Stadnamn
    using HTTP
    using JSON3
    export get_stadnamn_url, get_stadnamn_data, explore, point_names
    include("request.jl")
    include("point_names.jl")
    include("utils.jl")
end

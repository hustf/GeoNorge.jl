module Stadnamn
using HTTP
using JSON3
import DelimitedFiles
using DelimitedFiles: readdlm
export get_stadnamn_url, get_stadnamn_data, explore, point_names
include("request.jl")
include("point_names.jl")
include("utils.jl")
const LOCAL_FNAM = "Stadnamn.csv"
const BASE_URL = "https://api.kartverket.no/stedsnavn/v1"
end

# Stadnamn.jl
using Test
using Stadnamn
endpoint = "/punkt"
params = Dict(:koordsys => 25833,
                     :utkoordsys => 25833,
                     :nord => 6939589,
                     :ost => 51796,
                     :radius => 50,
                     :filtrer => "navn.stedsnavn")
o = get_stadnamn_data(endpoint, params)
vnams =  get.(o.navn[1].stedsnavn, "skrivemåte")
@test vnams = ["Jønshornet", "Ramoen"]

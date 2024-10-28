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
@test all(vnams .== ["Jønshornet", "Ramoen"])


# Navneobjekttype

@test isempty(Stadnamn.online_point_objects(47529,6911394))
@test ! isempty(Stadnamn.online_point_objects(47965,6911108))

vsutm = ["47529,6911394", "47965,6911108"]
@test length(Stadnamn.online_points_nested_objects(vsutm)) == 2
@test Stadnamn.online_points_names(vsutm) == ["", "Reiteåsane"]
@test point_names(vsutm) == ["", "Reiteåsane"]


vsutm = ["47965,6911108", # Reiteåsane
         "43824,6928853", # Sandhornet, close, no alternative
         "48180,6928237" # Another 'Sandhornet', a bit further from the name, no alternative
       ]

@test Stadnamn.online_points_names(vsutm) == ["Reiteåsane", "Sandhornet", "Sandhornet"]
@test point_names(vsutm) == ["Reiteåsane", "·Sandhornet", "·Sandhornet"]

vsutm = ["47965,6911108", # Reiteåsane
         "43824,6928853", # Sandhornet, close, no alternative
         "48180,6928237",  # Another 'Sandhornet', a bit further from the name, no alternative
         "29801,6915399"  # Yet another 'Sandhornet', very close, has one alternative
       ]

@test length(Stadnamn.online_points_nested_objects(vsutm)[4][1].stedsnavn) == 2

@test Stadnamn.online_points_names(vsutm) == ["Reiteåsane", "Sandhornet", "Sandhornet", "Blåfjellet"]
@test point_names(vsutm) == ["Reiteåsane", "·Sandhornet", "·Sandhornet", "·Sandhornet (Blåfjellet)"]

vsutm = ["47965,6911108", # Reiteåsane
         "43824,6928853", # Sandhornet, close, no alternative
         "48180,6928237",  # Another 'Sandhornet', a bit further from the name, no alternative
         "29801,6915399",  # Yet another 'Sandhornet', very close, has one alternative
         "39951,6923774",  # Sandhornet, close no alternative
         "459539,7444076"] # Yet another 'Sandhornet', exact, no alternative

@test Stadnamn.online_points_names(vsutm) == ["Reiteåsane", "Sandhornet", "Sandhornet", "Blåfjellet", "Sandhornet", "Sandhornet"]

vsutm = ["40400,6917295", # Blåfjellet, no alt.
         "70592,6898043", # Blåfjellet, Storsvornibba, Holtafjellet
         "32181,6869544"] # Holtafjellet
@test Stadnamn.online_points_names(vsutm) == ["Blåfjellet", "Storsvornibba", "Holtafjellet"]

vsutm = ["60030,6935104", # Saudehornet
         "40697,6931960"] # Sauehornet, Saudehornet
@test Stadnamn.online_points_names(vsutm) == ["Saudehornet", "Sauehornet"]
@test point_names(vsutm) == ["·Trandalhatten (Saudehornet)", "·Saudehornet"]
# The preference for unique names will pick those, even when further away, when the radius is large.
@test Stadnamn.online_points_names(vsutm; radius = 4500)  == ["Staven", "Saudehaugen"]

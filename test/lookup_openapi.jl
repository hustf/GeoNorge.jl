# Some exploring
using Stadnamn


openapi_spec = explore()
openapi_spec[:info]
openapi_spec[:info][:version]

explore("info")
   info
      description
      title
      version

explore("paths/punkt/get/parameters");

oo = explore("paths/punkt/get/parameters/8")

explore("components/schemas/Navneobjekttype/properties/navneobjekttype")

# We need to go online to get the actual list of navneobjekttype:
noty = get_stadnamn_data("/navneobjekttyper", Dict{Symbol, Any}())
vtyp = map(o -> o.navneobjekttype, noty)
println.(sort(vtyp)); # 291 elements


["Annen terrengdetalj",
"Berg",
"Egg",
"Fjell",
"Fjell i dagen",
"Fjellkant",
"Fjellområde",
"Fjelltopp i sjø",
"Haug",
"Hei",
"Høyde",
"Rygg",
"Stein",
"Topp",
"Utmark",
"Varde",
"Vidde",
"Ås"]



	


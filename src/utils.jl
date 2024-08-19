"""
    explore()
    explore(string_path)
    ---> JSON3.Object or JSON3.Array

# Example
In the REPL you might inspect like this:
```
julia> openapi_spec = explore()
JSON3.Object{Vector{UInt8}, Vector{UInt64}} with 5 entries:
  :components => {…
  :info       => {…
  :openapi    => "3.0.3"
  :paths      => {…
  :servers    => Object[{…

julia> openapi_spec[:info]
JSON3.Object{Vector{UInt8}, SubArray{UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}} with 3 entries:
  :description => "\nAPI for søk etter stedsnavn. Man kan for eksempel søke etter et navn, et ste…
  :title       => "Kartverkets åpne API for søk etter stedsnavn"
  :version     => "1.1"

julia> openapi_spec[:info][:version]
"1.1"

julia> explore("info");
   info
      description
      title
      version
julia> explore("paths/punkt/get/parameters");
            paths/punkt/get/parameters
               [1]
                     1
                        description
                        in
                        name
                        required
                        schema
               [2]
                     2
                        description
                        ....

julia> explore("paths/punkt/get/parameters/5/name");
                  paths/punkt/get/parameters/5/name
                     "utkoordsys"
  
```

"""
explore() = explore("")
function explore(string_path;  level = 0)
    obj =  get_stadnamn_data("https://api.kartverket.no/stedsnavn/v1/openapi.json")
    explore(string_path, obj;  level)
end
function explore(string_path, obj;     level = 0)
    # To find the object to examine we must access it by steps
    string_steps = splitpath(strip(string_path, '/'))
    
    if isempty(string_steps[1])
        print_level(level, "https://api.kartverket.no/stedsnavn/v1/openapi.json", obj)
        return obj
    end
    for step in string_steps
        level += 1
        if isnothing(tryparse(Int, step))
            # So, so, ugly exception here:
            if level == 2 && string_steps[1] == "paths"
                sy = Symbol("/" * step)
            else
                sy = Symbol(step)
            end
            obj = try
                get(obj, sy)
            catch e
                @error keys(obj)
                rethrow(e)
            end
        else
            obj = try
                getindex(obj, parse(Int, step))
            catch e
                @error keys(obj)
                rethrow(e)
            end
        end
    end
    print_level(level, string_path, obj)
    return obj
end
function print_level(level, string_path, obj::JSON3.Object)
    indent = repeat(' ', 3 * level)
    nextindent = repeat(' ', 3 * (level + 1))
    color = level + 2
    printstyled(indent, string_path, "\n"; color )
    for key in keys(obj)
        printstyled(nextindent, string(key), "\n"; color = color + 1)
    end
end
function print_level(level, string_path, obj::JSON3.Array)
    indent = repeat(' ', 3 * level)
    nextindent = repeat(' ', 3 * (level + 1))
    color = level + 2
    printstyled(indent, string_path, "\n"; color )
    for (i, o) in enumerate(obj)
        printstyled(nextindent, "[$i]\n"; color = color + 1)
        explore("$i", obj;     level = level + 2)
    end
end
function print_level(level, string_path, obj::String)
    indent = repeat(' ', 3 * level)
    nextindent = repeat(' ', 3 * (level + 1))
    color = level + 2
    printstyled(indent, string_path, "\n"; color )
    printstyled(nextindent, "\"$obj\""; color = color + 1)
end

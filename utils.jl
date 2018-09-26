# utility functions for the main parser

function concatSubstrings(l::Array{SubString})
    s = ""
    for e in l
        s * " " * e
    end
    return s
end

function default_parse(t::Type,l::Any, default::Any)
    res = tryparse(t, l)
    if typeof(res) == Nothing
        # i.e. if parsing failed
        print("Parse failed on $l")
        return default
    end
    return res
end

function create_open_file(fname)
    if !isfile(fname)
        touch(fname)
    end
    f = open(fname, "w+")
    return f
end

function getfields(obj)
    t = typeof(obj)
    fields = fieldnames(t)
    names = [getfield(obj, field) for field in fields]
    return names
end

function stringify_array(arr::Array{Any})
   return [string(a) for a in arr] 
end
    
function get_column_index(arr::Array{AbstractString},key::AbstractString)
    return findfirst(arr, key)
end

module ParsingTools

export
    Token,
    tokenize

using Compat

@compat public anchored!, normalize_code

include("types.jl")
include("tokenize.jl")

end # module

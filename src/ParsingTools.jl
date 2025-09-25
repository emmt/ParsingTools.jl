module ParsingTools

export
    Token,
    tokenize,

    # Predicates.
    is_asterisk,
    is_closing,
    is_closing_brace,
    is_closing_bracket,
    is_closing_parenthesis,
    is_comma,
    is_comment,
    is_escape_newline,
    is_identifier,
    is_opening,
    is_opening_brace,
    is_opening_bracket,
    is_opening_parenthesis,
    is_operator,
    is_semicolon,
    is_separator

using Compat

@compat public anchored!, normalize_code

include("types.jl")
include("tokens.jl")
include("tokenize.jl")

end # module

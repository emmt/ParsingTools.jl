module ParsingTools

export
    Token,
    tokenize,

    # Predicates.
    is_asterisk,
    is_character,
    is_closing,
    is_closing_brace,
    is_closing_bracket,
    is_closing_parenthesis,
    is_comma,
    is_comment,
    is_escape_newline,
    is_float,
    is_identifier,
    is_integer,
    is_literal,
    is_number,
    is_opening,
    is_opening_brace,
    is_opening_bracket,
    is_opening_parenthesis,
    is_operator,
    is_semicolon,
    is_separator,
    is_string

using Compat

@compat public anchored!, normalize_code

include("types.jl")
include("tokens.jl")
include("tokenize.jl")

end # module

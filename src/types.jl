# The line must be registered for pre-processor directives (which must fit on a line except
# if end-of-line is escaped by a backslash).
struct Token
    text::SubString{String}
    type::Symbol
    line::Int
end

# Alias to the type of pair than be converted to a token object.
const TokenAsPair = Pair{<:AbstractString,<:Tuple{Symbol,Integer}}

# String for '|' character (useful to display a Markdown table).
const PIPE = "ǀ" # HTML code: "&#124;"

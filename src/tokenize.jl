"""
    t = Token(text, type, line)
    t = Token(text => (type, line))

Build an object representing a code token. Arguments `text`, `type`, and `line` are
respectively the token as written in the code, its type (a `Symbol`), and the (starting)
line number in the code. These elements can be retrieved by `t.text`, `t.type` and `t.line`.

"""
Token((text,(type,line))::TokenAsPair) = Token(text, type, line)

Base.convert(::Type{Token}, t::Token) = t
Base.convert(::Type{Token}, t::TokenAsPair) = Token(t)::Token

Base.show(io::IO, t::Token) =
    print(io, "Token(\"", escape_string(t.text), "\" => (:", t.type, ", ", t.line, "))")

for f in (:(==), :isequal)
    @eval Base.$f(A::Token, B::Token) =
        A === B || ($f(A.type, B.type) && $f(A.line, B.line) && $f(A.text, B.text))
end

"""
    ParsingTools.normalize_code(str) -> str′::String

Replace CR and CR-LF by LF in code string `str` and convert it to a regular `String` (for
type stability).

"""
@noinline function normalize_code(str::AbstractString)
    if findfirst('\r', str) !== nothing
        return convert(String, replace(str, r"\r\n?" => "\n"))::String
    else
        return convert(String, str)::String
    end
end

"""
    ParsingTools.anchored!(re) -> re

Set the `PCRE.ANCHORED` option of a the regular expression `re` and return it.

"""
function anchored!(re::Regex)
    # See https://stackoverflow.com/questions/46288987/
    re.match_options |= Base.PCRE.ANCHORED
    return re
end

"""
    tokenize(lang, code) -> tokens::Vector{Token}

Extract tokens from string `code` according to language `lang`.

"""
tokenize(lang::Symbol, code::AbstractString; kwds...) =
    tokenize(Val(lang), code; kwds...)

# By default automatically normalize code.
@noinline tokenize(lang::Val, code::AbstractString) =
    tokenize(lang, convert(String, code)::String)

"""
    tokenize(; lang, file) -> tokens::Vector{Token}

Load code from `file` and extract its tokens according to language `lang`.

"""
tokenize(; lang::Symbol, file::AbstractString, kwds...) =
    tokenize(lang, open(file, "r") do io; read(io, String); end; kwds...)

# Error catcher.
@noinline tokenize(::Val{lang}, code::String; kwds...) where {lang} =
    throw(ArgumentError("no tokenizer is implemented for language \"$lang\""))

"""
    tokenize(:C, str) -> tokens::Vector{Token}

Extract tokens from C code in string `str`. In the resulting vector of tokens, each token
has fields `text`, `type`, and `line` which are respectively the token as written in the
code, its type (a `Symbol`), and the (starting) line number in the code.

The following table summarizes the possible associations:

| Sequence | Type        | Sequence | Type        | Sequence | Type         |
|:---------|:------------|:---------|:------------|:---------|:-------------|
| `=`      | `:operator` | `-`      | `:operator` | `:`      | `:separator` |
| `==`     | `:operator` | `-=`     | `:operator` | `;`      | `:separator` |
| `*`      | `:operator` | `--`     | `:operator` | `,`      | `:separator` |
| `*=`     | `:operator` | `->`     | `:operator` | `(`      | `:open`      |
| `!`      | `:operator` | `/*…*/`  | `:comment`  | `)`      | `:close`     |
| `!=`     | `:operator` | `//…`    | `:comment`  | `[`      | `:open`      |
| `%`      | `:operator` | `/=`     | `:operator` | `]`      | `:close`     |
| `%=`     | `:operator` | `/`      | `:operator` | `{`      | `:open`      |
| `^`      | `:operator` | `<<=`    | `:operator` | `}`      | `:close`     |
| `^=`     | `:operator` | `<<`     | `:operator` | `-1.2e+4`| `:float`     |
| `&`      | `:operator` | `<=`     | `:operator` | `0x7f`   | `:integer`   |
| `&=`     | `:operator` | `<`      | `:operator` | `idx2`   | `:name`      |
| `&&`     | `:operator` | `>=`     | `:operator` | `"…"`    | `:string`    |
| `$PIPE`      | `:operator` | `>>=`    | `:operator` | `'…'`    | `:character` |
| `$PIPE=`     | `:operator` | `>>`     | `:operator` | `#`      | `:operator`  |
| `$PIPE$PIPE`     | `:operator` | `>`      | `:operator` | `##`     | `:operator`  |
| `+`      | `:operator` | `.`      | `:operator` | `\\…`     | `:escape`    |
| `+=`     | `:operator` | `?`      | `:operator` |          |              |
| `++`     | `:operator` | `~`      | `:operator` |          |              |

Example:

```julia
julia> tokenize(:C, "val = -.78e-15 # x /* oops! */;")
7-element Vector{Token}:
 Token("val"         => (:name,      1))
 Token("="           => (:operator,  1))
 Token("-.78e-15"    => (:float,     1))
 Token("#"           => (:operator,  1))
 Token("x"           => (:name,      1))
 Token("/* oops! */" => (:comment,   1))
 Token(";"           => (:separator, 1))

julia> tokenize(:C, "#include <sys/types.h>")
9-element Vector{Token}:
 Token("#"       => (:operator, 1))
 Token("include" => (:name,     1))
 Token("<"       => (:operator, 1))
 Token("sys"     => (:name,     1))
 Token("/"       => (:operator, 1))
 Token("types"   => (:name,     1))
 Token("."       => (:operator, 1))
 Token("h"       => (:name,     1))
 Token(">"       => (:operator, 1))

```

!!! warning
    This tokenizer assumes that `str` is valid C code, it does not distinguish C keywords
    from identifiers (`:name` stands for both), and it does not attempt to do something
    specific about the pre-processor directives (see above example).

"""
function tokenize(lang::Val{:C}, code::String)
    # Replace CR and CR-LF by LF.
    code = normalize_code(code)::String

    # Regular expressions matching literal numbers, left anchored and with at least two
    # groups, the first one to capture the token, and a last () to capture the next index.
    int_re = anchored!(r"([-+]?\d+[UL]*|0x[0-9A-Fa-f]+)()")
    flt_re = anchored!(r"([-+]?((\.\d+|\d+\.\d*)([eE][-+]?\d+)?|\d+[eE][-+]?\d+))()")

    line = 1
    tokens = Token[]
    start, stop = firstindex(code), lastindex(code)
    null = eltype(code)(0x00)::eltype(code)
    index = start
    while index <= stop
        c = code[index]
        if isspace(c) || iscntrl(c)
            # Skip spaces.
            if c == '\n'
                line += 1
            end
            index = nextind(code, index)
            continue
        end
        if 'a' <= c <= 'z' || 'A' <= c <= 'Z' || c == '_'
            # Symbol name.
            m = match(anchored!(r"([A-Z_a-z][0-9A-Z_a-z]*)()"), code, index)
            push!(tokens, first(m.captures) => (:name, line))
            index = last(m.offsets)
            continue
        end
        if c == '/'
            # May be a comment starting with "//" or "/*", or an operator "/" or "=".
            anchor = index
            next = nextind(code, index)
            t = next <= stop ? code[next] : null
            if t == '/'
                # Fetch "//…" comment line.
                while true
                    index = next
                    next = nextind(code, next)
                    next <= stop || break
                    if code[next] == '\n'
                        # Skip terminating newline.
                        line += 1
                        next = nextind(code, next)
                        break
                    end
                end
                push!(tokens, SubString(code, anchor, index) => (:comment, line))
                index = next
            elseif t == '*'
                # Fetch "/*…*/" comment block.
                linestart = line
                flag = false # closing "*/" found?
                index = next
                while true
                    index = nextind(code, index)
                    index <= stop || break # error: unfinished comment
                    t = code[index]
                    if t == '*'
                        index = nextind(code, index)
                        next <= stop || break # error: unfinished comment
                        t = code[index]
                        if t == '/'
                            flag = true
                            break
                        end
                    end
                    if t == '\n'
                        line += 1
                    end
                end
                flag || error("unfinished /*…*/ comment, line $line")
                push!(tokens, SubString(code, anchor, index) => (:comment, linestart))
                index = nextind(code, index)
            elseif t == '='
                # Fetch "/=" operator.
                push!(tokens, SubString(code, anchor, next) => (:operator, line))
                index = nextind(code, next)
            else
                # Fetch "/" operator.
                push!(tokens, SubString(code, anchor, anchor) => (:operator, line))
                index = next
            end
            continue
        end
        if c == '"' || c == '\''
            # String or character literal.
            type = (c == '"' ? :string : :character)
            linestart = line
            escape = false
            anchor = index
            while true
                index = nextind(code, index)
                index <= stop || error(
                    "unfinished literal $type, from line $linestart to $line")
                t = code[index]
                if t == c && !escape
                    push!(tokens, SubString(code, anchor, index) => (type, line))
                    index = nextind(code, index)
                    break
                elseif t == '\\'
                    escape = !escape
                else
                    escape = false
                    if t == '\n'
                        line += 1
                    end
                end
            end
            continue
        end
        if c == '\\'
            # A backslash only makes sense to escape a newline.
            next = nextind(code, index)
            next <= stop || error("orphan backslash, line $line")
            t = code[next]
            if t == '\n'
                line += 1
            end
            push!(tokens, SubString(code, index, next) => (:escape, line))
            index = nextind(code, next)
            continue
        end
        if c == '#'
            # Pre-processor directive or operator "#" or "##".
            anchor = index
            next = nextind(code, index)
            if next <= stop && code[next] == '#'
                index = next
                next = nextind(code, index)
            end
            push!(tokens, SubString(code, anchor, index) => (:operator, line))
            index = next
            continue
        end
        if c == '(' || c == '{' || c == '['
            push!(tokens, SubString(code, index, index) => (:open, line))
            index = nextind(code, index)
            continue
        end
        if c == ')' || c == '}' || c == ']'
            push!(tokens, SubString(code, index, index) => (:close, line))
            index = nextind(code, index)
            continue
        end
        if c == ',' || c == ';' || c == ':'
            push!(tokens, SubString(code, index, index) => (:separator, line))
            index = nextind(code, index)
            continue
        end
        if c == '~' || c == '?'
            push!(tokens, SubString(code, index, index) => (:operator, line))
            index = nextind(code, index)
            continue
        end
        if c == '=' || c == '*' || c == '!' || c == '%' || c == '^'
            # These may be followed by a "=".
            m = match(anchored!(r"(.=?)()"), code, index)
            push!(tokens, first(m.captures) => (:operator, line))
            index = last(m.offsets)
            continue
        end
        if c == '&' || c == '|'
            # Match "&", "&&", "&=", "|", "||", or "|=".
            m = match(anchored!(r"((.)(\2|=)?)()"), code, index)
            push!(tokens, first(m.captures) => (:operator, line))
            index = last(m.offsets)
            continue
        end
        if c == '+' || c == '-' || '0' <= c <= '9'
            # May be a floating-point literal.
            m = match(flt_re, code, index)
            if m != nothing
                push!(tokens, first(m.captures) => (:float, line))
                index = last(m.offsets)
                continue
            end
            # May be an integer literal.
            m = match(int_re, code, index)
            if m != nothing
                push!(tokens, first(m.captures) => (:integer, line))
                index = last(m.offsets)
                continue
            end
            # Must be an operator.
            if c == '+'
                # Match "+", "++", or "+=".
                m = match(anchored!(r"(\+[+=]?)()"), code, index)
                push!(tokens, first(m.captures) => (:operator, line))
                index = last(m.offsets)
                continue
            end
            if c == '-'
                # Match "-", "--", "-=", or "->".
                m = match(anchored!(r"(-[->=]?)()"), code, index)
                push!(tokens, first(m.captures) => (:operator, line))
                index = last(m.offsets)
                continue
            end
            error("this is unexpected")
            continue
        end
        if c == '.'
            # May be a floating-point literal or an "." operator.
            m = match(flt_re, code, index)
            if m != nothing
                push!(tokens, first(m.captures) => (:float, line))
                index = last(m.offsets)
            else
                push!(tokens, SubString(code, index, index) => (:operator, line))
                index = nextind(code, index)
            end
            continue
        end
        if c == '<' || c == '>'
            # May be "<", "<<", "<=", "<<=", ">", ">>", ">=" or ">>="
            m = match(anchored!(r"((.)\2?=?)()"), code, index)
            push!(tokens, first(m.captures) => (:operator, line))
            index = last(m.offsets)
            continue
        end
        @warn "unexpected character '$c' (0x$(string(Integer(c);base=16))), line $line"
        index = nextind(code, index)
    end
    return tokens
end

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
    is_identifier(t::Token)

Yield whether `t` is an identifier or a keyword.

"""
is_identifier(t::Token) = t.type === :name

"""
    is_operator(t::Token)

Yield whether `t` is an operator.

"""
is_operator(t::Token) = t.type === :operator

"""
    is_separator(t::Token)

Yield whether `t` is a separator.

"""
is_separator(t::Token) = t.type === :separator

"""
    is_opening(t::Token)

Yield whether `t` is an opening token like `(`, `[`, or `{`.

"""
is_opening(t::Token) = t.type === :open

"""
    is_closing(t::Token)

Yield whether `t` is a closing token like `)`, `]`, or `}`.

"""
is_closing(t::Token) = t.type === :close

for (s, (a, b)) in ("(" => (:opening, :parenthesis),
                    ")" => (:closing, :parenthesis),
                    "[" => (:opening, :bracket),
                    "]" => (:closing, :bracket),
                    "{" => (:opening, :brace),
                    "}" => (:closing, :brace))
    f = Symbol("is_$(a)_$(b)")
    g = Symbol("is_$(a)")
    @eval begin
        """
            $($f)(t::Token)

        Yield whether `t` is a `$($s)`.

        """
        $f(t::Token) = $g(t) && t.text == $s
    end
end

"""
    is_asterisk(t::Token)

Yield whether `t` is the `*` operator.

"""
is_asterisk(t::Token) = is_operator(t) && t.text == "*"

"""
    is_comma(t::Token)

Yield whether `t` is the `,` separator.

"""
is_comma(t::Token) = is_separator(t) && t.text == ","

"""
    is_semicolon(t::Token)

Yield whether `t` is the `;` separator.

"""
is_semicolon(t::Token) = is_separator(t) && t.text == ";"

"""
    is_comment(t::Token)

Yield whether `t` is a comment.

"""
is_comment(t::Token) = t.type === :comment

"""
    is_escape_newline(t::Token)

Yield whether `t` is the "\\\n" token.

"""
is_escape_newline(t::Token) = t.type === :escape && t.text == "\\\n"

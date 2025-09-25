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
    is_comment(t::Token)

Yield whether `t` is a comment.

For example, to strip the comment from a vector of `tokens`:

    filter(!is_comment, tokens)

"""
is_comment(t::Token) = t.type === :comment

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
    is_string(t::Token)

Yield whether `t` is a literal string token like `"hello world!"`.

"""
is_string(t::Token) = t.type === :string

"""
    is_character(t::Token)

Yield whether `t` is a literal character token like `'x'` or `'\\n'`.

"""
is_character(t::Token) = t.type === :character

"""
    is_integer(t::Token)

Yield whether `t` is a literal integer token.

"""
is_integer(t::Token) = t.type === :integer

"""
    is_float(t::Token)

Yield whether `t` is a literal floating-point token.

"""
is_float(t::Token) = t.type === :float

"""
    is_number(t::Token)

Yield whether `t` is a literal number token, i.e. an integer or a floating-point literal.

"""
is_number(t::Token) = is_integer(t) || is_float(t)

"""
    is_literal(t::Token)

Yield whether `t` is a literal token, i.e. an integer, floating-point, character, or string
literal.

"""
is_literal(t::Token) = is_number(t) || is_string(t) || is_character(t)

"""
    is_opening(t::Token)

Yield whether `t` is an opening token like `(`, `[`, or `{`.

"""
is_opening(t::Token) = t.type === :opening

"""
    is_closing(t::Token)

Yield whether `t` is a closing token like `)`, `]`, or `}`.

"""
is_closing(t::Token) = t.type === :closing

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
    is_escape_newline(t::Token)

Yield whether `t` is the "\\\n" token.

"""
is_escape_newline(t::Token) = t.type === :escape && t.text == "\\\n"

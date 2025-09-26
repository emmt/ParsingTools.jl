module ParsingToolsTests

using ParsingTools
using Test
using Aqua

@testset "ParsingTools.jl" begin
    @testset "tokenize" begin

        code = @inferred tokenize(:C, "([{}])*,;\\\nblue=123+0.4;red=\"red\";green+='G';")
        @test is_opening(code[1])
        @test is_opening(code[2])
        @test is_opening(code[3])
        @test is_closing(code[4])
        @test is_closing(code[5])
        @test is_closing(code[6])
        @test is_opening_parenthesis(code[1])
        @test is_opening_bracket(code[2])
        @test is_opening_brace(code[3])
        @test is_closing_brace(code[4])
        @test is_closing_bracket(code[5])
        @test is_closing_parenthesis(code[6])
        @test is_operator(code[7])
        @test is_asterisk(code[7])
        @test is_separator(code[8])
        @test is_comma(code[8])
        @test is_separator(code[9])
        @test is_semicolon(code[9])
        @test is_escape_newline(code[10])
        @test code[10].line == 1
        @test is_identifier(code[11])
        @test code[11].text == "blue"
        @test code[11].line == 2
        @test is_operator(code[12])
        @test is_literal(code[13])
        @test is_integer(code[13])
        @test is_operator(code[14])
        @test is_literal(code[15])
        @test is_float(code[15])
        @test is_separator(code[16])
        @test is_semicolon(code[16])
        @test is_identifier(code[17])
        @test code[17].text == "red"
        @test is_operator(code[18])
        @test is_literal(code[19])
        @test is_string(code[19])
        @test is_separator(code[20])
        @test is_semicolon(code[20])
        @test is_identifier(code[21])
        @test code[21].text == "green"
        @test is_operator(code[22])
        @test code[22].text == "+="
        @test is_literal(code[23])
        @test is_character(code[23])
        @test is_separator(code[24])
        @test is_semicolon(code[24])

        # Check parsing of integer suffixes.
        @test tokenize(:C, "0x12f4ul") == Token["0x12f4ul" => (:integer, 1)]
        @test tokenize(:C, "0x12f4alLu") == Token["0x12f4alLu" => (:integer, 1)]
        @test tokenize(:C, "0x12f4LU") == Token["0x12f4LU" => (:integer, 1)]
        @test tokenize(:C, "0x006eELLU") == Token["0x006eELLU" => (:integer, 1)]
        @test tokenize(:C, "1234ullu") == Token["1234ull" => (:integer, 1), "u" => (:name, 1)]
        @test tokenize(:C, "1234uul") == Token["1234u" => (:integer, 1), "ul" => (:name, 1)]

        # Tokenize chunks of code.
        A = @inferred tokenize(:C, "#include <sys/types.h>")
        @test A == Token["#"       => (:operator, 1),
                         "include" => (:name,     1),
                         "<"       => (:operator, 1),
                         "sys"     => (:name,     1),
                         "/"       => (:operator, 1),
                         "types"   => (:name,     1),
                         "."       => (:operator, 1),
                         "h"       => (:name,     1),
                         ">"       => (:operator, 1)]
        B = @inferred tokenize(:C, "val = -.78e-15 # x /* oops! */;")
        @test B == Token["val"         => (:name,      1),
                         "="           => (:operator,  1),
                         "-"           => (:operator,  1),
                         ".78e-15"     => (:float,     1),
                         "#"           => (:operator,  1),
                         "x"           => (:name,      1),
                         "/* oops! */" => (:comment,   1),
                         ";"           => (:separator, 1)]
        code =  """
                int a = 56; // decimal
                long b = 123456L; // decimal
                long long c = 12304596LL; // decimal
                unsigned d = 045; // octal
                unsigned int e = 0458; // octal and 8 (parse error)
                unsigned f[] = {0x23A, 0Xb4C, 0xFEA,}; /* hexadecimal */
                unsigned g[] = {0b101, 0B11101}; /* binary */
                unsigned long h = 5287727UL;
                unsigned long long i = 621917ull;
                """
        C = @inferred tokenize(:C, code)
        @test C == Token["int"        => (:name, 1),
                         "a"          => (:name, 1),
                         "="          => (:operator, 1),
                         "56"         => (:integer, 1),
                         ";"          => (:separator, 1),
                         "// decimal" => (:comment, 1),
                         "long"       => (:name, 2),
                         "b"          => (:name, 2),
                         "="          => (:operator, 2),
                         "123456L"    => (:integer, 2),
                         ";"          => (:separator, 2),
                         "// decimal" => (:comment, 2),
                         "long"       => (:name, 3),
                         "long"       => (:name, 3),
                         "c"          => (:name, 3),
                         "="          => (:operator, 3),
                         "12304596LL" => (:integer, 3),
                         ";"          => (:separator, 3),
                         "// decimal" => (:comment, 3),
                         "unsigned"   => (:name, 4),
                         "d"          => (:name, 4),
                         "="          => (:operator, 4),
                         "045"        => (:integer, 4),
                         ";"          => (:separator, 4),
                         "// octal"   => (:comment, 4),
                         "unsigned"   => (:name, 5),
                         "int"        => (:name, 5),
                         "e"          => (:name, 5),
                         "="          => (:operator, 5),
                         "045"        => (:integer, 5),
                         "8"          => (:integer, 5),
                         ";"          => (:separator, 5),
                         "// octal and 8 (parse error)" => (:comment, 5),
                         "unsigned"   => (:name, 6),
                         "f"          => (:name, 6),
                         "["          => (:opening, 6),
                         "]"          => (:closing, 6),
                         "="          => (:operator, 6),
                         "{"          => (:opening, 6),
                         "0x23A"      => (:integer, 6),
                         ","          => (:separator, 6),
                         "0Xb4C"      => (:integer, 6),
                         ","          => (:separator, 6),
                         "0xFEA"      => (:integer, 6),
                         ","          => (:separator, 6),
                         "}"          => (:closing, 6),
                         ";"          => (:separator, 6),
                         "/* hexadecimal */" => (:comment, 6),
                         "unsigned"   => (:name, 7),
                         "g"          => (:name, 7),
                         "["          => (:opening, 7),
                         "]"          => (:closing, 7),
                         "="          => (:operator, 7),
                         "{"          => (:opening, 7),
                         "0b101"      => (:integer, 7),
                         ","          => (:separator, 7),
                         "0B11101"    => (:integer, 7),
                         "}"          => (:closing, 7),
                         ";"          => (:separator, 7),
                         "/* binary */" => (:comment, 7),
                         "unsigned"   => (:name, 8),
                         "long"       => (:name, 8),
                         "h"          => (:name, 8),
                         "="          => (:operator, 8),
                         "5287727UL"  => (:integer, 8),
                         ";"          => (:separator, 8),
                         "unsigned"   => (:name, 9),
                         "long"       => (:name, 9),
                         "long"       => (:name, 9),
                         "i"          => (:name, 9),
                         "="          => (:operator, 9),
                         "621917ull"  => (:integer, 9),
                         ";"          => (:separator, 9)]

        # Check `Parsingtools.cleanup`.
        code = @inferred tokenize(:C,
            """
            int x = 3; // Some comment.
            #define NV (85\\
                        + 7)
            short b = 5 /* another comment */;
            """)
        @test @inferred(ParsingTools.cleanup(code)) == code
        @test @inferred(ParsingTools.cleanup(code; strip_comments=true)) == Token[
            "int" => (:name, 1),
            "x" => (:name, 1),
            "=" => (:operator, 1),
            "3" => (:integer, 1),
            ";" => (:separator, 1),
            "#" => (:operator, 2),
            "define" => (:name, 2),
            "NV" => (:name, 2),
            "(" => (:opening, 2),
            "85" => (:integer, 2),
            "\\\n" => (:escape, 2),
            "+" => (:operator, 3),
            "7" => (:integer, 3),
            ")" => (:closing, 3),
            "short" => (:name, 4),
            "b" => (:name, 4),
            "=" => (:operator, 4),
            "5" => (:integer, 4),
            ";" => (:separator, 4)]
        @test @inferred(ParsingTools.cleanup(code; merge_lines=true, strip_comments=true)) == Token[
            "int" => (:name, 1),
            "x" => (:name, 1),
            "=" => (:operator, 1),
            "3" => (:integer, 1),
            ";" => (:separator, 1),
            "#" => (:operator, 2),
            "define" => (:name, 2),
            "NV" => (:name, 2),
            "(" => (:opening, 2),
            "85" => (:integer, 2),
            "+" => (:operator, 2),
            "7" => (:integer, 2),
            ")" => (:closing, 2),
            "short" => (:name, 4),
            "b" => (:name, 4),
            "=" => (:operator, 4),
            "5" => (:integer, 4),
            ";" => (:separator, 4)]
        @test @inferred(ParsingTools.cleanup(code; merge_lines=true)) == Token[
            "int" => (:name, 1),
            "x" => (:name, 1),
            "=" => (:operator, 1),
            "3" => (:integer, 1),
            ";" => (:separator, 1),
            "// Some comment." => (:comment, 1),
            "#" => (:operator, 2),
            "define" => (:name, 2),
            "NV" => (:name, 2),
            "(" => (:opening, 2),
            "85" => (:integer, 2),
            "+" => (:operator, 2),
            "7" => (:integer, 2),
            ")" => (:closing, 2),
            "short" => (:name, 4),
            "b" => (:name, 4),
            "=" => (:operator, 4),
            "5" => (:integer, 4),
            "/* another comment */" => (:comment, 4),
            ";" => (:separator, 4)]

    end
end


@testset "Quality tests" begin
    Aqua.test_all(ParsingTools)
end

end # module

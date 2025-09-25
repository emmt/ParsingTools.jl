module ParsingToolsTests

using ParsingTools
using Test
using Aqua

@testset "ParsingTools.jl" begin
    @testset "tokenize" begin

        code = @inferred tokenize(:C, "([{}])*,;\\\nblue")
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
    end
end


@testset "Quality tests" begin
    Aqua.test_all(ParsingTools)
end

end # module

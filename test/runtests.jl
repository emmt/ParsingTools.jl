module ParsingToolsTests

using ParsingTools
using Test

@testset "ParsingTools.jl" begin
    @testset "tokenize" begin
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
                         "-.78e-15"    => (:float,     1),
                         "#"           => (:operator,  1),
                         "x"           => (:name,      1),
                         "/* oops! */" => (:comment,   1),
                         ";"           => (:separator, 1)]
    end
end

end # module

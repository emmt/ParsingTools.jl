# ParsingTools

[![Build Status](https://github.com/emmt/ParsingTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/emmt/ParsingTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/emmt/ParsingTools.jl?svg=true)](https://ci.appveyor.com/project/emmt/ParsingTools-jl)
[![Coverage](https://codecov.io/gh/emmt/ParsingTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/emmt/ParsingTools.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

The [`ParsingTools.jl`](https://github.com/emmt/ParsingTools.jl) package provides simple
tools to parse programming languages. This is a work in progress; for now, a tokenizer for
the C language is implemented.

Example:

```julia
julia> tokenize(:C, "val = -.78e-15 # x /* oops! */;")
7-element Vector{Token}:
 Token("val"         => (:name,      1))
 Token("="           => (:operator,  1))
 Token("-"           => (:operator,  1))
 Token(".78e-15"     => (:float,     1))
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

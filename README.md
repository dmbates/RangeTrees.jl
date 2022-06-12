# RangeTrees.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://dmbates.github.io/RangeTrees.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://dmbates.github.io/RangeTrees.jl/dev/)
[![Build Status](https://github.com/dmbates/RangeTrees.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/dmbates/RangeTrees.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/dmbates/RangeTrees.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/dmbates/RangeTrees.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/R/RangeTrees.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/report.html)

This [Julia](https://julialang.org) package defines the `RangeTree` and `RangeNode` types to represent an [augmented interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree) created from a `Vector{UnitRange{<:Interval}}`.
An `intersect` method allows for evaluation of coverage of segments, as in the [coverage](https://bedtools.readthedocs.io/en/latest/content/tools/coverage.html) program from
[bedtools](https://bedtools.readthedocs.io/en/latest/index.html).

The facilities of this package are a subset of those offered by [IntervalTrees.jl](http://github.com/BioJulia/IntervalTrees.jl) but tuned to the particular task of intersecting intervals represented as `UnitRange{<:Integer}`.

The example in the figure on the [Wikipedia page](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree) would be reproduced as
```julia
julia> using RangeTrees

julia> rt = RangeTree([0:0, 3:40, 10:14, 20:35, 29:98]); 

julia> rt.nodes
5-element Vector{RangeNode{Int64}}:
 RangeNode{Int64}(0:0, 0, 0, 0)
 RangeNode{Int64}(3:40, 1, 0, 40)
 RangeNode{Int64}(10:14, 2, 5, 98)
 RangeNode{Int64}(20:35, 0, 0, 35)
 RangeNode{Int64}(29:98, 4, 0, 98)

julia> show(intersect(40:59, rt))
UnitRange{Int64}[40:40, 40:59]
```

The tree is different from that shown in the figure because a `RangeTree` is constructed to be balanced and the one in the figure is not balanced.
Note that in the figure the intervals exclude the right hand endpoint whereas Julia's `UnitRange{<:Integer}` is inclusive of both end points.
Thus `[20, 36)` in the figure corresponds to the range `20:35`.
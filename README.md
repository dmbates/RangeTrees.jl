# RangeTrees.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://dmbates.github.io/RangeTrees.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://dmbates.github.io/RangeTrees.jl/dev/)
[![Build Status](https://github.com/dmbates/RangeTrees.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/dmbates/RangeTrees.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/dmbates/RangeTrees.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/dmbates/RangeTrees.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/R/RangeTrees.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/report.html)

This [Julia](https://julialang.org) package defines the `RangeTree` and `RangeNode` types to represent an [augmented interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree) created from a `Vector{UnitRange{T}} where {T<:Integer}`.
A fast `intersect` method for target range and a `RangeTree` can be used to evaluate coverage by the ranges in the `RangeTree`, as in the [coverage](https://bedtools.readthedocs.io/en/latest/content/tools/coverage.html) program from
[bedtools](https://bedtools.readthedocs.io/en/latest/index.html).

The facilities of this package are a subset of those offered by [IntervalTrees.jl](http://github.com/BioJulia/IntervalTrees.jl) but tuned to the particular task of intersecting intervals represented as `UnitRange{<:Integer}`.

The example in the figure on the [Wikipedia page](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree) would be reproduced as
```julia
julia> using RangeTrees

julia> rt = RangeTree([0:0, 3:40, 10:14, 20:35, 29:98]); 

julia> show(intersect(40:59, rt))
UnitRange{Int64}[40:40, 40:59]
```

The tree is different from that shown in the figure because a `RangeTree` is constructed to be balanced and the one in the figure is not balanced.
Note that in the figure the intervals exclude the right hand endpoint whereas Julia's `UnitRange{<:Integer}` is inclusive of both end points.
Thus `[20, 36)` in the figure corresponds to the range `20:35`.

Methods for some [AbstractTrees.jl](https://github.com/JuliaCollections/AbstractTrees.jl) generics are available, most importantly `print_tree`.
These methods are called on an `IndexNode` generated from the `RangeTree`.
```julia
julia> idxnd = IndexNode(rt);

julia> print_tree(idxnd)
(10:14, 98)
├─ (3:40, 40)
│  └─ (0:0, 0)
└─ (29:98, 98)
   └─ (20:35, 35)

julia> treesize(idxnd)
5

julia> treebreadth(idxnd)
2

julia> treeheight(idxnd)
2

julia> collect(nodevalue.(Leaves(idxnd)))
2-element Vector{Tuple{UnitRange{Int64}, Int64}}:
 (0:0, 0)
 (20:35, 35)

julia> collect(nodevalue.(PostOrderDFS(idxnd)))  # post-order, depth-first traversal 
5-element Vector{Tuple{UnitRange{Int64}, Int64}}:
 (0:0, 0)
 (3:40, 40)
 (20:35, 35)
 (29:98, 98)
 (10:14, 98)

julia> collect(nodevalue.(PreOrderDFS(idxnd)))  # pre-order, depth-first traversal
5-element Vector{Tuple{UnitRange{Int64}, Int64}}:
 (10:14, 98)
 (3:40, 40)
 (0:0, 0)
 (29:98, 98)
 (20:35, 35)
``` 
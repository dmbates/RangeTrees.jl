# RangeTrees.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://dmbates.github.io/RangeTrees.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://dmbates.github.io/RangeTrees.jl/dev/)
[![Build Status](https://github.com/dmbates/RangeTrees.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/dmbates/RangeTrees.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/dmbates/RangeTrees.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/dmbates/RangeTrees.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/R/RangeTrees.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/report.html)

This [Julia](https://julialang.org) package defines the `RangeNode` type to represent an [augmented interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree) created from a `Vector{UnitRange{T}} where {T<:Integer}`.
(The tree is represented by its root node.)

A fast `intersect` method for a target range and a `RangeNode` can be used to evaluate coverage by the ranges in the tree routed at the node, as in the [coverage](https://bedtools.readthedocs.io/en/latest/content/tools/coverage.html) program from
[bedtools](https://bedtools.readthedocs.io/en/latest/index.html).

Tree traversal, printing, etc. use the [AbstractTrees.jl](https://github.com/JuliaCollections/AbstractTrees.jl) framework.

The facilities of this package are a subset of those offered by [IntervalTrees.jl](http://github.com/BioJulia/IntervalTrees.jl) but tuned to the particular task of intersecting a `UnitRange` target with the intervals (also represented as `UnitRange`) in the tree.

The example in the figure on the [Wikipedia page](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree) can be reproduced as
```julia
julia> using RangeTrees

julia> rt = RangeNode([0:0, 3:40, 10:14, 20:35, 29:98]);

julia> print_tree(rt)
(10:14, 98)
├─ (3:40, 40)
│  └─ (0:0, 0)
└─ (29:98, 98)
   └─ (20:35, 35)

julia> results = intersect(40:59, rt)
2-element Vector{UnitRange{Int64}}:
 40:40
 40:59

julia> intersect!(empty!(results), 40:59, rt)
2-element Vector{UnitRange{Int64}}:
 40:40
 40:59

julia> intersect!(empty!(results), 40:59, rt)
2-element Vector{UnitRange{Int64}}:
 40:40
 40:59
```

Each node in the `print_tree` output is shown as the range at that node and the maximum value of `last(range)` in the subtree rooted at that node.  This is the augmentation in the tree that allows for fast intersection of the nodes in the tree with a target tree.

The tree `rt` is not the same as the one shown in the figure because a `RangeNode` is constructed to be balanced and the one in the figure is not balanced.
Note that in the figure the intervals exclude the right hand endpoint whereas Julia's `UnitRange{<:Integer}` is inclusive of both end points.
Thus `[20, 36)` in the figure corresponds to the range `20:35`.

The `intersect!` method allows for passing the vector that will be the result, reducing the memory allocations.  Note that the first argument to `intersect!` should be wrapped in `empty!` because `intersect!` is recursive and `push!`s each intersection onto the end of `result`.

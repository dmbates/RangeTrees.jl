module RangeTrees

using AbstractTrees

import Base.intersect!

"""
    RangeNode

An augmented, balanced, binary [interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree)
of intervals of integers represented as a [UnitRange](@ref).

```jldoctest
julia> rt = RangeNode([0:0, 3:40, 10:14, 20:35, 29:98]); # example from Wikipedia page

julia> intersect(40:59, rt)
2-element Vector{UnitRange{Int64}}:
 40:40
 40:59
````
"""
struct RangeNode{T}
    irange::UnitRange
    v::Vector{UnitRange{T}}
    maxl::Vector{T}
end

"""
    midrange(rng::AbstractUnitRange{T}) where {T<:Integer}

Return the median of `rng`, rounding up when `length(rng)` is even.
"""
function midrange(rng::AbstractUnitRange{T}) where {T<:Integer}
    return (first(rng) + last(rng) + one(T)) >> 1
end

midrange(rt::RangeNode) = midrange(rt.irange)

decrement(idx) = idx - one(idx)

increment(idx) = idx + one(idx)

# AbstractTrees.NodeType(::Type{RangeNode{T}}) where T = HasNodeType()

function AbstractTrees.children(rt::RangeNode)
    (; irange, v, maxl) = rt
    mid = midrange(irange)
    childranges = (first(irange):decrement(mid), increment(mid):last(irange))

    return map(r -> RangeNode(r, v, maxl), filter(!isempty, childranges))
end

AbstractTrees.nodetype(::Type{RangeNode{T}}) where T = RangeNode{T}

function AbstractTrees.nodevalue(rt::RangeNode)
    (; irange, v, maxl) = rt
    mid = midrange(irange)
    return v[mid], maxl[mid]
end

Base.show(io::IO, ::MIME"text/plain", rt::RangeNode) = show(io, nodevalue(rt))

function AbstractTrees.printnode(io::IO, rt::RangeNode)
    print(io, nodevalue(rt))
end

maxlast(rt::RangeNode) = rt.maxl[midrange(rt)]

function updatemaxl!(rt::RangeNode)
    rt.maxl[midrange(rt)] = max(maxlast(rt), maximum(maxlast, children(rt); init=0))
    return rt
end

function RangeNode(v::Vector{UnitRange{T}}) where T
    rt = RangeNode(UnitRange(eachindex(v)), sort!(copy(v); by=first), last.(v))
    for node in PostOrderDFS(rt)
        updatemaxl!(node)
    end
    return rt
end

AbstractTrees.getroot(rt::RangeNode) = rt

"""
    intersect!(result::AbstractVector{UnitRange}, target::UnitRange, rt::RangeNode)

Recursively intersect `target` with the intervals in `rt`.

Non-empty intersections are pushed onto `result` in the same order as the intersecting nodes
appear in the tree. Storing `maxlast` allows for the pre-order depth-first search to be truncated
when a node's `maxlast` is less than `first(target)`.  Because the nodes are in non-decreasing
order of `first(intvl)` the right subtree can be skipped when `last(target) < first(intvl)`.
"""
function Base.intersect!(
    result::Vector{UnitRange{T}},
    target::AbstractUnitRange{T},
    rt::RangeNode{T}
) where T
    (; irange, v, maxl) = rt
    
    maxlast(rt) < first(target) && return result

    mid = midrange(irange)
    lrng = first(irange):decrement(mid)
    isempty(lrng) || intersect!(result, target, RangeNode(lrng, v, maxl))
    isect = intersect(v[mid], target)
    isempty(isect) || push!(result, isect)
    rrng = increment(mid):last(irange)
    isempty(rrng) || last(target) < first(irange) ||
      intersect!(result, target, RangeNode(rrng, v, maxl))
    return result
end

function Base.intersect(target::AbstractUnitRange{T}, rt::RangeNode{T}) where T
    return intersect!(typeof(target)[], target, rt)
end

function Base.intersect(rt::RangeNode{T}, target::AbstractUnitRange{T}) where T
    return intersect(target, rt)
end

export
    Leaves,
    PostOrderDFS,
    PreOrderDFS,
    RangeNode,

    children,
    intersect!,
    midrange,
    nodetype,
    nodevalue,
    print_tree,
    treebreadth,
    treeheight,
    treesize

end

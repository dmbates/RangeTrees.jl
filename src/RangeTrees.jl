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
    ranges::Vector{UnitRange{T}}
    maxlast::Vector{T}
    inds::UnitRange
end

"""
    midrange(rng::AbstractUnitRange{T}) where {T<:Integer}

Return the median of `rng`, rounding up when `length(rng)` is even.
"""
function midrange(rng::AbstractUnitRange{T}) where {T<:Integer}
    return (first(rng) + last(rng) + one(T)) >> 1
end

"""
    splitrange(rng)

Split `rng` into `mid`, the value of [`midrange`](@ref), the `UnitRange` to
the left of `mid` and the `UnitRange` to the right.
"""
function splitrange(rng)
    mid = midrange(rng)
    return first(rng):(mid - one(mid)), mid, (mid + one(mid)):last(rng)
end

# recursively update the elements of maxlast in a depth-first pre-order scan
function _updatemaxlast!(mlast::AbstractVector{T}, inds::AbstractUnitRange) where {T<:Number}
    if !issubset(inds, eachindex(mlast)) 
        throw(ArgumentError("inds = $inds is not a subset of eachindex(mlast)"))
    end
    left, mid, right = splitrange(inds)
    thismax = mlast[mid]
    isempty(left) || (thismax = max(thismax, _updatemaxlast!(mlast, left)))
    isempty(right) || (thismax = max(thismax, _updatemaxlast!(mlast, right)))
    mlast[mid] = thismax
    return thismax
end

function RangeNode(ranges::Vector{UnitRange{T}}) where {T}
    issorted(ranges; by=first) || (ranges = sort(ranges; by=first))
    inds = UnitRange(eachindex(ranges))
    maxlast = last.(ranges)
    _updatemaxlast!(maxlast, inds)
    return RangeNode(ranges, maxlast, inds)
end

AbstractTrees.NodeType(::Type{RangeNode{T}}) where T = HasNodeType()

function AbstractTrees.children(rt::RangeNode)
    (; ranges, maxlast, inds) = rt
    left, mid, right = splitrange(inds)

    return map(r -> RangeNode(ranges, maxlast, r), filter(!isempty, [left, right]))
end

AbstractTrees.nodetype(::Type{RangeNode{T}}) where {T} = RangeNode{T}

function AbstractTrees.nodevalue(rt::RangeNode)
    (; ranges, maxlast, inds) = rt
    mid = midrange(inds)
    return @inbounds ranges[mid], maxlast[mid]
end

# Base.show(io::IO, ::MIME"text/plain", rt::RangeNode) = show(io, nodevalue(rt))

AbstractTrees.isroot(rt::RangeNode) = isequal(rt.inds, eachindex(rt.maxlast))

function AbstractTrees.getroot(rt::RangeNode)
    (; ranges, maxlast) = rt
    return RangeNode(ranges, maxlast, UnitRange(eachindex(maxlast)))
end

"""
    intersect!(result::AbstractVector{UnitRange}, target::UnitRange, rt::RangeNode)

Recursively intersect `target` with the intervals in `rt`.

Non-empty intersections are pushed onto `result` in the same order as the intersecting nodes
appear in the tree. Storing `maxlast` allows for the pre-order depth-first search to be truncated
when a node's `maxlast` is less than `first(target)`.  Because the nodes are in non-decreasing
order of `first(intvl)` the right subtree can be skipped when `last(target) < first(intvl)`.
"""
function Base.intersect!(
    result::Vector{UnitRange{T}}, target::AbstractUnitRange{T}, rt::RangeNode{T}
) where {T}
    (; ranges, maxlast, inds) = rt

    left, mid, right = splitrange(inds)

    @inbounds maxlast[mid] < first(target) && return result
    isempty(left) || intersect!(result, target, RangeNode(ranges, maxlast, left))
    thisrange = @inbounds ranges[mid]
    last(target) < first(thisrange) && return result
    isect = intersect(thisrange, target)
    isempty(isect) || push!(result, isect)
    isempty(right) || intersect!(result, target, RangeNode(ranges, maxlast, right))
    return result
end

function Base.intersect(target::AbstractUnitRange{T}, rt::RangeNode{T}) where {T}
    return intersect!(typeof(target)[], target, rt)
end

function Base.intersect(rt::RangeNode{T}, target::AbstractUnitRange{T}) where {T}
    return intersect(target, rt)
end

export Leaves,
    PostOrderDFS,
    PreOrderDFS,
    RangeNode,
    children,
    intersect!,
    isroot,
    midrange,
    nodetype,
    nodevalue,
    print_tree,
    treebreadth,
    treeheight,
    treesize

end

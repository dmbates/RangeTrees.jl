module RangeTrees

using AbstractTrees

import Base.intersect!

"""
    RangeNode

An augmented, balanced, binary [interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree)
of intervals of integers represented as a [UnitRange](@ref).

```jldoctest
julia> rn = RangeNode([0:0, 3:40, 10:14, 20:35, 29:98]); # example from Wikipedia page

julia> intersect(40:59, rn)
2-element Vector{UnitRange{Int64}}:
 40:40
 40:59
````
"""
struct RangeNode{T,R}
    ranges::Vector{UnitRange{T}}
    maxlast::Vector{T}
    inds::UnitRange{R}
end

"""
    midrange(rng::AbstractUnitRange{T}) where {T<:Integer}

Return the median of `rng`, rounding up when `length(rng)` is even.
"""
function midrange(rng::AbstractUnitRange{T}) where {T<:Integer}
    return (first(rng) + last(rng) + one(T)) >> 1
end
midrange(rn::RangeNode) = midrange(rn.inds)

"""
    splitrange(rng)

Split `rng` into `mid`, the value of [`midrange`](@ref), the `UnitRange` to
the left of `mid` and the `UnitRange` to the right.
"""
function splitrange(rng)
    mid = midrange(rng)
    return first(rng):(mid - one(mid)), mid, (mid + one(mid)):last(rng)
end
splitrange(rn::RangeNode) = splitrange(rn.inds)

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
    inds = UnitRange{length(ranges) ≤ typemax(Int32) ? Int32 : Int}(eachindex(ranges))
    maxlast = last.(ranges)
    _updatemaxlast!(maxlast, inds)
    return RangeNode(ranges, maxlast, inds)
end

AbstractTrees.NodeType(::Type{RangeNode{T}}) where T = HasNodeType()

function AbstractTrees.children(rn::RangeNode)
    (; ranges, maxlast, inds) = rn
    left, mid, right = splitrange(inds)

    return map(r -> RangeNode(ranges, maxlast, r), filter(!isempty, [left, right]))
end

AbstractTrees.nodetype(::Type{RangeNode{T,R}}) where {T,R} = RangeNode{T,R}

function AbstractTrees.nodevalue(rn::RangeNode)
    (; ranges, maxlast, inds) = rn
    mid = midrange(inds)
    return @inbounds ranges[mid], maxlast[mid]
end

Base.show(io::IO, ::MIME"text/plain", rn::RangeNode) = show(io, nodevalue(rn))

AbstractTrees.isroot(rn::RangeNode) = isequal(rn.inds, eachindex(rn.maxlast))

function AbstractTrees.getroot(rn::RangeNode)
    (; ranges, maxlast) = rn
    inds = UnitRange{length(ranges) ≤ typemax(Int32) ? Int32 : Int}(eachindex(ranges))
    return RangeNode(ranges, maxlast, inds)
end

function Base.intersect!(
    result::Vector{UnitRange{T}},
    target::AbstractUnitRange,
    ranges::Vector{UnitRange{T}},
    maxlast::Vector{T},
    inds::UnitRange{<:Integer},
) where {T}
    left, mid, right = splitrange(inds)
         # return if maxlast of this node < first(target)
    @inbounds(maxlast[mid]) < first(target) && return result
         # check the left subtree
    isempty(left) || intersect!(result, target, ranges, maxlast, left)
    thisrange = @inbounds(ranges[mid])
         # return if last(target) < first(thisrange) b/c ranges are sorted by first
    last(target) < first(thisrange) && return result
         # check thisrange
    isect = intersect(thisrange, target)
    isempty(isect) || push!(result, isect)
         # check the right subtree
    isempty(right) || intersect!(result, target, ranges, maxlast, right)
    return result
end

"""
    intersect!(result::Vector{UnitRange{T}}, target::AbstractUnitRange, rn::RangeNode{T}) where {T}

Recursively intersect `target` with the intervals in the tree rooted at `rn`.

Non-empty intersections are pushed onto `result` in the same order as the intersecting nodes
appear in the tree. Storing `maxlast` allows for the pre-order depth-first search to be truncated
when a node's `maxlast` is less than `first(target)`.  Because the nodes are in non-decreasing
order of `first(intvl)` the right subtree can be skipped when `last(target) < first(intvl)`.
"""
function Base.intersect!(
    result::Vector{UnitRange{T}},
    target::AbstractUnitRange,
    rn::RangeNode{T},
) where {T}
    return intersect!(empty!(result), target, rn.ranges, rn.maxlast, rn.inds)
end

function Base.intersect(target::AbstractUnitRange, rn::RangeNode{T}) where {T}
    return intersect!(UnitRange{T}[], target, rn)
end

function Base.intersect(rn::RangeNode{T}, target::AbstractUnitRange) where {T}
    return intersect(target, rn)
end

export Leaves,
    PostOrderDFS,
    PreOrderDFS,
    RangeNode,
    children,
    getroot,
    intersect!,
    isroot,
    midrange,
    nodetype,
    nodevalue,
    print_tree,
    splitrange,
    treebreadth,
    treeheight,
    treesize

end

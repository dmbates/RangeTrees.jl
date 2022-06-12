module RangeTrees

using AbstractTrees

struct RangeNode{T}
    intvl::UnitRange{T}  # value of the node
    left::Int    # index of the left subtree (0 => no left subtree)
    right::Int   # index of the right subtree (0 => no right subtree)
    maxlast::T   # maximum(last(n.intvl) where n is a node in this node's subtree)
end

"""
    midrange(rng::UnitRange{T})::T

Return the mid-value of `rng` rounding up when `length(rng)` is even.
"""
midrange(rng::UnitRange{T}) where T = (first(rng) + last(rng) + one(T)) >> 1

"""
    _addchildren!(v::Vector{RangeNode{T}}, inds::UnitRange) where T

Recursively re-write the `left`, `right`, and `maxlast` fields in `v[inds]`
to form an augmented, balanced, binary
[interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree).

Can be extended to store parents in the nodes.
"""
function _addchildren!(v::Vector{RangeNode{T}}, inds::UnitRange) where T
    mid = midrange(inds)
    (; intvl, left, right, maxlast) = v[mid]
    linds = first(inds):(mid - 1) 
    if !isempty(linds)
        left = _addchildren!(v, linds)
        maxlast = max(maxlast, v[left].maxlast)
    end
    rinds = (mid + 1):last(inds)
    if !isempty(rinds)
        right = _addchildren!(v, rinds)
        maxlast = max(maxlast, v[right].maxlast)
    end
    v[mid] = RangeNode(intvl, left, right, maxlast)
    return mid
end

"""
    RangeTree

An augmented, balanced, binary [interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree)
of ranges (or intervals) represented as `UnitRange`{@ref}.

The `nodes` field, a vector of `RangeNode`{@ref}s, represents the tree.
The root node of a `RangeTree` `rt` is `rt.nodes[rt.rootind]`.
The `rootind` field should always be `midrange(UnitRange(eachindex(nodes)))`.

A `RangeTree` is usually constructed from a `Vector{UnitRange}`.
"""
struct RangeTree{T}
    nodes::Vector{RangeNode{T}}
    rootind::Integer
end

function RangeTree(v::AbstractVector{UnitRange{T}}) where T
    issorted(v; by=first) || sort!(v; by=first)
    v = [RangeNode(ivl, 0, 0, last(ivl)) for ivl in v]
    range = UnitRange(eachindex(v))
    _addchildren!(v, range)
    return RangeTree(v, midrange(range))
end

"""
    intersect!(result::AbstractVector{UnitRange}, target::UnitRange, rt::RangeTree, index)

Recursively intersect `target` with the intervals in the subtree of `rt.nodes[index]`.
Non-empty intersections are `push!`'d onto `result` in sorted order.
"""
function intersect!(
    result::Vector{UnitRange{T}},
    target::UnitRange{T},
    rt::RangeTree{T},
    nodeind::Integer
) where T
    (; intvl, left, right, maxlast) = rt.nodes[nodeind]

    iszero(left) || last(target) < first(intvl) || intersect!(result, target, rt, left)
    intsect = intersect(intvl, target)
    isempty(intsect) || push!(result, intsect)
    iszero(right) || maxlast < first(target) || intersect!(result, target, rt, right)
    return result
end

function intersect!(result::Vector{UnitRange{T}}, target::UnitRange{T}, rt::RangeTree{T}) where T
    return intersect!(result, target, rt, rt.rootind)
end

function Base.intersect(target::UnitRange{T}, rt::RangeTree{T}) where T
    return intersect!(typeof(target)[], target, rt)
end
  
export
    RangeNode,
    RangeTree,

    midrange,
    intersect!

end

module RangeTrees

using AbstractTrees

"""
    RangeNode{T}

The element type of the vector in the `nodes` field of a [RangeTree](@ref).

The value of a `RangeNode{T}` is the `UnitRange{T}` in its `intvl` field.
The `left` and `right` fields are the indices of the children of this node
(values of 0 imply no child on that side).

The `maxlast` field is the maximum value of `last(n.intvl)` for any node `n`
in the right subtree.  This is the "augmentation" in an
[augmented interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree)
that allows for efficient intersection of an interval with all the nodes of a
[RangeTree](@ref).
""" 
struct RangeNode{T}
    intvl::UnitRange{T}  # value of the node
    left::Int    # index of the root of the left subtree (0 => no left subtree)
    right::Int   # index of the root of the right subtree (0 => no right subtree)
    parent::Int  # index of the parent (0 => no parent)
    maxlast::T   # maximum(last(n.intvl) where n is a node in this node's subtree)
end

"""
    midrange(rng::UnitRange{T})::T

Return the largest median of `rng`.
"""
midrange(rng::UnitRange{T}) where T = (first(rng) + last(rng) + one(T)) >> 1
midrange(one2::Base.OneTo{T}) where T = (last(one2) + one(T) + one(T)) >> 1

"""
    _addchildren!(v::Vector{RangeNode{T}}, inds::UnitRange) where T

Internal utility to recursively re-write the `left`, `right`, and `maxlast`
fields in `v[inds]` so as to form an augmented, balanced, binary
[interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree).
"""
function _addchildren!(v::Vector{RangeNode{T}}, inds::UnitRange, parent) where T
    mid = midrange(inds)
    (; intvl, left, right, maxlast) = v[mid]
    linds = first(inds):(mid - 1) 
    if !isempty(linds)
        left = _addchildren!(v, linds, mid)
        maxlast = max(maxlast, v[left].maxlast)
    end
    rinds = (mid + 1):last(inds)
    if !isempty(rinds)
        right = _addchildren!(v, rinds, mid)
        maxlast = max(maxlast, v[right].maxlast)
    end
    v[mid] = RangeNode(intvl, left, right, parent, maxlast)
    return mid
end

"""
    RangeTree

An augmented, balanced, binary [interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree)
of intervals of integers represented as a [UnitRange](@ref).

The `nodes` field, a vector of [RangeNode](@ref)s, is the tree.
The root node of a `RangeTree` `rt` is `rt.nodes[rt.rootind]`.
The `rootind` field should always be `midrange(UnitRange(eachindex(nodes)))`.

A `RangeTree` is usually constructed from a `Vector{UnitRange{<:Integer}}`.  It is designed
to allow for fast intersection of another `UnitRange{<:Integer` with the values of all the
nodes in the tree.

```jldoctest
julia> rt = RangeTree([0:0, 3:40, 10:14, 20:35, 29:98]); # example from Wikipedia page

julia> intersect(40:59, rt)
2-element Vector{UnitRange{Int64}}:
 40:40
 40:59
````
"""
struct RangeTree{T}
    nodes::Vector{RangeNode{T}}
end

function RangeTree(v::AbstractVector{UnitRange{T}}) where T
    issorted(v; by=first) || sort!(v; by=first)
    v = [RangeNode(ivl, 0, 0, 0, last(ivl)) for ivl in v]
    _addchildren!(v, UnitRange(eachindex(v)), 0)
    return RangeTree(v)
end

Base.eachindex(rt::RangeTree) = eachindex(rt.nodes)
Base.getindex(rt::RangeTree, idx::Integer) = rt.nodes[idx]

"""
    intersect!(result::AbstractVector{UnitRange}, target::UnitRange, rt::RangeTree, idx::Integer)

Recursively intersect `target` with the intervals in the subtree of `rt[idx]`.

Non-empty intersections are pushed onto `result` in the same order as the intersecting nodes
appear in the tree. Storing `maxlast` allows for the pre-order depth-first search to be truncated
when a node's `maxlast` is less than `first(target)`.  Because the nodes are in non-decreasing
order of `first(intvl)` the right subtree can be skipped when `last(target) < first(intvl)`.
"""
function intersect!(
    result::Vector{UnitRange{T}},
    target::UnitRange{T},
    rt::RangeTree{T},
    node_index::Integer
) where T
    (; intvl, left, right, maxlast) = rt[node_index]

    maxlast < first(target) && return result

    iszero(left) || intersect!(result, target, rt, left)
    isect = intersect(intvl, target)
    isempty(isect) || push!(result, isect)
    iszero(right) || last(target) < first(intvl) || intersect!(result, target, rt, right)
    return result
end

function intersect!(result::Vector{UnitRange{T}}, target::UnitRange{T}, rt::RangeTree{T}) where T
    return intersect!(empty!(result), target, rt, rootindex(rt))
end

function Base.intersect(target::AbstractUnitRange{T}, rt::RangeTree{T}) where T
    return intersect!(typeof(target)[], target, rt)
end

function Base.intersect(refs::RangeTree{T}, target::AbstractUnitRange{T}) where T
    return intersect(target, refs)
end

# methods for generics from AbstractTrees

function AbstractTrees.childindices(rt::RangeTree, idx::Integer)
    (; left, right) = rt[idx]

    nullrt = iszero(right)
    return iszero(left) ? (nullrt ? () : (right,)) : (nullrt ? (left,) : (left, right))
end

function AbstractTrees.nodevalue(rt::RangeTree, idx::Integer)
    nv = rt[idx]
    return (nv.intvl, nv.maxlast)
end

function AbstractTrees.parentindex(rt::RangeTree, idx::Integer)
    parind = rt[idx].parent
    return iszero(parind) ? nothing : parind
end

function AbstractTrees.rootindex(rt::RangeTree)
    return midrange(eachindex(rt))
end

export
    Leaves,
    PostOrderDFS,
    PreOrderDFS,
    RangeNode,
    RangeTree,

    childindices,
    intersect!,
    midrange,
    parentindex,
    print_tree,
    rootindex,
    treebreadth,
    treeheight,
    treesize

end

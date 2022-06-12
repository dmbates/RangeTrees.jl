module RangeTrees

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
    left::Int    # index of the left subtree (0 => no left subtree)
    right::Int   # index of the right subtree (0 => no right subtree)
    maxlast::T   # maximum(last(n.intvl) where n is a node in this node's subtree)
end

"""
    midrange(rng::UnitRange{T})::T

Return the median of `rng`, rounding up when `length(rng)` is even.
"""
midrange(rng::UnitRange{T}) where T = (first(rng) + last(rng) + one(T)) >> 1

"""
    _addchildren!(v::Vector{RangeNode{T}}, inds::UnitRange) where T

Internal utility to recursively re-write the `left`, `right`, and `maxlast`
fields in `v[inds]` so as to form an augmented, balanced, binary
[interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree).
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
Non-empty intersections are pushed onto `result` in sorted order.
"""
function intersect!(
    result::Vector{UnitRange{T}},
    target::UnitRange{T},
    rt::RangeTree{T},
    node_index::Integer
) where T
    (; intvl, left, right, maxlast) = rt.nodes[node_index]

        # Check the left subtree, if any, unless this interval is to the right of the target
        # (nodes are constructed to be sorted by the first(intvl)).
    iszero(left) || last(target) < first(intvl) || intersect!(result, target, rt, left)

    intsect = intersect(intvl, target)
    isempty(intsect) || push!(result, intsect)

        # Check the right subtree, if any, unless the target is to the right of maxlast.
    iszero(right) || maxlast < first(target) || intersect!(result, target, rt, right)
    return result
end

function intersect!(result::Vector{UnitRange{T}}, target::UnitRange{T}, rt::RangeTree{T}) where T
    return intersect!(result, target, rt, rt.rootind)
end

function Base.intersect(target::UnitRange{T}, rt::RangeTree{T}) where T
    return intersect!(typeof(target)[], target, rt)
end

# hook into the AbstractTrees interface through IndexNode (not working at present).

using AbstractTrees

AbstractTrees.ChildIndexing(::Type{<:RangeTree{T}}) where T = IndexedChildren()

AbstractTrees.IndexNode(rt::RangeTree, node_index) = rt.nodes[node_index]

function AbstractTrees.childindices(rt::RangeTree, node_index)
    (; left, right) = IndexNode(rt, node_index)

    nullrt = iszero(right)
    return iszero(left) ? (nullrt ? () : (right,)) : (nullrt ? (left,) : (left, right))
end

AbstractTrees.nodevalue(rt::RangeTree, idx) = rt.nodes[idx].intvl

AbstractTrees.rootindex(rt::RangeTree) = rt.rootind

export
    Leaves,
    PostOrderDFS,
    PreOrderDFS,
    RangeNode,
    RangeTree,

    childindices,
    intersect!,
    midrange,
    print_tree,
    rootindex,
    treebreadth,
    treeheight,
    treesize

end

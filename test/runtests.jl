using RangeTrees
using AbstractTrees
using Arrow
using Test

increment(x) = x + one(x)

iob = IOBuffer()

@testset "RangeTrees.jl" begin
    rt = RangeTree([0:0, 3:40, 10:14, 20:35, 29:98]) # example from Wikipedia page
    @test length(rt.nodes) == 5
    results = intersect(40:59, rt)
    @test results == [40:40, 40:59]
    @test intersect(rt, 40:59) == results
    @test intersect!(results, 40:59, rt) == [40:40, 40:59]
       # test methods defined for AbstractTrees generics
    @test rootindex(rt) == 3
    @test childindices(rt, 3) == (2, 5)
    @test childindices(rt, 1) == ()
    @test nodevalue(rt, 1) == (0:0, 0)
    @test treesize(IndexNode(rt)) == 5
    @test treeheight(IndexNode(rt)) == 2
    print_tree(iob, IndexNode(rt))
    str = String(take!(iob))
    @test startswith(str, "(10:14, 98)\n")
    @test endswith(str, "(20:35, 35)\n")
end

@testset "largetree" begin
    refrntr = let 
        tbl = Arrow.Table(joinpath(@__DIR__, "data", "refs.arrow"))
        RangeTree(UnitRange.(increment.(tbl.start), tbl.stop))
    end
    idxntr = IndexNode(refrntr)
    @test treesize(idxntr) == length(refrntr.nodes)
    @test treeheight(idxntr) == 12
    @test treebreadth(idxntr) == 2423
end

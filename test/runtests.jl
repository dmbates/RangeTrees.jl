using RangeTrees
using AbstractTrees
using Arrow
using Test

const iob = IOBuffer()

@testset "RangeTrees.jl" begin
    rn = RangeNode([0:0, 3:40, 10:14, 20:35, 29:98]) # example from Wikipedia page
    result = intersect(40:59, rn)
    @test result == [40:40, 40:59]
    @test intersect!(empty!(result), 40:59, rn) == [40:40, 40:59]
    @test result == intersect(rn, 40:59)
       # test methods defined for AbstractTrees generics
    @test treesize(rn) == 5
    @test treeheight(rn) == 2
    @test treebreadth(rn) == 2
    @test nodetype(rn) == typeof(rn)
    @test isnothing(show(iob, MIME"text/plain"(), rn))
    @test String(take!(iob)) == "(10:14, 98)"
    @test isnothing(print_tree(iob, rn))
    str = String(take!(iob))
    @test startswith(str, "(10:14, 98)\n")
    @test endswith(str, "(20:35, 35)\n")
    @test getroot(rn) == rn
    @test isroot(rn)
    @test_throws ArgumentError RangeTrees._updatemaxlast!(rn.maxlast, -2:2) # for code coverage
    @test splitrange(rn) == (1:2, 3, 4:5)
    @test NodeType(typeof(rn)) == HasNodeType()
    @test eltype(PreOrderDFS(rn)) == typeof(rn)
    @test childtype(rn) == typeof(rn)
    @test childtype(typeof(rn)) == typeof(rn)
end

increment(x) = x + one(x)

@testset "largetree" begin
    rn = let 
        tbl = Arrow.Table(joinpath(@__DIR__, "data", "refs.arrow"))
        RangeNode(UnitRange.(increment.(tbl.start), tbl.stop))
    end
    @test treesize(rn) == length(rn.maxlast)
    @test treeheight(rn) == 12
    @test treebreadth(rn) == 2423
    offspring = children(rn)
    @test length(offspring) == 2
    leftinds, mid, rightinds = splitrange(rn.inds)
    @test mid == midrange(rn)
    @test first(offspring).inds == leftinds
    target = 31659713:31668660
    result = similar(rn.ranges, 0)
    @test length(intersect!(result, target, rn)) == 12
end

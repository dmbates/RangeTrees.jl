using RangeTrees
using AbstractTrees
using Arrow
using Test

const iob = IOBuffer()

@testset "RangeTrees.jl" begin
    rt = RangeNode([0:0, 3:40, 10:14, 20:35, 29:98]) # example from Wikipedia page
    result = intersect(40:59, rt)
    @test result == [40:40, 40:59]
    @test intersect!(empty!(result), 40:59, rt) == [40:40, 40:59]
    @test result == intersect(rt, 40:59)
       # test methods defined for AbstractTrees generics
    @test treesize(rt) == 5
    @test treeheight(rt) == 2
    @test treebreadth(rt) == 2
    @test nodetype(rt) == typeof(rt)
    @test isnothing(print_tree(iob, rt))
    str = String(take!(iob))
    @test startswith(str, "(10:14, 98)\n")
    @test endswith(str, "(20:35, 35)\n")
    @test getroot(rt) == rt
    @test isroot(rt)
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

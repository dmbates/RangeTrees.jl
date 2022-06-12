using RangeTrees
using AbstractTrees
using Test

@testset "RangeTrees.jl" begin
    rt = RangeTree([0:0, 3:40, 10:14, 20:35, 29:98]) # example from Wikipedia page
    @test length(rt.nodes) == 5
    @test intersect(40:59, rt) == [40:40, 40:59]
       # test methods defined for AbstractTrees generics
    @test rootindex(rt) == 3
    @test childindices(rt, 3) == (2, 5)
    @test childindices(rt, 1) == ()
    @test nodevalue(rt, 1) == (0:0, 0)
    @test parentindex(rt, 1) == 2
    @test_broken treesize(rt) == 5
    @test_broken treeheight(rt) == 3
    print_tree(rt)
end

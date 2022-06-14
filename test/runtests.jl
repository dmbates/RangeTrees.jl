using RangeTrees
using AbstractTrees
using Test

@testset "RangeTrees.jl" begin
    rt = RangeNode([0:0, 3:40, 10:14, 20:35, 29:98]) # example from Wikipedia page
    result = intersect(40:59, rt)
    @test result == [40:40, 40:59]
    @test intersect!(empty!(result), 40:59, rt) == [40:40, 40:59]
    @test result == intersect(rt, 40:59)
       # test methods defined for AbstractTrees generics
    @test_broken treesize(rt) == 5
    @test_broken treeheight(rt) == 2
    @test_broken treebreadth(rt) == 2
    @test_broken nodetype(rt) == typeof(rt)
    iob = IOBuffer()
    @test isnothing(print_tree(iob, rt))
    str = String(take!(iob))
    @test startswith(str, "(10:14, 98)\n")
    @test endswith(str, "(20:35, 35)\n")
    @test isnothing(show(iob, MIME"text/plain"(), rt))
    @test_broken String(take!(iob)) == "(10:14, 98)"
    @test_broken getroot(rt) == rt
end

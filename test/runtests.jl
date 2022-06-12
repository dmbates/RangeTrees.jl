using RangeTrees
using Test

@testset "RangeTrees.jl" begin
    rt = RangeTree([0:0, 3:40, 10:14, 20:35, 29:98]) # example from Wikipedia page
    @test length(rt.nodes) == 5
    @test rt.rootind == 3
    @test intersect(40:59, rt) == [40:40, 40:59]
end

using JulGame
@testset "Math tests" begin
    include("lerptests.jl")
    include("vectortests.jl")

    @testset "Math tests" begin
        @test Math.normalize(Math.Vector2f(1, 1)) == Math.Vector2f(0.7071067811865475, 0.7071067811865475)
        @test Math.distance(Math.Vector2f(0, 0), Math.Vector2f(3, 4)) == 5.0
    end
end
using Test

ROOTDIR = joinpath(@__DIR__, "..")
EXAMPLEGAMEDIR = joinpath(ROOTDIR, "examples")
SMOKETESTDIR = joinpath(@__DIR__, "projects", "SmokeTest")
PROFILINGTESTDIR = joinpath(@__DIR__, "projects", "ProfilingTest")
include(joinpath(SMOKETESTDIR, "src", "SmokeTest.jl"))
include(joinpath(PROFILINGTESTDIR, "Platformer", "src", "Platformer.jl"))

@testset "All tests" begin
    cd(joinpath(@__DIR__, "projects", "ProfilingTest", "Platformer", "src"))
    @testset "Platformer" begin
        @test PlatformerModule.run_platformer() == 0
    end

    #include("math/mathtests.jl")
    
    cd(joinpath(SMOKETESTDIR, "src"))
    @test SmokeTest.run(SMOKETESTDIR, Test) == 0

    if !Sys.islinux()
        cd(joinpath(ROOTDIR, "src", "editor", "JulGameEditor", "src"))
        include(joinpath(ROOTDIR, "src", "editor", "JulGameEditor", "src", "../Editor.jl"))
        @testset "Editor" begin
            @test Editor.run(true) == 0
        end
    end
end
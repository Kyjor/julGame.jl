@testset "Open and close" begin
    JulGame.MAIN.testMode = true
    scene = SceneBuilderModule.Scene(joinpath(ROOTDIR , "examples", "Testing", "Testing"), "scene.json")
    main = scene.init("JulGame Example", false, Math.Vector2(1920, 1080),Math.Vector2(576, 576), false, 1.0, true)
end
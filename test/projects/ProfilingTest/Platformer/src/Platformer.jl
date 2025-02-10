module PlatformerModule
    using JulGame
    function run_platformer()
        JulGame.MAIN = JulGame.MainLoop()
        MAIN.testMode = true
        MAIN.testLength = 30.0
        MAIN.currentTestTime = 0.0
        JulGame.PIXELS_PER_UNIT = 16
        scene = JulGame.SceneBuilderModule.Scene("level_0.json")
        try
            SceneBuilderModule.load_and_prepare_scene(scene, JulGame.MAIN)
        catch e
            @error e
            Base.show_backtrace(stderr, catch_backtrace())
            return -1
        end

        return 0
    end
end # module

# comment when building
# Platformer.run()
# using Profile

# @profile Platformer.run()

# Profile.print(format=:flat)

#@profview_allocs Platformer.run() sample_rate = 1
#using Cthulhu
#ProfileView.@profview Platformer.run()
# Click somewhere in the profile
#Cthulhu.descend_clicked()
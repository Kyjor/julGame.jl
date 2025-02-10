module GameManagerModule
    using JulGame

    mutable struct GameManager
        currentLevel::Int32
        currentMusic
        soundBank
        starCount::Int32
        parent

        function GameManager()
            this = new()

            this.currentLevel = 1
            this.parent = C_NULL
            this.soundBank = [
                "water-ambience.mp3",
                "lava.wav",
                "strong-wind.wav",
            ]
            this.starCount = 3

            return this
        end
    end

    function JulGame.initialize(this::GameManager)
        MAIN.scene.camera.offset = JulGame.Math.Vector2f(0, -2.75)
        #todo: MAIN.cameraBackgroundColor = (0, 0, 0)
        MAIN.optimizeSpriteRendering = true

        JulGame.add_shape(this.parent, JulGame.ShapeModule.Shape(Math.Vector3(0,0,0), true, false, 0, Math.Vector2f(0,0), Math.Vector2f(1.2175,0.5), Math.Vector2f(10,5), Int32(255)))
        coinUI = JulGame.SceneModule.get_entity_by_id(MAIN.scene, "44e5d671-cf93-4862-9048-9900f55be3dc")
        livesUI = JulGame.SceneModule.get_entity_by_name(MAIN.scene, "LivesUI")

        # coinUI.persistentBetweenScenes = true
        # coinUI.sprite.isWorldEntity = false
        # coinUI.sprite.position = JulGame.Math.Vector2f(-.1, 1)

        livesUI.persistentBetweenScenes = true
        livesUI.sprite.isWorldEntity = false
        livesUI.sprite.position = JulGame.Math.Vector2f(-.1, .25)
                
        this.parent.persistentBetweenScenes = true
        if this.currentLevel > 1
            # JulGame.Component.unload_sound(this.currentMusic)
        end

        # this.currentMusic = JulGame.create_sound_source(this.parent, JulGame.SoundSourceModule.SoundSource(Int32(-1), true, this.soundBank[this.currentLevel], Int32(25)))
        # JulGame.Component.toggle_sound(this.currentMusic)
        
        MAIN.scene.uiElements[2].text = string(this.starCount)
    end

    function JulGame.update(this::GameManager, deltaTime)
    end

    function JulGame.on_shutdown(this::GameManager)
    end
end # module
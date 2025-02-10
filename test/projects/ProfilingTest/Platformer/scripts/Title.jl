module TitleModule
    using JulGame

    mutable struct Title
        fade
        parent
        textBox

        function Title()
            this = new()

            this.fade = true
            this.parent = C_NULL
            this.textBox = C_NULL

            return this
        end
    end

    function JulGame.initialize(this::Title)
        this.textBox = MAIN.scene.uiElements[1]
    end

    function JulGame.update(this::Title, deltaTime)
        try
            if this.fade 
                this.textBox.alpha -= 1
                this.textBox.text = this.textBox.text
                if this.textBox.alpha <= 25
                    this.fade = false
                end
            else
                this.textBox.alpha += 1
                this.textBox.text = this.textBox.text
                if this.textBox.alpha >= 250
                    this.fade = true
                end
            end

            # sound = JulGame.create_sound_source(this.parent, JulGame.SoundSourceModule.SoundSource(Int32(-1), false, "confirm-ui.wav", Int32(50)))
            # JulGame.Component.toggle_sound(sound)

            JulGame.change_scene("level_1.json")
        catch e
            @error string(e)
            Base.show_backtrace(stdout, catch_backtrace())
            rethrow(e)
        end
    end

    function JulGame.on_shutdown(this::Title)
    end
end # module
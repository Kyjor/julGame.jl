module WaterModule
    using JulGame

    mutable struct Water
        main
        offset
        parent
        
        function Water()
            this = new()

            this.parent = C_NULL
            this.offset = JulGame.Math.Vector2f(0, 0)

            return this
        end
    end

    function JulGame.initialize(this::Water)
        this.offset = JulGame.Math.Vector2f(this.parent.transform.position.x + 9, 5.5)
    end

    function JulGame.update(this::Water, deltaTime)
        this.parent.transform.position = JulGame.Math.Vector2f(MAIN.scene.camera.position.x, 0) + this.offset
    end

    function JulGame.on_shutdown(this::Water)
    end
end # module
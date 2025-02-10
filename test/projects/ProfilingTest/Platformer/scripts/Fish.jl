module FishModule
    using JulGame

    mutable struct Fish
        animator
        endingY::Int32
        isFire::Bool
        isMovingUp::Bool
        parent::JulGame.EntityModule.Entity
        sound::SoundSourceModule.SoundSource
        speed::Number
        startingY::Int32

        function Fish(speed::Number = 5, startingY::Int32 = Int32(0), endingY::Int32 = Int32(0), isFire::Bool = false)
            this = new()

            this.endingY = endingY
            this.isFire = isFire
            this.isMovingUp = false
            this.speed = speed
            this.startingY = startingY

            return this
        end
    end

    function JulGame.initialize(this::Fish)
        this.animator = this.parent.animator
        this.parent.sprite.rotation = 90
    end
    function JulGame.update(this::Fish, deltaTime)
        if this.parent.transform.position.y >= this.startingY && !this.isMovingUp
            this.parent.sprite.rotation = this.isFire ? 0 : 90
            this.isMovingUp = true
        elseif this.parent.transform.position.y <= this.endingY && this.isMovingUp
            this.parent.sprite.rotation = this.isFire ? 180 : 270
            this.isMovingUp = false
        end

        if this.isMovingUp
            this.parent.transform.position = Vector2f(this.parent.transform.position.x, this.parent.transform.position.y - this.speed*deltaTime)
        else
            this.parent.transform.position = Vector2f(this.parent.transform.position.x, this.parent.transform.position.y + this.speed*deltaTime)
        end
    end

    function JulGame.on_shutdown(this::Fish)
    end
end # module
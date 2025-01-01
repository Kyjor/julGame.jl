module ParticleModule
    using ..JulGame

    export Particle
    mutable struct Particle
        currentFrame::Integer
        offset::Math.Vector2
        position::Math.Vector2
        texture::Ptr{SDL2.LibSDL2.SDL_Texture}
        renderer::Ptr{SDL2.LibSDL2.SDL_Renderer}

        function Particle(position::Math.Vector2, image::String)
            this = new()
            
            this.currentFrame = rand(1:5)
            this.offset = Math.Vector2(position.x - 5 + ( rand() % 25 ), position.y - 5 + ( rand() % 25 ))
            
            fullPath = joinpath(@__DIR__, image)

            this.texture = SDL2.SDL_CreateTextureFromSurface(this.renderer, SDL2.IMG_Load(fullPath))

            # Set type
            # if rand() % 3 == 0
            #     mTexture = gRedTexture
            # elseif rand() % 3 == 1
            #     mTexture = gGreenTexture
            # else
            #     mTexture = gBlueTexture
            # end
        
            return this
        end
    end

    function Base.getproperty(this::Particle, s::Symbol)
        if s == :draw
            function()
                if this.isDead()
                    return
                end

                SDL2.SDL_SetTextureAlphaMod(this.texture, 255)
                SDL2.SDL_RenderCopy(MAIN.renderer, this.texture, C_NULL, SDL2.SDL_Rect(this.offset.x, this.offset.y, 10, 10))

                #this.currentFrame += 1
            end
        elseif s == :isDead
            function()
                return this.currentFrame > 10
            end
        else
            try
                getfield(this, s)
            catch e
                println(e)
            end
        end
    end
end

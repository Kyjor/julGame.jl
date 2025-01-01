module DotModule
    using ..JulGame

    export Dot
    mutable struct Dot
        dimensions::Math.Vector2
        offset::Math.Vector2
        maximumVelocity::Integer
        particles::Array{Any}
        texture::Ptr{SDL2.LibSDL2.SDL_Texture}
        velocity::Math.Vector2

        function Dot()
            this = new()

            this.particles = []
            for i in 1:10
                push!(this.particles, ParticleModule.Particle(Math.Vector2(0, 0), "red.bmp"))
            end
            fullPath = joinpath(@__DIR__, "dot.bmp")
            this.texture = SDL2.SDL_CreateTextureFromSurface(MAIN.renderer, SDL2.IMG_Load(fullPath))

            return this
        end
    end

    function Base.getproperty(this::Dot, s::Symbol)
        if s == :draw
            function()
                SDL2.SDL_SetTextureAlphaMod(this.texture, 255)
                SDL2.SDL_RenderCopy(Renderer, this.texture, C_NULL, Ref(SDL2.SDL_Rect(0, 0, 10, 10)))
            end
        elseif s == :move
            function()
    
            end
        elseif s == :drawParticles
            function()
                # Go through particles
                for i in 1:10
                    # Delete and replace dead particles
                    if particles[i].isDead()
                        delete!(particles, i)
                        #particles[i] = Particle(mPosX, mPosY)
                    end
                end

                # Show particles
                for i in 1:10
                    this.draw(particles[i])
                end
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
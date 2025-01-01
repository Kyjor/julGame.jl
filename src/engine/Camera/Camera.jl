module CameraModule
    using JulGame
    using .Math

    export Camera
    mutable struct Camera
		backgroundColor::Tuple{Int64, Int64, Int64, Int64}
        offset::Vector2f
        position::Vector2f
        size::Vector2
        startingCoordinates::Vector2f

        target::Union{
            Ptr{Nothing}, 
            JulGame.TransformModule.Transform
            }
        windowPos::Vector2

        function Camera(size::Vector2, initialPosition::Vector2f, offset::Vector2f, target)
            this = new()
            
            this.backgroundColor = (0,0,0, 255)
            this.size = size
            this.position = initialPosition
            this.offset = Vector2f(offset.x, offset.y)
            this.target = target
            this.startingCoordinates = Vector2f()                                                                                                                                                                                                           
            this.windowPos = Vector2(0,0)

            return this
        end
    end

    function update(this::Camera, newPosition = nothing)
        SDL2.SDL_SetRenderDrawBlendMode(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, SDL2.SDL_BLENDMODE_BLEND)
        rgba = (r = Ref(UInt8(0)), g = Ref(UInt8(0)), b = Ref(UInt8(0)), a = Ref(UInt8(255)))
        SDL2.SDL_GetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r, rgba.g, rgba.b, rgba.a)
        SDL2.SDL_SetRenderDrawColor(Renderer, this.backgroundColor[1], this.backgroundColor[2], this.backgroundColor[3], this.backgroundColor[4]);
        SDL2.SDL_RenderFillRectF(Renderer, Ref(SDL2.SDL_FRect(this.windowPos.x, this.windowPos.y, this.size.x, this.size.y)))
        SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r[], rgba.g[], rgba.b[], rgba.a[]);
        
        center =  Vector2f(this.size.x/SCALE_UNITS/2, this.size.y/SCALE_UNITS/2)
        if this.target !== nothing && newPosition === nothing && this.target !== C_NULL && newPosition !== C_NULL
            targetPos = this.target.position
            targetScale = this.target.scale
            this.position = targetPos - center + 0.5 * targetScale + this.offset
            return
        end
        if newPosition === nothing || newPosition == C_NULL
            return
        end
        this.position = newPosition
    end

    # making set property observable
    function Base.setproperty!(this::Camera, s::Symbol, x)
        @debug("setting camera property $(s) to: $(x)")
        try
            setfield!(this, s, x)
        catch e
            println(e)
        end
    end
end

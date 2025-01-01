module ShapeModule
    using ..Component.JulGame
    import ..Component
    export Shape
    struct Shape
        color::Math.Vector3
        isFilled::Bool
        isWorldEntity::Bool
        layer::Int32
        offset::Math.Vector2f
        position::Math.Vector2f
        size::Math.Vector2f
    end

    export InternalShape
    mutable struct InternalShape
        color::Math.Vector3
        isFilled::Bool
        isWorldEntity::Bool
        layer::Int32
        offset::Math.Vector2f
        position::Math.Vector2f
        parent::Any # Entity
        size::Math.Vector2f
        
        function InternalShape(parent::Any, color::Math.Vector3 = Math.Vector3(255,0,0), isFilled::Bool = true, offset::Math.Vector2f = Math.Vector2f(0,0), size::Math.Vector2f = Math.Vector2f(1,1); isWorldEntity::Bool = true, position::Math.Vector2f = Math.Vector2f(0,0), layer::Int32 = Int32(0))
            this = new()
            
            this.color = color
            this.size = size
            this.isFilled = isFilled
            this.isWorldEntity = isWorldEntity
            this.layer = layer
            this.offset = offset
            this.parent = parent
            this.position = position

            return this
        end
    end

    function Component.draw(this::InternalShape, camera = nothing)
        if JulGame.Renderer::Ptr{SDL2.SDL_Renderer} == C_NULL
            return                    
        end

        parentTransform = this.parent.transform

        cameraDiff = this.isWorldEntity && camera !== nothing ? 
        Math.Vector2((camera.position.x + camera.offset.x) * SCALE_UNITS, (camera.position.y + camera.offset.y) * SCALE_UNITS) : 
        Math.Vector2(0,0)
        position = this.isWorldEntity ?
        parentTransform.position :
        this.position

        outlineRect = Ref(SDL2.SDL_FRect(convert(Int32,round((position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - (parentTransform.scale.x * SCALE_UNITS - SCALE_UNITS) / 2)), 
        convert(Int32,round((position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - (parentTransform.scale.y * SCALE_UNITS - SCALE_UNITS) / 2)),
        convert(Int32,round(parentTransform.scale.x * SCALE_UNITS)), 
        convert(Int32,round(parentTransform.scale.y * SCALE_UNITS))))

        rgba = (r = Ref(UInt8(this.color.x)), g = Ref(UInt8(this.color.y)), b = Ref(UInt8(this.color.z)), a = Ref(UInt8(255)))
        currentDrawColor = SDL2.SDL_GetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r, rgba.g, rgba.b, rgba.a)
        SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.color.x, this.color.y, this.color.z, SDL2.SDL_ALPHA_OPAQUE );      
        this.isFilled ? SDL2.SDL_RenderFillRectF(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, outlineRect) : SDL2.SDL_RenderDrawRectF(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, outlineRect);
        SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r[], rgba.g[], rgba.b[], rgba.a[]);
    end
end

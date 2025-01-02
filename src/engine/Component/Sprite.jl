module SpriteModule
    using ..Component.JulGame
    import ..Component

    export Sprite
    struct Sprite
        color::Math.Vector3
        crop::Union{Ptr{Nothing}, Math.Vector4}
        isFlipped::Bool
        imagePath::String
        isWorldEntity::Bool
        layer::Int32
        offset::Math.Vector2f
        position::Math.Vector2f
        rotation::Float64
        pixelsPerUnit::Int32
        center::Math.Vector2f
    end

    export InternalSprite
    mutable struct InternalSprite
        center::Math.Vector2f
        color::Math.Vector3
        crop::Union{Ptr{Nothing}, Math.Vector4}
        isFlipped::Bool
        isFloatPrecision::Bool
        image::Union{Ptr{Nothing}, Ptr{SDL2.LibSDL2.SDL_Surface}}
        imagePath::String
        isWorldEntity::Bool
        layer::Int32
        offset::Math.Vector2f
        parent::Any # Entity
        position::Math.Vector2f
        rotation::Float64
        pixelsPerUnit::Int32
        size::Math.Vector2
        texture::Union{Ptr{Nothing}, Ptr{SDL2.LibSDL2.SDL_Texture}}
        
        function InternalSprite(parent::Any, imagePath::String, crop::Union{Ptr{Nothing}, Math.Vector4}=C_NULL, isFlipped::Bool=false, color::Math.Vector3 = Math.Vector3(255,255,255), isCreatedInEditor::Bool=false; pixelsPerUnit::Int32=Int32(-1), isWorldEntity::Bool=true, position::Math.Vector2f = Math.Vector2f(0,0), rotation::Float64 = 0.0, layer::Int32 = Int32(0), center::Math.Vector2f = Math.Vector2f(0.5,0.5))
            this = new()

            this.offset = Math.Vector2f()
            this.isFlipped = isFlipped
            this.imagePath = imagePath
            this.center = center
            this.color = color
            this.crop = crop
            this.image = C_NULL
            this.isWorldEntity = isWorldEntity
            this.layer = layer
            this.parent = parent
            this.pixelsPerUnit = pixelsPerUnit
            this.position = position
            this.rotation = rotation
            this.texture = C_NULL
            this.isFloatPrecision = false

            if isCreatedInEditor
                return this
            end
        
            fullPath = joinpath(BasePath, "assets", "images", imagePath)
            
            this.image = load_image_sdl(this, fullPath, imagePath)
            if this.image == C_NULL
                error = unsafe_string(SDL2.SDL_GetError())
                
                println(fullPath)
                println(string("Couldn't open image! SDL Error: ", error))
                Base.show_backtrace(stdout, catch_backtrace())
                return
            end
            surface = unsafe_wrap(Array, this.image, 10; own = false)
            this.size = Math.Vector2(surface[1].w, surface[1].h)
        
            return this
        end
    end
    
    function Component.draw(this::InternalSprite, camera = nothing)
        if this.image == C_NULL || JulGame.Renderer::Ptr{SDL2.SDL_Renderer} == C_NULL
            return
        end
        if this.texture == C_NULL
            this.texture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.image)
            Component.set_color(this)
        end
        colorRefs = (Ref(UInt8(0)), Ref(UInt8(0)), Ref(UInt8(0)))
        SDL2.SDL_GetTextureColorMod(this.texture, colorRefs...)
        if colorRefs[1] != this.color.x || colorRefs[2] != this.color.y || colorRefs[3] != this.color.z
            Component.set_color(this)
        end
       

        parentTransform = this.parent.transform

        cameraDiff = this.isWorldEntity && camera !== nothing ? 
        Math.Vector2((camera.position.x + camera.offset.x) * SCALE_UNITS, (camera.position.y + camera.offset.y) * SCALE_UNITS) : 
        Math.Vector2(0,0)
        position = this.isWorldEntity ?
        parentTransform.position :
        this.position

        srcRect = (this.crop == Math.Vector4(0,0,0,0) || this.crop == C_NULL) ? C_NULL : Ref(SDL2.SDL_Rect(this.crop.x, this.crop.y, this.crop.z, this.crop.t))
        dstRect = Ref(SDL2.SDL_FRect(
            (position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - (parentTransform.scale.x * SCALE_UNITS - SCALE_UNITS) / 2, # TODO: Center the sprite within the entity
            (position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - (parentTransform.scale.y * SCALE_UNITS - SCALE_UNITS) / 2,
            (this.crop == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS,
            (this.crop == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS
        ))

        if this.pixelsPerUnit > 0 || JulGame.PIXELS_PER_UNIT > 0
            ppu = this.pixelsPerUnit > 0 ? this.pixelsPerUnit : JulGame.PIXELS_PER_UNIT
            dstRect = Ref(SDL2.SDL_FRect(
                (position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - ((srcRect == C_NULL ? this.size.x : this.crop.z) * parentTransform.scale.x * SCALE_UNITS / ppu - SCALE_UNITS) / 2,
                (position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - ((srcRect == C_NULL ? this.size.y : this.crop.t) * parentTransform.scale.y * SCALE_UNITS / ppu - SCALE_UNITS) / 2,
                (srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS/ppu,
                (srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS/ppu
            ))     
        end

        if !this.isFloatPrecision
            srcRect = this.crop == Math.Vector4(0,0,0,0) || this.crop == C_NULL ? C_NULL : Ref(SDL2.SDL_Rect(this.crop.x,this.crop.y,this.crop.z,this.crop.t))
            ppu = 16
            dstRect = Ref(SDL2.SDL_Rect(
                convert(Int32, clamp(round((position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - ((srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS / ppu - SCALE_UNITS) / 2), -2147483648, 2147483647)),
                    convert(Int32, clamp(round((position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - ((srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS / ppu - SCALE_UNITS) / 2), -2147483648, 2147483647)),
                    convert(Int32, clamp(round((srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS/ppu*parentTransform.scale.x), -2147483648, 2147483647)),
                    convert(Int32, clamp(round((srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS/ppu*parentTransform.scale.y), -2147483648, 2147483647))
            ))
            if (this.pixelsPerUnit > 0 || JulGame.PIXELS_PER_UNIT > 0) && this.pixelsPerUnit != -1
                ppu = this.pixelsPerUnit > 0 ? this.pixelsPerUnit : JulGame.PIXELS_PER_UNIT
                dstRect = Ref(SDL2.SDL_Rect(
                    convert(Int32, clamp(round((position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - ((srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS / ppu - SCALE_UNITS) / 2), -2147483648, 2147483647)),
                    convert(Int32, clamp(round((position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - ((srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS / ppu - SCALE_UNITS) / 2), -2147483648, 2147483647)),
                    convert(Int32, clamp(round((srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS/ppu*parentTransform.scale.x), -2147483648, 2147483647)),
                    convert(Int32, clamp(round((srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS/ppu*parentTransform.scale.y), -2147483648, 2147483647))
                ))     
            end
        end

         # Calculate center position on sprite using the center property
         # center should be a point from 0 to 1, where 0.5 is the center of the sprite 
         # The value is a pointer to a point indicating the point around which dstrect will be rotated 
         # (if C_NULL, rotation will be done around dstrect.w / 2, dstrect.h / 2)
         # Todo: don't allocate this every frame
        calculatedCenter = Math.Vector2(dstRect[].w * (this.center.x%1), dstRect[].h * (this.center.y%1))
        calculatedCenter = !this.isFloatPrecision ? Ref(SDL2.SDL_Point(round(calculatedCenter.x), round(calculatedCenter.y))) : Ref(SDL2.SDL_FPoint(calculatedCenter.x, calculatedCenter.y))   

        if this.isFloatPrecision && SDL2.SDL_RenderCopyExF(
            JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, 
            this.texture, 
            srcRect, 
            dstRect,
            this.rotation,
            calculatedCenter, # Ref(SDL2.SDL_Point(0,0)) CENTER
            this.isFlipped ? SDL2.SDL_FLIP_HORIZONTAL : SDL2.SDL_FLIP_NONE) != 0

            error = unsafe_string(SDL2.SDL_GetError())
        end

        if  !this.isFloatPrecision && SDL2.SDL_RenderCopyEx(
            JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, 
            this.texture, 
            srcRect, 
            dstRect,
            this.rotation,
            calculatedCenter, 
            this.isFlipped ? SDL2.SDL_FLIP_HORIZONTAL : SDL2.SDL_FLIP_NONE) != 0

            error = unsafe_string(SDL2.SDL_GetError())
        end
    end

    function Component.initialize(this::InternalSprite)
        if this.image == C_NULL
            return
        end

        this.texture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.image)
    end

    function Component.flip(this::InternalSprite)
        this.isFlipped = !this.isFlipped
    end

    function Component.load_image(this::InternalSprite, imagePath::String)
        SDL2.SDL_ClearError()
        this.image = load_image_sdl(this, joinpath(BasePath, "assets", "images", imagePath), imagePath)
        error = unsafe_string(SDL2.SDL_GetError())
        if !isempty(error)
            println(string("Couldn't open image! SDL Error: ", error))
            SDL2.SDL_ClearError()
            this.image = C_NULL
            return
        end

        surface = unsafe_wrap(Array, this.image, 10; own = false)
        this.size = Math.Vector2(surface[1].w, surface[1].h)
        
        this.imagePath = imagePath
        this.texture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.image)
        Component.set_color(this)
    end

    function load_image_sdl(this::InternalSprite, fullPath::String, imagePath::String)
        if haskey(JulGame.IMAGE_CACHE, get_comma_separated_path(imagePath))
            raw_data = JulGame.IMAGE_CACHE[get_comma_separated_path(imagePath)]
            rw = SDL2.SDL_RWFromConstMem(pointer(raw_data), length(raw_data))
            if rw != C_NULL
                @debug("loading image from cache")
                @debug("comma separated path: ", get_comma_separated_path(imagePath))
                return SDL2.IMG_Load_RW(rw, 1)
            end
        end
        @debug "Loading image from disk for sprite, there are $(length(JulGame.IMAGES_CACHE)) images in cache"

        return SDL2.IMG_Load(fullPath)
    end

    function get_comma_separated_path(path::String)
        # Normalize the path to use forward slashes
        normalized_path = replace(path, '\\' => '/')
        
        # Split the path into components
        parts = split(normalized_path, '/')
        
        result = join(parts[1:end], ",")
    
        return result  
    end

    function Component.destroy(this::InternalSprite)
        if this.image == C_NULL
            return
        end

        SDL2.SDL_DestroyTexture(this.texture)
        SDL2.SDL_FreeSurface(this.image)
        this.image = C_NULL
        this.texture = C_NULL
    end

    function Component.set_color(this::InternalSprite)
        SDL2.SDL_SetTextureColorMod(this.texture, UInt8(this.color.x%256), UInt8(this.color.y%256), (this.color.z%256));
    end
end

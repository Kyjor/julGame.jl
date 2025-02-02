module SpriteModule
    using ..Component.JulGame
    import ..Component

    export Sprite
    struct Sprite
        color::Tuple{Int64, Int64, Int64, Int64}
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
        color::Tuple{Int64, Int64, Int64, Int64}
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
        
        function InternalSprite(parent::Any, imagePath::String, crop::Union{Ptr{Nothing}, Math.Vector4}=C_NULL, isFlipped::Bool=false, color::Tuple{Int64, Int64, Int64, Int64} = (255,255,255,255), isCreatedInEditor::Bool=false; pixelsPerUnit::Int32=Int32(-1), isWorldEntity::Bool=true, position::Math.Vector2f = Math.Vector2f(0,0), rotation::Float64 = 0.0, layer::Int32 = Int32(0), center::Math.Vector2f = Math.Vector2f(0.5,0.5))
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
    
        # Create texture if it doesn't exist
        if this.texture == C_NULL
            this.texture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.image)
            Component.set_color(this)
        end
    
        # Check and set color if necessary
        colorRefs = (Ref(UInt8(0)), Ref(UInt8(0)), Ref(UInt8(0)))
        alphaRef = Ref(UInt8(0))
        SDL2.SDL_GetTextureColorMod(this.texture, colorRefs...)
        SDL2.SDL_GetTextureAlphaMod(this.texture, alphaRef)
        if colorRefs[1] != this.color[1] || colorRefs[2] != this.color[2] || colorRefs[3] != this.color[3] || this.color[4] != alphaRef
            Component.set_color(this)
        end
    
        # Calculate camera difference
        cameraDiff = this.isWorldEntity && camera !== nothing ? 
            Math.Vector2((camera.position.x + camera.offset.x) * SCALE_UNITS, (camera.position.y + camera.offset.y) * SCALE_UNITS) : 
            Math.Vector2(0, 0)
    
        # Calculate position
        position = this.isWorldEntity ? this.parent.transform.position : this.position
    
        # Calculate source rectangle
        srcRect = (this.crop == Math.Vector4(0, 0, 0, 0) || this.crop == C_NULL) ? C_NULL : Ref(SDL2.SDL_Rect(this.crop.x, this.crop.y, this.crop.z, this.crop.t))
    
        # Calculate pixels per unit
        ppu = this.pixelsPerUnit > 0 ? this.pixelsPerUnit : JulGame.PIXELS_PER_UNIT
    
        # Precompute values to avoid redundant calculations
        cropWidth = srcRect == C_NULL ? this.size.x : this.crop.z
        cropHeight = srcRect == C_NULL ? this.size.y : this.crop.t
        scaleX = this.parent.transform.scale.x
        scaleY = this.parent.transform.scale.y
    
        # Compute position adjustment
        adjustedX = (position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x
        adjustedY = (position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y
    
        # Handle pixelsPerUnit == 0 (use true size without scaling)
        if this.pixelsPerUnit == 0
            scaledWidth = cropWidth * scaleX
            scaledHeight = cropHeight * scaleY
        else
            # Use pixelsPerUnit or default PIXELS_PER_UNIT for scaling
            ppu = this.pixelsPerUnit > 0 ? this.pixelsPerUnit : JulGame.PIXELS_PER_UNIT
            scaleFactor = SCALE_UNITS / ppu
            scaledWidth = cropWidth * scaleFactor * scaleX
            scaledHeight = cropHeight * scaleFactor * scaleY
        end
    
        # Compute centered position
        # Adjust for scaling to keep the sprite centered on the transform
        centeredX = adjustedX - (scaledWidth - SCALE_UNITS * scaleX) / 2
        centeredY = adjustedY - (scaledHeight - SCALE_UNITS * scaleY) / 2
    
        # Select float or integer precision
        if this.isFloatPrecision
            dstRect = Ref(SDL2.SDL_FRect(centeredX, centeredY, scaledWidth, scaledHeight))
        else
            dstRect = Ref(SDL2.SDL_Rect(
                convert(Int32, clamp(round(centeredX), -2147483648, 2147483647)),
                convert(Int32, clamp(round(centeredY), -2147483648, 2147483647)),
                convert(Int32, clamp(round(scaledWidth), -2147483648, 2147483647)),
                convert(Int32, clamp(round(scaledHeight), -2147483648, 2147483647))
            ))
        end
    
        # Calculate center for rotation
        calculatedCenter = Math.Vector2(dstRect[].w * (this.center.x % 1), dstRect[].h * (this.center.y % 1))
        rotationCenter = !this.isFloatPrecision ? 
            Ref(SDL2.SDL_Point(round(calculatedCenter.x), round(calculatedCenter.y))) :
            Ref(SDL2.SDL_FPoint(calculatedCenter.x, calculatedCenter.y))
    
        # Render with appropriate precision
        renderFn = this.isFloatPrecision ? SDL2.SDL_RenderCopyExF : SDL2.SDL_RenderCopyEx
        if renderFn(
            JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, 
            this.texture, 
            srcRect, 
            dstRect,
            this.rotation, 
            rotationCenter, 
            this.isFlipped ? SDL2.SDL_FLIP_HORIZONTAL : SDL2.SDL_FLIP_NONE
        ) != 0
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
        SDL2.SDL_SetTextureColorMod(this.texture, UInt8(this.color[1]%256), UInt8(this.color[2]%256), (this.color[3]%256));
        SDL2.SDL_SetTextureAlphaMod(this.texture, UInt8(this.color[4]%256));
    end
end

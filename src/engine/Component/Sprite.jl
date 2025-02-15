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
        
            Component.load_image(this::InternalSprite, imagePath::String)
            if this.image == C_NULL
                error = unsafe_string(SDL2.SDL_GetError())
                @error(string("Couldn't open image! path: $(fullPath) SDL Error: ", error))
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

    const FALLBACK_IMAGE_BYTES = UInt8[
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x20, 
        0x00, 0x00, 0x00, 0x20, 0x08, 0x06, 0x00, 0x00, 0x00, 0x73, 0x7a, 0x7a, 0xf4, 0x00, 0x00, 0x00, 0x01, 0x73, 0x52, 0x47, 
        0x42, 0x00, 0xae, 0xce, 0x1c, 0xe9, 0x00, 0x00, 0x01, 0x02, 0x49, 0x44, 0x41, 0x54, 0x58, 0x85, 0xdd, 0x96, 0x4b, 0x0e, 
        0x83, 0x30, 0x0c, 0x44, 0xed, 0xaa, 0x57, 0x61, 0xc9, 0x02, 0x72, 0x14, 0xae, 0x59, 0x8e, 0x12, 0x75, 0xd1, 0x25, 0x87, 
        0x71, 0x37, 0x0d, 0xa2, 0x40, 0xc3, 0xd8, 0x71, 0x68, 0xd5, 0x59, 0x81, 0x64, 0x65, 0x5e, 0x7e, 0x9e, 0x30, 0x01, 0x12, 
        0x11, 0x41, 0xea, 0x98, 0x99, 0x91, 0xba, 0xa5, 0xae, 0x88, 0xf9, 0x18, 0x02, 0x34, 0x58, 0x02, 0xd5, 0x80, 0x1c, 0x16, 
        0xde, 0xfa, 0x7e, 0x33, 0xfb, 0xb6, 0xe9, 0x36, 0x75, 0x8f, 0xe9, 0x3e, 0x7f, 0x0f, 0x31, 0xc2, 0x10, 0xd9, 0x22, 0x64, 
        0xf6, 0x6b, 0x98, 0x04, 0x82, 0x42, 0x7c, 0x2c, 0xd0, 0x2c, 0xfd, 0x1a, 0x44, 0x03, 0x71, 0x78, 0x06, 0x50, 0x2d, 0xb7, 
        0xa0, 0x6d, 0xba, 0xb7, 0xff, 0x9c, 0x2e, 0x5e, 0x00, 0x56, 0xfd, 0x27, 0x00, 0xba, 0xfc, 0x59, 0x00, 0x66, 0xe6, 0x21, 
        0x46, 0x17, 0x20, 0x13, 0x40, 0xa9, 0xd0, 0x6b, 0xf8, 0xdb, 0x67, 0xe0, 0x8c, 0x6d, 0xa8, 0xb2, 0x02, 0x9a, 0x56, 0xec, 
        0x0e, 0xa0, 0x31, 0x27, 0x02, 0xc2, 0x88, 0x08, 0x6f, 0xcb, 0x5a, 0x73, 0x18, 0x00, 0x81, 0xb0, 0x98, 0xab, 0x00, 0x72, 
        0x10, 0x56, 0x73, 0x35, 0x40, 0x82, 0x20, 0x22, 0x4a, 0x20, 0x25, 0xe6, 0x45, 0x92, 0x97, 0x4e, 0x37, 0xf6, 0x96, 0x79, 
        0x0b, 0x76, 0x07, 0xab, 0xf1, 0x28, 0x5d, 0x9b, 0xe7, 0x6e, 0x82, 0x88, 0x88, 0x16, 0x02, 0x06, 0xc8, 0x99, 0xa7, 0xe7, 
        0xd8, 0x18, 0x82, 0x1a, 0xc2, 0xa5, 0x13, 0xa6, 0xfc, 0x6f, 0x9b, 0x6e, 0x86, 0x38, 0x15, 0x60, 0x09, 0xa1, 0x95, 0x6b, 
        0x16, 0x58, 0x20, 0x60, 0x80, 0x5a, 0xd1, 0x6c, 0xba, 0x86, 0x9e, 0x99, 0x60, 0x6a, 0xa1, 0x9e, 0x99, 0x60, 0xee, 0xe1, 
        0x7b, 0x27, 0xfd, 0x2b, 0x99, 0x50, 0xaa, 0x27, 0x9d, 0x07, 0x96, 0x9b, 0xca, 0xab, 0x4b, 0x6c, 0x00, 0x00, 0x00, 0x00, 
        0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
    ]  # This is a 1x1 transparent PNG image.

    function load_fallback_image()
        rwops = SDL2.SDL_RWFromMem(pointer(FALLBACK_IMAGE_BYTES), length(FALLBACK_IMAGE_BYTES))
        if rwops == C_NULL
            @error("Failed to create SDL_RWops for fallback image.")
            return C_NULL
        end
        image = SDL2.IMG_Load_RW(rwops, 1)  # Load directly from memory and free rwops after use
        return image
    end

    function Component.load_image(this::InternalSprite, imagePath::String)
        SDL2.SDL_ClearError()
    
        fullPath = joinpath(BasePath, "assets", "images", imagePath)
        this.image = load_image_sdl(this, fullPath, imagePath)
        error = unsafe_string(SDL2.SDL_GetError())
    
        if !isempty(error) || this.image == C_NULL
            @error("Couldn't open image '$imagePath'! SDL Error: ", error)
            SDL2.SDL_ClearError()
    
            # Load from byte array
            this.image = load_fallback_image()
            this.imagePath = "fallback.png"
            this.pixelsPerUnit = 0
            if this.image == C_NULL
                @error("Fallback image also failed to load! $(unsafe_string(SDL2.SDL_GetError()))")
                return
            end
        else
            this.imagePath = imagePath
        end
    
        # Get image size
        surface = unsafe_wrap(Array, this.image, 10; own = false)
        this.size = Math.Vector2(surface[1].w, surface[1].h)
    
        # Create texture
        this.texture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.image)
    
        if this.texture == C_NULL
            @error("Failed to create texture from image.")
            return
        end
    
        Component.set_color(this)
    end

    function load_image_sdl(this::InternalSprite, fullPath::String, imagePath::String)
        if haskey(JulGame.IMAGE_CACHE, get_comma_separated_path(imagePath))
            raw_data = JulGame.IMAGE_CACHE[get_comma_separated_path(imagePath)]
            rw = SDL2.SDL_RWFromConstMem(pointer(raw_data), length(raw_data))
            if rw != C_NULL
                @debug("loading image from cache")
                @debug("comma separated path: ", get_comma_separated_path(imagePath))
                SDL2.IMG_Load_RW(rw, 1)
            end
        end
        @debug "Loading image from disk $(fullPath) for sprite, there are $(length(JulGame.IMAGE_CACHE)) images in cache"

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
        this.image = C_NULL
        this.texture = C_NULL
    end

    function Component.set_color(this::InternalSprite)
        SDL2.SDL_SetTextureColorMod(this.texture, UInt8(this.color[1]%256), UInt8(this.color[2]%256), (this.color[3]%256));
        SDL2.SDL_SetTextureAlphaMod(this.texture, UInt8(this.color[4]%256));
    end
end

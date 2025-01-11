module ScreenButtonModule    
    using ..UI.JulGame
    using ..UI.JulGame.Math
    import ..UI

    export ScreenButton
    mutable struct ScreenButton
        alpha
        clickEvents::Vector{Function}
        currentTexture
        buttonDownSprite
        buttonDownSpritePath::String
        buttonDownTexture
        #TODO: add buttonHoverSprite/Color Mod 
        buttonUpSprite
        buttonUpSpritePath::String
        buttonUpTexture
        fontPath::Union{String, Ptr{Nothing}}
        isHovered::Bool
        isInitialized::Bool
        mouseOverSprite
        name::String
        persistentBetweenScenes::Bool
        position::Math.Vector2
        size::Math.Vector2
        text::String
        textOffset::Math.Vector2
        textSize::Math.Vector2
        textTexture

        function ScreenButton(name::String, buttonUpSpritePath::String, buttonDownSpritePath::String, size::Math.Vector2, position::Math.Vector2, fontPath::Union{String, Ptr{Nothing}} = C_NULL, text::String="", textOffset::Math.Vector2=Math.Vector2(0,0))
            this = new()
            
            this.buttonDownSpritePath = buttonDownSpritePath
            this.buttonUpSpritePath = buttonUpSpritePath
            this.buttonDownSprite = load_image_sdl(joinpath(JulGame.BasePath, "assets", "images"), buttonDownSpritePath)
            this.buttonUpSprite = load_image_sdl(joinpath(JulGame.BasePath, "assets", "images"), buttonUpSpritePath)
            this.clickEvents = []
            this.currentTexture = C_NULL
            this.size = size
            this.fontPath = fontPath
            this.mouseOverSprite = false
            this.name = name
            this.position = position
            this.text = text
            this.textOffset = textOffset
            this.textTexture = C_NULL
            this.isInitialized = false
            this.persistentBetweenScenes = false
            this.isHovered = false

            return this
        end
    end

    function UI.render(this::ScreenButton, debug)
        if !this.isInitialized
            UI.initialize(this)
        end

        if !this.mouseOverSprite && this.currentTexture == this.buttonDownTexture
            #TODO: this.currentTexture = this.buttonUpTexture
        end    
        if this.currentTexture == C_NULL || 
            #this.textTexture == C_NULL || 
            this.currentTexture === nothing #|| this.textTexture === nothing
            return
        end

        @assert SDL2.SDL_RenderCopyExF(
            JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, 
            this.currentTexture, 
            C_NULL, 
            Ref(SDL2.SDL_FRect(this.position.x, this.position.y, this.size.x,this.size.y)), 
            0.0, 
            C_NULL, 
            SDL2.SDL_FLIP_NONE) == 0 "error rendering image: $(unsafe_string(SDL2.SDL_GetError()))"

        # @assert SDL2.SDL_RenderCopyF(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.textTexture, C_NULL, Ref(SDL2.SDL_FRect(this.position.x + this.textOffset.x, this.position.y + this.textOffset.y,this.textSize.x,this.textSize.y))) == 0 "error rendering button text: $(unsafe_string(SDL2.SDL_GetError()))"
    end

    function UI.initialize(this::ScreenButton)
        this.buttonDownTexture = CallSDLFunction(SDL2.SDL_CreateTextureFromSurface, JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.buttonDownSprite)
        this.buttonUpTexture = CallSDLFunction(SDL2.SDL_CreateTextureFromSurface, JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.buttonUpSprite)
        this.currentTexture = this.buttonUpTexture

        if this.fontPath == C_NULL
            this.isInitialized = true
            return
        end

        #font = CallSDLFunction(SDL2.TTF_OpenFont, joinpath(JulGame.BasePath, "assets", "fonts", this.fontPath), 64)
        # text = font != C_NULL ? CallSDLFunction(SDL2.TTF_RenderUTF8_Blended, font, this.text, SDL2.SDL_Color(255,255,255,255)) : C_NULL
        # surface = unsafe_wrap(Array, text, 10; own = false)
        # this.textSize = Math.Vector2(surface[1].w, surface[1].h)
        # this.textTexture = CallSDLFunction(SDL2.SDL_CreateTextureFromSurface, JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, text)
        this.isInitialized = true
    end

    function UI.load_button_sprite_editor(this::ScreenButton, path::String, up::Bool)
        sprite = load_image_sdl(joinpath(JulGame.BasePath, "assets", "images", path), path)
        texture = CallSDLFunction(SDL2.SDL_CreateTextureFromSurface, JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, sprite)
        if up
            this.buttonUpSpritePath = path
            this.buttonUpSprite = sprite
            this.buttonUpTexture = texture
        else
            this.buttonDownSpritePath = path
            this.buttonDownSprite = sprite
            this.buttonDownTexture = texture
        end

        this.currentTexture = texture
    end

    function load_image_sdl(fullPath::String, imagePath::String)
        if haskey(JulGame.IMAGE_CACHE, get_comma_separated_path(imagePath))
            raw_data = JulGame.IMAGE_CACHE[get_comma_separated_path(imagePath)]
            rw = SDL2.SDL_RWFromConstMem(pointer(raw_data), length(raw_data))
            if rw != C_NULL
                @debug("loading image at $(imagePath) from cache")
                @debug("comma separated path: ", get_comma_separated_path(imagePath))
                return SDL2.IMG_Load_RW(rw, 1)
            end
        end
        @debug "Loading image from disk, there are $(length(JulGame.IMAGE_CACHE)) images in cache"

        return CallSDLFunction(SDL2.IMG_Load, joinpath(fullPath, imagePath))
    end

    function get_comma_separated_path(path::String)
        # Normalize the path to use forward slashes
        normalized_path = replace(path, '\\' => '/')
        
        # Split the path into components
        parts = split(normalized_path, '/')
        
        result = join(parts[1:end], ",")
    
        return result  
    end

    function UI.add_click_event(this::ScreenButton, event)
        push!(this.clickEvents, event)
    end

    function UI.handle_event(this::ScreenButton, evt, x, y)
        if evt.type == evt.type == SDL2.SDL_MOUSEBUTTONDOWN
        this.currentTexture = this.buttonDownTexture
        elseif evt.type == SDL2.SDL_MOUSEBUTTONUP
            this.currentTexture = this.buttonUpTexture
            for eventToCall in this.clickEvents
                Base.invokelatest(eventToCall,(evt = evt, x = x, y = y))
            end
        elseif evt.type == SDL2.SDL_MOUSEMOTION
            this.isHovered = true
        end 
    end
    
    function UI.destroy(this::ScreenButton)
        if this.buttonDownTexture != C_NULL
            SDL2.SDL_DestroyTexture(this.buttonDownTexture)
        end
        if this.buttonUpTexture != C_NULL
            SDL2.SDL_DestroyTexture(this.buttonUpTexture)
        end
        this.buttonDownTexture = C_NULL
        this.buttonUpTexture = C_NULL
        this.currentTexture = C_NULL
    end
end

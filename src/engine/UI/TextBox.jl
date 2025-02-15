module TextBoxModule
    using ..UI.JulGame
    using ..UI.JulGame.Math
    import ..UI
    export TextBox      
    mutable struct TextBox
        alpha
        anchorOffset::Vector2
        #anchor::JulGame.Enum
        clickEvents
        font
        fontPath::String
        fontSize::Int32
        id::String
        isActive::Bool
        isCenteredX::Bool
        isCenteredY::Bool
        isHovered::Bool
        isWorldEntity::Bool
        name::String
        persistentBetweenScenes::Bool
        position::Vector2
        renderText
        size::Vector2
        text::String
        textTexture
        isConstructed::Bool

        function TextBox(name::String, fontPath::String, fontSize::Number, position::Math.Vector2, text::String, isCenteredX::Bool = false, isCenteredY::Bool = false; anchorOffset::Math.Vector2 = Math.Vector2(0,0), id::String=JulGame.generate_uuid(), isWorldEntity::Bool=false) # TODO: replace bool with enum { left, center, right, etc }
            this = new()

            this.isConstructed = false
            this.alpha = 255
            this.clickEvents = []
            this.fontPath = fontPath
            this.fontSize = Int32(fontSize)
            this.id = id
            this.anchorOffset = anchorOffset
            this.isCenteredX = isCenteredX
            this.isCenteredY = isCenteredY
            this.name = name
            this.position = position
            setfield!(this, :text, text)
            this.isHovered = false
            this.isWorldEntity = isWorldEntity
            this.textTexture = C_NULL
            this.persistentBetweenScenes = false
            this.isActive = true
            this.renderText = C_NULL
            
            if fontPath == ""
                fontPath = joinpath("FiraCode-Regular.ttf")
            end

            UI.load_font(this, joinpath(BasePath, "assets", "fonts"), fontPath)
            this.isConstructed = true

            return this
        end
    end

    function UI.render(this::TextBox, debug::Bool)
        if this.textTexture == C_NULL || !this.isActive
            return
        end

        if debug
            rgba = (r = Ref(UInt8(0)), g = Ref(UInt8(0)), b = Ref(UInt8(0)), a = Ref(UInt8(255)))
            SDL2.SDL_GetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r, rgba.g, rgba.b, rgba.a)
            SDL2.SDL_SetRenderDrawColor(Renderer, 0, 255, 0, 255);
            SDL2.SDL_RenderDrawLines(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, [
                SDL2.SDL_Point(this.position.x, this.position.y), 
                SDL2.SDL_Point(this.position.x + this.size.x, this.position.y),
                SDL2.SDL_Point(this.position.x + this.size.x, this.position.y + this.size.y), 
                SDL2.SDL_Point(this.position.x, this.position.y + this.size.y), 
                SDL2.SDL_Point(this.position.x, this.position.y)], 5)
            SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r[], rgba.g[], rgba.b[], rgba.a[]);
        end

        camera = MAIN.scene.camera
        cameraDiff = this.isWorldEntity && camera !== nothing ? 
        Math.Vector2((camera.position.x + camera.offset.x) * SCALE_UNITS, (camera.position.y + camera.offset.y) * SCALE_UNITS) : 
        Math.Vector2(0,0)

        @assert SDL2.SDL_RenderCopyF(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.textTexture, C_NULL, Ref(SDL2.SDL_FRect(this.position.x - cameraDiff.x, this.position.y - cameraDiff.y, this.size.x, this.size.y))) == 0 "error rendering textbox text: $(unsafe_string(SDL2.SDL_GetError()))"
    end

    function UI.load_font(this::TextBox, basePath::String, fontPath::String)
        @debug string("loading font from $(basePath)\\$(fontPath)")
        this.font = load_font_sdl(basePath, fontPath, this.fontSize)
        if this.font == C_NULL
            error("Failed to load font")
            return
        end
        if fontPath != joinpath("FiraCode-Regular.ttf")
            this.fontPath = fontPath
        end

        this.renderText = CallSDLFunction(SDL2.TTF_RenderUTF8_Blended, this.font, this.text, SDL2.SDL_Color(255,255,255,this.alpha))
        
        surface = unsafe_wrap(Array, this.renderText, 10; own = false)
        this.size = Math.Vector2(surface[1].w, surface[1].h)
        
        this.textTexture = CallSDLFunction(SDL2.SDL_CreateTextureFromSurface, JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.renderText)
    end

    function UI.initialize(this::TextBox)
        if !this.isWorldEntity
            UI.center_text(this)
        end
    end

    function UI.add_click_event(this::TextBox, event)
        push!(this.clickEvents, event)
    end

    function UI.handle_event(this::TextBox, evt, x, y)
        if evt.type == evt.type == SDL2.SDL_MOUSEBUTTONDOWN
        elseif evt.type == SDL2.SDL_MOUSEBUTTONUP
            for eventToCall in this.clickEvents
                Base.invokelatest(eventToCall,(evt = evt, x = x, y = y))
            end
        elseif evt.type == SDL2.SDL_MOUSEMOTION
            this.isHovered = true
        end 
    end

    function load_font_sdl(basePath::String, fontPath::String, fontSize::Int32)
        if haskey(JulGame.FONT_CACHE, get_comma_separated_path(fontPath))
            raw_data = JulGame.FONT_CACHE[get_comma_separated_path(fontPath)]
            rw = SDL2.SDL_RWFromConstMem(pointer(raw_data), length(raw_data))
            if rw != C_NULL
                @debug("loading font from cache")
                @debug("comma separated path: ", get_comma_separated_path(fontPath))
                return SDL2.TTF_OpenFontRW(rw, 1, fontSize)
            end
        end
        @debug "Loading font from disk, there are $(length(JulGame.FONT_CACHE)) fonts in cache"
        return CallSDLFunction(SDL2.TTF_OpenFont, joinpath(basePath, fontPath), fontSize)
    end

    function get_comma_separated_path(path::String)
        # Normalize the path to use forward slashes
        normalized_path = replace(path, '\\' => '/')
        
        # Split the path into components
        parts = split(normalized_path, '/')
        
        result = join(parts[1:end], ",")
    
        return result  
    end

    """
        rerender_text(this::TextBox)

    Recreates the font surface and texture. If the TextBox is not a world entity, it centers the text.

    # Arguments
    - `this::TextBox`: The TextBox object to update.

    # Examples
    """
    function UI.rerender_text(this::TextBox)
        if this.renderText != C_NULL
            SDL2.SDL_FreeSurface(this.renderText)
        end
        if this.textTexture != C_NULL
            SDL2.SDL_DestroyTexture(this.textTexture)
        end

        this.renderText = SDL2.TTF_RenderUTF8_Blended(this.font, this.text, SDL2.SDL_Color(255,255,255,(this.alpha+1)%256))
        surface = unsafe_wrap(Array, this.renderText, 10; own = false)

        this.size = Math.Vector2(surface[1].w, surface[1].h)
        this.textTexture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, this.renderText)
        
        if !this.isWorldEntity
            UI.center_text(this)
        end
    end

    function UI.set_color(this::TextBox, r,g,b)
        SDL2.SDL_SetTextureColorMod(this.textTexture, r%256, g%256, b%256);
    end

    function UI.center_text(this::TextBox)
        if MAIN.scene.camera === nothing
            @warn "No camera found in scene"
            return
        end

        if this.isCenteredX
            this.position = Math.Vector2(max(MAIN.scene.camera.size.x/2 - this.size.x/2, 0) + this.anchorOffset.x, this.position.y)    
        end
        if this.isCenteredY
            this.position = Math.Vector2(this.position.x, max(MAIN.scene.camera.size.y/2 - this.size.y/2, 0) + this.anchorOffset.y)
        end
    end
    
    function UI.update_font_size(this::TextBox, newSize::Int32; basePath::String = "")
        this.fontSize = newSize
        # TODO: SDL2.TTF_SetFontSize(this.font, newSize)
        # close font, reopen with new size
        if basePath == ""
            basePath = joinpath(BasePath, "assets", "fonts")
        end

        SDL2.TTF_CloseFont(this.font)
        UI.load_font(this, basePath, joinpath(this.fontPath))
    end

    function UI.destroy(this::TextBox)
        if this.textTexture == C_NULL
            return
        end

        SDL2.SDL_DestroyTexture(this.textTexture)
        this.textTexture = C_NULL
    end

    function Base.setproperty!(this::TextBox, s::Symbol, x)
        @debug("setting textbox property $(s) to: $(x)")
        try
            setfield!(this, s, x)
            if s == :text || s == :alpha || s == :isActive
                if length(x) == 0
                    setfield!(this, s, " ")# prevents segfault when text is empty
                end
                if this.isConstructed
                    UI.rerender_text(this) # this line MUST stay inside the if for specific fields as we can't call this on fields that are used in this function
                end
            end
        catch e
            error(e)
            Base.show_backtrace(stderr, catch_backtrace())
        end
    end

end

module SceneBuilderModule
    using ...JulGame
    using ...CameraModule
    using ...ColliderModule
    using ...EntityModule
    using ...Math
    using ...RigidbodyModule
    using ...TextBoxModule
    using ...ScreenButtonModule
    using ..SceneReaderModule
    using JSON3

    export Scene
    mutable struct Scene
        scene
        srcPath::String
        type::String

        function Scene(sceneFileName::String, srcPath::String = joinpath(pwd(), ".."), type::String="SDLRenderer")
            this = new()  

            this.scene = sceneFileName
            this.srcPath = srcPath 
            this.type = type
            path = Base.load_path()[1]
            JulGame.IS_PACKAGE_COMPILED = occursin("share", path) && occursin("Project.toml", path)
            if Sys.isapple() && JulGame.IS_PACKAGE_COMPILED
                srcPath = joinpath(join(split(path, "/")[1:findfirst(x -> x == "Build", split(path, "/"))], "/"))
            end

            JulGame.BasePath = srcPath
            if type == "Web"
                JulGame.IS_WEB = true
            end

            return this
        end    
    end
    
    function load_and_prepare_scene(this::Scene, main; config=parse_config(), windowName::String="Game", isWindowResizable::Bool=false, globals = [])
        config = fill_in_config(config)

        windowName::String = windowName
        size::Vector2 = Vector2(parse(Int32, get(config, "Width", DEFAULT_CONFIG["Width"])), parse(Int32, get(config, "Height", DEFAULT_CONFIG["Height"])))
        isResizable::Bool = isWindowResizable
        targetFrameRate::Int32 = parse(Int32, get(config, "FrameRate", DEFAULT_CONFIG["FrameRate"]))

        if main !== nothing
            JulGame.MAIN = main
        end
        MAIN.windowName = windowName
        MAIN.globals = globals
        MAIN.level = this
        MAIN.targetFrameRate = targetFrameRate
        MAIN.scene.name = split(this.scene, ".")[1]

        if size == Math.Vector2()
			displayMode = SDL2.SDL_DisplayMode[SDL2.SDL_DisplayMode(0x12345678, 800, 600, 60, C_NULL)]
			SDL2.SDL_GetCurrentDisplayMode(0, pointer(displayMode))
			size = Math.Vector2(displayMode[1].w, displayMode[1].h)
		end

        flags = SDL2.SDL_RENDERER_ACCELERATED |
		(size == Math.Vector2() ? SDL2.SDL_WINDOW_FULLSCREEN_DESKTOP : 0)  |
        (get(config, "Fullscreen", DEFAULT_CONFIG["Fullscreen"]) == "1" ? SDL2.SDL_WINDOW_FULLSCREEN_DESKTOP : 0)

        MAIN.screenSize = size
        
        if !JulGame.IS_EDITOR && !JulGame.IS_WEB
            MAIN.window = SDL2.SDL_CreateWindow(MAIN.windowName, SDL2.SDL_WINDOWPOS_CENTERED, SDL2.SDL_WINDOWPOS_CENTERED, MAIN.screenSize.x, MAIN.screenSize.y, flags)
            JulGame.Renderer::Ptr{SDL2.SDL_Renderer} = SDL2.SDL_CreateRenderer(MAIN.window, -1, SDL2.SDL_RENDERER_ACCELERATED)
        end

        scene = deserialize_scene(joinpath(BasePath, "scenes", this.scene))
        MAIN.scene.entities = scene[1]
        MAIN.scene.uiElements = scene[2]
        MAIN.scene.camera = scene[3]
        
        if size.x < MAIN.scene.camera.size.x && size.x > 0
            MAIN.scene.camera.size = Vector2(size.x, MAIN.scene.camera.size.y)
        end
        if size.y < MAIN.scene.camera.size.y && size.y > 0
            MAIN.scene.camera.size = Vector2(MAIN.scene.camera.size.x, size.y)
        end
        if !JulGame.IS_EDITOR && !JulGame.IS_WEB
            SDL2.SDL_RenderSetLogicalSize(JulGame.Renderer, MAIN.scene.camera.size.x, MAIN.scene.camera.size.y)
        end
        
        for uiElement in MAIN.scene.uiElements
            if "$(typeof(uiElement))" == "JulGame.UI.TextBoxModule.Textbox" && !uiElement.isWorldEntity
                UI.center_text(uiElement)
            end
        end

        MAIN.scene.rigidbodies = InternalRigidbody[]
        MAIN.scene.colliders = InternalCollider[]
        add_scripts_to_entities(BasePath)

        MAIN.assets = joinpath(BasePath, "assets")
        JulGame.MainLoopModule.prepare_window_scripts_and_start_loop(size)
    end

    function deserialize_and_build_scene(this::Scene)
        scene = deserialize_scene(joinpath(BasePath, "scenes", this.scene))
        
        @debug String("Changing scene to $(this.scene)")
        @debug String("Entities in main scene: $(length(MAIN.scene.entities))")

        for entity in scene[1]
            if !any(e.id == entity.id for e in MAIN.scene.entities)
                push!(MAIN.scene.entities, entity)
            else
                @warn("duplicate entity found (persistence)")
            end
        end
        
        for uiElement in scene[2]
            if !any(e.id == uiElement.id for e in MAIN.scene.uiElements)
                push!(MAIN.scene.uiElements, uiElement)
            else
                @warn("duplicate ui element found (persistence)")
            end
        end

        for uiElement in MAIN.scene.uiElements
            if "$(typeof(uiElement))" == "JulGame.UI.TextBoxModule.Textbox" && uiElement.isWorldEntity
                UI.center_text(uiElement)
            end
        end

        MAIN.scene.camera = scene[3]

        for entity in MAIN.scene.entities
            if entity.persistentBetweenScenes #TODO: Verify if the entity is in it's first scene. If it is, don't skip the scripts.
                continue
            end
            
            if entity.rigidbody != C_NULL
                push!(MAIN.scene.rigidbodies, entity.rigidbody)
            end
            if entity.collider != C_NULL
                push!(MAIN.scene.colliders, entity.collider)
            end
        end 

        add_scripts_to_entities(BasePath)
    end

    """
    create_new_entity(this::Scene)

    Create a new entity and add it to the scene.

    # Arguments
    - `this::Scene`: The scene object to which the entity will be added.

    """
    function create_new_entity(this::Scene)
        push!(MAIN.scene.entities, Entity("New entity"))
    end

    function create_new_text_box(this::Scene)
        textBox = TextBox("TextBox", "", 40, Vector2(0, 200), "TextBox", true, true)
        JulGame.initialize(textBox)
        push!(MAIN.scene.uiElements, textBox)
    end
    
    function create_new_screen_button(this::Scene)
        screenButton = ScreenButton("name", "ButtonUp.png", "ButtonDown.png", Vector2(256, 64), Vector2(0, 0), joinpath("FiraCode-Regular.ttf"), "test")
        JulGame.initialize(screenButton)
        push!(MAIN.scene.uiElements, screenButton)
    end

    function add_scripts_to_entities(path::String)
        @debug string("Adding scripts to entities")
        @debug string("Path: ", path)
        @debug string("Entities: ", length(MAIN.scene.entities))
        if !JulGame.IS_PACKAGE_COMPILED
            @debug "Package not compiled, loading scripts"
            foreach(file -> try
                Base.include(JulGame.ScriptModule, file)
            catch e
                println("Error including $file: ", e)
            end, filter(contains(r".jl$"), readdir(joinpath(path, "scripts"); join=true)))
        end

        scripts_mod = filter(x -> occursin(r"\.Scripts$", string(x)), ccall(:jl_module_usings, Any, (Any,), getfield(Main, Symbol("$(JulGame.ProjectModule)"))))
        if scripts_mod !== nothing
            JulGame.ScriptModule = scripts_mod[1]
        end

        for entity in MAIN.scene.entities
            scriptCounter = 1
            for script in entity.scripts
                if !isa(script, JSON3.Object)
                    scriptCounter += 1
                    continue
                end
                @debug String("Adding script: $(script.name) to entity: $(entity.name)")

                newScript = nothing
                try
                    module_name = getfield(JulGame.ScriptModule, Symbol("$(script.name)Module"))
                    constructor = Base.invokelatest(getfield, module_name, Symbol(script.name)) 
                    newScript = Base.invokelatest(constructor)
                    scriptFields = get(script, "fields", Dict())
                    @debug("getting fields for: $(script)")
                    for (key, value) in scriptFields
                        ftype = nothing
                        try
                            ftype = fieldtype(typeof(newScript), Symbol(key))
                            @debug("type: $(ftype)")
                            if ftype <: EditorExport
                                @debug "Overwriting $(key) to $(value) using scene file"
                                Base.invokelatest(setfield!, newScript, key, EditorExport(value))
                                continue
                            elseif value === nothing
                                @debug "Value is nothing"
                                continue
                            end
                        catch e
                            @warn string(e)
                        end
                    end
                catch e
                    @error string(e)
                    Base.show_backtrace(stdout, catch_backtrace())
                end
                if newScript != C_NULL && newScript !== nothing
                    entity.scripts[scriptCounter] = newScript
                    newScript.parent = entity
                end
                scriptCounter += 1
            end
        end
    end

    # Define default configuration values
    const DEFAULT_CONFIG = Dict(
        "Width" => "800",
        "Height" => "600",
        "FrameRate" => "60",
        "Fullscreen" => "0"
    )

    # Function to read and parse the config file
    function parse_config()
        filename = joinpath(JulGame.BasePath, "config.julgame")
        config = copy(DEFAULT_CONFIG)
        
        if isfile(filename)
            # Open the file for reading
            open(filename, "r") do file
                for line in eachline(file)
                    # Split the line at the '=' character
                    parts = split(line, "=", limit=2)
                    if length(parts) == 2
                        key, value = parts[1], parts[2]
                        # Strip any extra whitespace and add to dictionary
                        config[strip(key)] = strip(value)
                    end
                end
            end
        end

        write_config(filename, config)
        
        return config
    end

    function fill_in_config(config)
        for (key, value) in DEFAULT_CONFIG
            if !haskey(config, key)
                config[key] = value
            end
        end

        return config
    end

    # Function to write values to the config file
    function write_config(filename::String, config::Dict{String, String})
        # Open the file for writing
        open(filename, "w") do file
            for (key, value) in config
                # Write each key-value pair to the file
                println(file, "$key=$value")
            end
        end
    end

    function instantiate_script(script_name::String)
        # Instantiate the struct from the module
        new_script = eval(Symbol("$(script_name)module.$script_name"))()
        return new_script
    end
end # module


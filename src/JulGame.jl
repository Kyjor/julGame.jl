module JulGame
    include("utils/CommonFunctions.jl")
    using SimpleDirectMediaLayer
    const SDL2 = SimpleDirectMediaLayer
    MAIN = nothing

    IS_WEB::Bool = false
    IS_EDITOR::Bool = false
    IS_EDITOR_PLAY_MODE::Bool = false
    IS_DEBUG::Bool = false
    IS_PACKAGE_COMPILED::Bool = false

    DELTA_TIME = 0.0
    # TODO: Create a globals file
    
    SCENE_CACHE::Dict = Dict{String, Any}()
    IMAGE_CACHE::Dict = Dict{String, Any}()
    FONT_CACHE::Dict = Dict{String, Any}()
    AUDIO_CACHE::Dict = Dict{String, Any}()

    Coroutines::Vector = []

    ProjectModule = ""
    ScriptModule = Module(:Scripts)

    include("ModuleExtensions/SDL2Extension.jl")
    const SDL2E = SDL2Extension
    export DELTA_TIME, IS_EDITOR, SDL2, SDL2E, MAIN

    include("utils/Structs.jl")
    export EditorExport, Enum

    include("Coroutine/Coroutine.jl")
    using .CoroutineModule
    export Coroutine
    
    include("utils/Types.jl")
    export Script

    include("utils/Utils.jl")
    export CallSDLFunction

    include("utils/Constants.jl")
    export SCALE_UNITS, GRAVITY

    PIXELS_PER_UNIT = -1
    export PIXELS_PER_UNIT
    
    BasePath = ""
    export BasePath

    Renderer = Ptr{SDL2.LibSDL2.SDL_Renderer}(C_NULL)
    export Renderer
    
    include("utils/Macros.jl")
    using .Macros: @event, @argevent
    export @event, @argevent

    include("Math/Math.jl")
    using .Math: Math
    export Math

    include("engine/DataManagement/DataManagement.jl")
    using .DataManagement: PrefHandlerModule
    export PrefHandlerModule

    include("engine/Input/Input.jl")
    using .InputModule: Input
    export Input

    include("engine/UI/UI.jl")
    using .UI
    export ScreenButtonModule, TextBoxModule

    include("engine/Component/Component.jl")
    using .Component
    export AnimationModule, AnimatorModule, ColliderModule, CircleColliderModule, RigidbodyModule, ShapeModule, SoundSourceModule, SpriteModule, TransformModule
    
    include("engine/Camera/Camera.jl")
    using .CameraModule: Camera
    
    include("engine/Entity.jl") 
    using .EntityModule   
    export Entity

    include("engine/Scene.jl")
    using .SceneModule: Scene

    include("engine/SceneManagement/SceneManagement.jl")
    using .SceneManagement
    export SceneBuilderModule, SceneLoaderModule, SceneReaderModule, SceneWriterModule 
    
    include("MainLoop.jl") 
    using .MainLoopModule: MainLoop
    export MainLoop
end

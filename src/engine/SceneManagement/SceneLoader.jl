module SceneLoaderModule
    using ...JulGame
    using ..SceneBuilderModule

    export load_scene
    """
        load_scene(projectPath::String, sceneFileName::String)

    Load a scene from the specified project path and scene file name.

    # Arguments
    - `projectPath`: The path to the project.
    - `sceneFileName`: The name of the scene file.

    # Returns
    The initialized main scene.

    """
    function load_scene(projectPath::String, sceneFileName::String) 
        JulGame.BasePath = JulGame.BasePath == "" ? projectPath : JulGame.BasePath
        #println("Loading scene $sceneFileName from $projectPath")
        scene = Scene(sceneFileName, projectPath)
        return SceneBuilderModule.load_and_prepare_scene(nothing; this=scene)
    end
    
    export load_scene_from_editor
    """
        load_scene_from_editor(scenePath::String, renderer = nothing)

    Load a scene from the editor.

    # Arguments
    - `scenePath`: The path of the scene to load.
    - `renderer`: Optional renderer to use for the scene.

    # Returns
    - The initialized main scene.

    """
    function load_scene_from_editor(scenePath::String, renderer = nothing) 

        projectPath = get_project_path_from_full_scene_path(scenePath)
        sceneFileName = get_scene_file_name_from_full_scene_path(scenePath)

        JulGame.BasePath = JulGame.BasePath == "" ? projectPath : JulGame.BasePath
        if renderer !== nothing
            JulGame.Renderer::Ptr{SDL2.SDL_Renderer} = renderer
        end
        @debug ("Loading scene $sceneFileName from $projectPath")
        scene = Scene("$sceneFileName", "$projectPath")
        
        SceneBuilderModule.load_and_prepare_scene(JulGame.Main(Float64(1.0)); this=scene)

        return MAIN
    end

    export get_project_path_from_full_scene_path
    """
        get_project_path_from_full_scene_path(scenePath::String)

    Get the project path from the full scene path.

    # Arguments
    - `scenePath`: The full path of the scene.

    # Returns
    - `projectPath`: The project path extracted from the scene path.

    """
    function get_project_path_from_full_scene_path(scenePath::String)
        return dirname(dirname(scenePath))
    end

    export get_scene_file_name_from_full_scene_path
    """
        get_scene_file_name_from_full_scene_path(scenePath::String)

    Extracts the file name from the given full scene path.

    # Arguments
    - `scenePath`: The full path of the scene.

    # Returns
    - `sceneFileName`: The file name extracted from the scene path.
    """
    function get_scene_file_name_from_full_scene_path(scenePath::String)
        sceneFileName = split(scenePath, "/")[end]
        sceneFileName = split(sceneFileName, "\\")[end]

        return sceneFileName
    end
end

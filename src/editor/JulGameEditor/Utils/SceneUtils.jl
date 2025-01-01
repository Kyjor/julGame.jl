"""
    load_scene(scenePath::String)

Load a scene from the specified `scenePath` using the SceneLoaderModule.
Returns the loaded game.

# Arguments
- `scenePath`: The path to the scene file.

"""
function load_scene(scenePath::String)
    game = C_NULL
    try
        game = SceneLoaderModule.load_scene_from_editor(scenePath);
    catch e
        rethrow(e)
    end

    return game
end


"""
    get_all_scenes_from_folder(projectPath::String)

Searches through the specified `projectPath` and its subdirectories for a "scenes" folder. If found, it returns a list of all JSON files within that folder.

# Arguments
- `projectPath`: The path to the project directory.

# Returns
An array of file paths to the JSON files found in the "scenes" folder.
"""
function get_all_scenes_from_folder(projectPath::String)
    sceneFiles = []
    try
        # get all files in the scenes folder joinpath(projectPath, "scenes")
        if !isdir(joinpath(projectPath, "scenes"))
            @error "No scenes folder found in project directory: $projectPath"
        else
            for (root, dirs, files) in walkdir(joinpath(projectPath, "scenes"))
                for file in files
                    if occursin(r".json$", file)
                        push!(sceneFiles, joinpath(root, file))
                    end
                end
            end
        end
    catch e
        rethrow(e)
    end

    return sceneFiles
end

function get_all_scenes_from_base_folder(projectPath::String)
    sceneFiles = []
    try
        # search through projectpath and it's subdirectories for a scenes folder. If it exists, return all of the json files from it
        if !isdir(joinpath(projectPath, "scenes"))
            @error "No scenes folder found in project directory: $projectPath"
        else
            for (root, dirs, files) in walkdir(joinpath(projectPath, "scenes"))
                for file in files
                    if occursin(r".json$", file)
                        push!(sceneFiles, joinpath(root, file))
                    end
                end
            end
        end
    catch e
        rethrow(e)
    end

    return sceneFiles
end

"""
    choose_project_filepath()

Opens a dialog box to choose a config.julgame file.
"""
function choose_project_filepath()
    return dirname(pick_file(; filterlist="julgame"))
end

function choose_folder_with_dialog()
    dir = pick_folder()
    # println("open_dialog returned $dir")
    return dir
end

"""
    load_scene(scenePath::String, renderer)

Load a scene from the specified `scenePath` using the given `renderer`.

# Arguments
- `scenePath`: The path to the scene file.
- `renderer`: The renderer to use for loading the scene.

# Returns
The loaded main struct.
"""
function load_scene(scenePath::String, renderer)
    println("Loading scene from $scenePath")
    game = C_NULL
    try
        game = SceneLoaderModule.load_scene_from_editor(scenePath, renderer);
    catch e
        rethrow(e)
    end

    return game
end
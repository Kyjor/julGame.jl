module SceneWriterModule
    using ...JulGame
    using JSON3
    
    export serialize_entities
    """
        serialize_entities(entities::Array, uiElements::Array, projectPath, sceneName)

    Serialize the entities and text boxes into a JSON file.

    # Arguments
    - `entities::Array`: An array of entities to be serialized.
    - `uiElements::Array`: An array of text boxes to be serialized.
    - `projectPath`: The path to the project directory.
    - `sceneName`: The name of the scene.

    """
    function serialize_entities(entities::Array, uiElements::Array, camera, projectPath, sceneName)
        @debug String("Serializing entities")
        entitiesDict = []
        uiElementsDict = []
        
        count = 1
        for entity in entities
            push!(entitiesDict, Dict(
                "id" => string(entity.id), 
                "parent" =>  entity.parent != C_NULL ? entity.parent.id : C_NULL, 
                "isActive" => entity.isActive, 
                "name" => entity.name, 
                "persistentBetweenScenes" => entity.persistentBetweenScenes,
                "components" => serialize_entity_components([entity.animator, entity.collider, entity.circleCollider, entity.rigidbody, entity.shape, entity.soundSource, entity.sprite, entity.transform]), 
                "scripts" => serialize_entity_scripts(entity.scripts)))
            count += 1
        end

        count = 1
        for uiElement in uiElements
            if "$(typeof(uiElement))" == "JulGame.UI.ScreenButtonModule.ScreenButton"
                push!(uiElementsDict, Dict(
                    "id" => count, 
                    # TODO: "alpha" => uiElement.alpha, 
                    "buttonDownSpritePath" => normalize_path(uiElement.buttonDownSpritePath), 
                    "buttonUpSpritePath" => normalize_path(uiElement.buttonUpSpritePath), 
                    "fontPath" => normalize_path(uiElement.fontPath), 
                    # TODO: "fontSize" => uiElement.fontSize, 
                    "name" => uiElement.name,
                    "persistentBetweenScenes" => uiElement.persistentBetweenScenes,
                    "position" => Dict("x" => uiElement.position.x, "y" => uiElement.position.y),
                    "size" => Dict("x" => uiElement.size.x, "y" => uiElement.size.y),
                    "text" => uiElement.text,
                    "textOffset" => Dict("x" => uiElement.textOffset.x, "y" => uiElement.textOffset.y),
                    "type" => "ScreenButton"
                    ))
            else
                push!(uiElementsDict, Dict(
                    "id" => count, 
                    "alpha" => uiElement.alpha, 
                    "fontPath" => normalize_path(uiElement.fontPath), 
                    "fontSize" => uiElement.fontSize, 
                    "isActive" => uiElement.isActive,
                    "isCenteredX" => uiElement.isCenteredX,
                    "isCenteredY" => uiElement.isCenteredY,
                    "isWorldEntity" => uiElement.isWorldEntity,
                    "name" => uiElement.name,
                    "persistentBetweenScenes" => uiElement.persistentBetweenScenes,
                    "position" => Dict("x" => uiElement.position.x, "y" => uiElement.position.y),
                    "size" => Dict("x" => uiElement.size.x, "y" => uiElement.size.y),
                    "text" => uiElement.text,
                    "type" => "TextBox"
                    ))
            end
            count += 1
        end
        entitiesJson = Dict( 
            "Entities" => entitiesDict,
            "UIElements" => uiElementsDict,
            "Camera" => Dict("position" => Dict("x" => camera.position.x, "y" => camera.position.y), "backgroundColor" => Dict("r" => camera.backgroundColor[1], "g" => camera.backgroundColor[2], "b" => camera.backgroundColor[3], "a" => camera.backgroundColor[4]), "size" => Dict("x" => camera.size.x, "y" => camera.size.y), "offset" => Dict("x" => camera.offset.x, "y" => camera.offset.y), "startingCoordinates" => Dict("x" => camera.startingCoordinates.x, "y" => camera.startingCoordinates.y))
            )
        try
            name = split(sceneName,".")[1]
            @debug "writing to $(joinpath(projectPath, "scenes", "$(sceneName)"))"

            open(joinpath(projectPath, "scenes", "$(name)-saving"), "w") do io
                JSON3.pretty(io, entitiesJson)
            end
            if isfile(joinpath(projectPath, "scenes", "$(sceneName)")) 
                mv(joinpath(projectPath, "scenes", "$(sceneName)"), joinpath(projectPath, "scenes", "$(name)-backup.json"); force=true)
            end
            mv(joinpath(projectPath, "scenes", "$(name)-saving"), joinpath(projectPath, "scenes", "$(sceneName)"); force=true)
        catch e
            @error string(e)
			Base.show_backtrace(stdout, catch_backtrace())
            rethrow(e)
        end
    end

    export serialize_entity_components
    """
        serialize_entity_components(components)

    Serialize the given entity components into a dictionary representation.

    # Arguments
    - `components`: An array of entity components.

    # Returns
    - `componentsDict`: A dictionary representation of the serialized components.

    """
    function serialize_entity_components(components)

        componentsDict = []
        for component in components
            componentType = "$(typeof(component).name.wrapper)"
            componentType = String(split(componentType, '.')[length(split(componentType, '.'))])
            componentType = replace(componentType, "Internal" => "")
            if componentType == "Transform"
                serializedComponent = Dict("type" => componentType, "position" => Dict("x" => component.position.x, "y" => component.position.y), "scale" => Dict("x" => component.scale.x, "y" => component.scale.y))
                push!(componentsDict, serializedComponent)
            elseif componentType == "Animation"
                serializedComponent = Dict(
                    "type" => componentType, 
                    "frames" => component.frames, 
                    "animatedFPS" => component.animatedFPS            
                    )
                push!(componentsDict, serializedComponent)
            elseif componentType == "Animator"
                serializedAnimations = []
                for animation in component.animations
                    serializedAnimation = Dict(
                        "frames" => animation.frames, 
                        "animatedFPS" => animation.animatedFPS            
                        )
                push!(serializedAnimations, serializedAnimation)
                end
                push!(componentsDict, Dict("type" => componentType, "animations" => serializedAnimations))
            elseif componentType == "Collider"
                serializedComponent = Dict(
                    "type" => componentType, 
                    "size" => Dict("x" => component.size.x, "y" => component.size.y), 
                    "tag" => component.tag, 
                    "isTrigger" => component.isTrigger, 
                    "offset" => Dict("x" => component.offset.x, "y" => component.offset.y),
                    "enabled" => component.enabled,
                    "isPlatformerCollider" => component.isPlatformerCollider,
                    )
                push!(componentsDict, serializedComponent)
            elseif componentType == "Rigidbody"
                serializedComponent = Dict(
                    "type" => componentType, 
                    "mass" => component.mass, 
                    "drag" => component.drag,
                    "useGravity" => component.useGravity,
                    )
                push!(componentsDict, serializedComponent)
            elseif componentType == "Shape"
                serializedComponent = Dict(
                    "type" => componentType,
                    "color" => Dict("x" => component.color.x, "y" => component.color.y, "z" => component.color.z),
                    "isFilled" => component.isFilled, 
                    "isWorldEntity" => component.isWorldEntity, 
                    "layer" => component.layer, 
                    "offset" => Dict("x" => component.offset.x, "y" => component.offset.y),
                    "position" => Dict("x" => component.position.x, "y" => component.position.y),
                    "size" => Dict("x" => component.size.x, "y" => component.size.y),
                    "alpha" => component.alpha,
                    )
                push!(componentsDict, serializedComponent)
            elseif componentType == "SoundSource"
                serializedComponent = Dict(
                    "type" => componentType, 
                    "channel" => component.channel, 
                    "isMusic" => component.isMusic, 
                    "path" => normalize_path(component.path), 
                    "playOnStart" => component.playOnStart, 
                    "sound" => component.sound, 
                    "volume" => component.volume, 
                    )
                push!(componentsDict, serializedComponent)
            elseif componentType == "Sprite"
                serializedComponent = Dict(
                    "type" => componentType, 
                    "crop" => component.crop == C_NULL ? C_NULL : Dict("x" => component.crop.x, "y" => component.crop.y, "z" => component.crop.z, "t" => component.crop.t), 
                    "isFlipped" => component.isFlipped, 
                    "imagePath" => normalize_path(component.imagePath),
                    "layer" => component.layer,
                    "isWorldEntity" => component.isWorldEntity,
                    "pixelsPerUnit" => component.pixelsPerUnit,
                    "offset" => Dict("x" => component.offset.x, "y" => component.offset.y),
                    "position" => Dict("x" => component.position.x, "y" => component.position.y),
                    "rotation" => component.rotation,
                    "center" => Dict("x" => component.center.x, "y" => component.center.y),
                    "color" => Dict("x" => component.color[1], "y" => component.color[2], "z" => component.color[3], "t" => component.color[4]),
                    "size" => Dict("x" => component.size.x, "y" => component.size.y),
                )
                push!(componentsDict, serializedComponent)
            elseif "$componentType" != "Ptr"
                println("Component type $(componentType) not supported")
            end
        end
        return componentsDict
    end

    """
        normalize_path(path)

    Normalize the given path by replacing backslashes with forward slashes.

    # Arguments
    - `path`: The path to be normalized.

    # Returns
    The normalized path with forward slashes.

    """
    function normalize_path(path)
        return replace(joinpath(path), "\\" => "//")
    end

    export serialize_entity_scripts
    """
        serialize_entity_scripts(scripts)

    Serialize a list of scripts into a dictionary format.

    # Arguments
    - `scripts`: A list of scripts to be serialized.

    # Returns
    - `scriptsDict`: A dictionary containing the serialized scripts.

    """
    function serialize_entity_scripts(scripts)
        scriptsDict = []

        for script in scripts
            fields = Dict{String, Any}()
            scriptName = split("$(typeof(script))", ".")[end]
            for field in fieldnames(typeof(script))
                if field == :parent 
                    continue
                end
                val = nothing
                if isdefined(script, Symbol(field))
                    val = getfield(script, field)
                    if !isa(val, EditorExport)
                        continue
                    end
                    val = val.value
                else 
                    continue
                end
                fields["$(field)"] = val
            end

            scriptType = "$(typeof(script))"
            scriptName = split(scriptType, ".")[end]
            push!(scriptsDict, Dict("name" => scriptName, "fields" => fields))
        end

        return scriptsDict
    end

    function set_undefined_field(script, field)
        ftype = fieldtype(typeof(script), field)
        if ftype == String
            return ""
        elseif ftype <: Number
            return 0
        elseif ftype == Bool
            return false
        end
    end
end # module

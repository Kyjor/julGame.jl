using JSON3

function serializeEntities(entities::Array)
   
    entitiesDict = []

    count = 1
    for entity in entities
       push!(entitiesDict, Dict("id" => count, "isActive" => entity.isActive, "name" => entity.name, "components" => serializeEntityComponents(entity.components), "scripts" => serializeEntityScripts(entity.scripts)))
       count += 1
    end
    hello_world = Dict( "Entities" => entitiesDict)

open(joinpath(@__DIR__, "..", "scenes", "scene.json"), "w") do io
    JSON3.pretty(io, hello_world)
end
end

function serializeEntityComponents(components)

    componentsDict = []
    for component in components
    componentType = "$(typeof(component).name.wrapper)"
    componentType = String(split(componentType, '.')[length(split(componentType, '.'))])
    println(componentType)
    #Dict("b" => 1, "c" => 2)
    ASSETS = joinpath(@__DIR__, "..", "assets")
    if componentType == "Transform"
        serializedComponent = Dict("type" => componentType, "rotation" => component.rotation, "position" => Dict("x" => component.position.x, "y" => component.position.y), "scale" => Dict("x" => component.scale.x, "y" => component.scale.y))
        push!(componentsDict, serializedComponent)
    elseif componentType == "Animation"
    elseif componentType == "Animator"
    elseif componentType == "Collider"
    elseif componentType == "Rigidbody"
    elseif componentType == "SoundSource"
    elseif componentType == "Sprite"
        println(component)
        serializedComponent = Dict(
            "type" => componentType, 
            "crop" => component.crop == C_NULL ? C_NULL : Dict("x" => component.crop.x, "y" => component.crop.y, "w" => component.crop.w, "h" => component.crop.h), 
            "isFlipped" => component.isFlipped, 
            "imagePath" => component.imagePath
            )
        push!(componentsDict, serializedComponent)
    end
    end
    return componentsDict
end

function serializeEntityScripts(scripts)

    scriptsDict = []

    #Dict("b" => 1, "c" => 2)
    return scriptsDict
end
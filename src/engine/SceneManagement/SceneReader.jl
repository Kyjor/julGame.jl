module SceneReaderModule
    using JSON3
    using ...AnimatorModule
    using ...AnimationModule
    using ...CameraModule
    using ...ColliderModule
    using ...CircleColliderModule
    using ...EntityModule
    using ...Math
    using ...RigidbodyModule
    using ...ShapeModule
    using ...SoundSourceModule
    using ...SpriteModule
    using ...UI.TextBoxModule
    using ...UI.ScreenButtonModule
    using ...TransformModule
    using ...JulGame


    function scriptObj(name::String, fields::Array)
        () -> (name; fields)
    end

    export deserialize_scene
    function deserialize_scene(filePath)
        try
            json = nothing
            if haskey(JulGame.SCENE_CACHE, basename(filePath))
                json = JulGame.SCENE_CACHE[basename(filePath)]
                @debug("using cached scene")
            else 
                entitiesJson = read(filePath, String)
                json = JSON3.read(entitiesJson)
                @debug("using scene from scene file")
            end

            entities = []
            uiElements = []
            res = []
            childParentDict = Dict()
    
            for entity in json.Entities
                components = []
    
                for component in entity.components
                    push!(components, deserialize_component(component))
                end
                
                if haskey(entity, "parent") && entity.parent != ""
                    childParentDict[string(entity.id)] = entity.parent
                end
                newEntity = Entity(get(entity, "name", "New entity"), string(entity.id))
                newEntity.isActive = get(entity, "isActive", true)
                newEntity.scripts = get(entity, "scripts", [])
                newEntity.persistentBetweenScenes = get(entity, "persistentBetweenScenes", false)

                for component in components
                    if typeof(component) == Animator
                        JulGame.add_animator(newEntity, component::Animator)
                        continue
                    elseif typeof(component) == Collider
                        JulGame.add_collider(newEntity, component::Collider)
                        continue
                    elseif typeof(component) == CircleCollider
                        JulGame.add_circle_collider(newEntity, component::CircleCollider)
                        continue
                    elseif typeof(component) == Rigidbody
                        JulGame.add_rigidbody(newEntity, component::Rigidbody)
                        continue
                    elseif typeof(component) == Shape
                        JulGame.add_shape(newEntity, component::Shape)
                        continue
                    elseif typeof(component) == SoundSource
                        JulGame.add_sound_source(newEntity, component::SoundSource)
                        continue
                    elseif typeof(component) == Sprite
                        JulGame.add_sprite(newEntity, false, component::Sprite)
                        continue
                    elseif typeof(component) == Transform 
                        newEntity.transform = component::Transform 
                        continue 
                    end
                end
                
                push!(entities, newEntity)
            end

            for entity in entities
                if haskey(childParentDict, string(entity.id))
                    parentId = childParentDict[string(entity.id)]
                    for e in entities
                        if string(e.id) == string(parentId)
                            entity.parent = e
                        end
                    end
                end
            end
            uiElements = deserialize_ui_elements(json.UIElements)
            camera = Camera(Vector2(500,500), Vector2f(),Vector2f(), C_NULL)
            if haskey(json, "Camera")
                camera = Camera(Vector2(json.Camera.size.x, json.Camera.size.y), Vector2f(json.Camera.position.x, json.Camera.position.y), Vector2f(json.Camera.offset.x, json.Camera.offset.y), C_NULL)
                camera.backgroundColor = (json.Camera.backgroundColor.r, json.Camera.backgroundColor.g, json.Camera.backgroundColor.b, json.Camera.backgroundColor.a)
            end
             
            push!(res, entities)
            push!(res, uiElements)
            push!(res, camera)
            return res
        catch e 
            @error string(e)
			Base.show_backtrace(stdout, catch_backtrace())
        end
    end

    function deserialize_ui_elements(jsonUIElements)
        res = []

        for uiElement in jsonUIElements
            try
                newUIElement = nothing
                if uiElement.type == "TextBox"
                    newUIElement = TextBox(uiElement.name, uiElement.fontPath, uiElement.fontSize, Vector2(uiElement.position.x, uiElement.position.y), get(uiElement, "text", " "), uiElement.isCenteredX, uiElement.isCenteredY)    
                    newUIElement.isWorldEntity = uiElement.isWorldEntity    
                    newUIElement.anchorOffset = !haskey(uiElement, "anchorOffset") ? Vector2(0,0) : Vector2(uiElement.anchorOffset.x, uiElement.anchorOffset.y)
                    newUIElement.id = string(get(uiElement, "id", newUIElement.id))
                    isActive::Bool = !haskey(uiElement, "isActive") ? true : uiElement.isActive
                    newUIElement.isActive = isActive    
                else
                    newUIElement = ScreenButton(uiElement.name, uiElement.buttonUpSpritePath, uiElement.buttonDownSpritePath, Vector2(uiElement.size.x, uiElement.size.y), Vector2(uiElement.position.x, uiElement.position.y), uiElement.fontPath, uiElement.text, Vector2(uiElement.textOffset.x, uiElement.textOffset.y))
                end
                newUIElement.persistentBetweenScenes = get(uiElement, "persistentBetweenScenes", false)
                push!(res, newUIElement)
            catch e 
                @error string(e)
				Base.show_backtrace(stdout, catch_backtrace())
            end
        end

        return res
    end

    export deserialize_component
    function deserialize_component(component)
        try
            if component.type == "Transform"
                newComponent = Transform(Vector2f(component.position.x, component.position.y), Vector2f(component.scale.x, component.scale.y))
            elseif component.type == "Animator"
                newAnimations = Animation[]
                for animation in component.animations
                newAnimationFrames = Vector{Vector4}()
                for animationFrame in animation.frames
                    push!(newAnimationFrames, Vector4(animationFrame.x, animationFrame.y, animationFrame.z, animationFrame.t))
                end
                push!(newAnimations, Animation(newAnimationFrames, convert(Int32, animation.animatedFPS)))
                end
                newComponent = Animator(newAnimations)
            elseif component.type == "Collider"
                isTrigger::Bool = !haskey(component, "isTrigger") ? false : component.isTrigger
                enabled::Bool = !haskey(component, "enabled") ? true : component.enabled
                isPlatformerCollider::Bool = !haskey(component, "isPlatformerCollider") ? false : component.isPlatformerCollider
                offset::Vector2f = !haskey(component, "offset") ? Vector2f(0,0) : Vector2f(component.offset.x, component.offset.y)
                newComponent = Collider(enabled::Bool, isPlatformerCollider, isTrigger, offset,  Vector2f(component.size.x, component.size.y), component.tag::String)
            elseif component.type == "CircleCollider"
                newComponent = CircleCollider(convert(Float64, component.diameter), component.enabled, component.isTrigger, Vector2f(component.offset.x, component.offset.y), component.tag)
            elseif component.type == "Rigidbody"
                newComponent = Rigidbody(; mass = convert(Float64, component.mass), useGravity = !haskey(component, "useGravity") ? true : component.useGravity)
            elseif component.type == "SoundSource"
                newComponent = SoundSource(Int32(component.channel), component.isMusic, component.path, get(component, "playOnStart", false), Int32(component.volume))
            elseif component.type == "Sprite"
                color = !haskey(component, "color") || isempty(component.color) ? (255,255,255,255) : (get(component.color, "x", 255), get(component.color, "y", 255), get(component.color, "z", 255), get(component.color, "t", 255))
                crop = !haskey(component, "crop") || isempty(component.crop) ? Vector4(0,0,0,0) : Vector4(component.crop.x, component.crop.y, component.crop.z, component.crop.t)
                isWorldEntity = !haskey(component, "isWorldEntity") ? true : component.isWorldEntity
                layer = !haskey(component, "layer") ? 0 : component.layer
                offset = !haskey(component, "offset") ? Vector2f() : Vector2f(component.offset.x, component.offset.y)
                position = !haskey(component, "position") ? Vector2f() : Vector2f(component.position.x, component.position.y)
                rotation = !haskey(component, "rotation") ? 0.0 : convert(Float64, component.rotation)
                pixelsPerUnit = !haskey(component, "pixelsPerUnit") ? -1 : component.pixelsPerUnit
                center = !haskey(component, "center") ? Vector2f(0.5,0.5) : Vector2f(component.center.x, component.center.y)
                newComponent = Sprite(color::Tuple{Int64, Int64, Int64, Int64}, crop::Union{Ptr{Nothing}, Math.Vector4}, component.isFlipped::Bool, component.imagePath::String, isWorldEntity::Bool, Int32(layer), offset::Vector2f, position::Vector2f, rotation::Float64, Int32(pixelsPerUnit), center::Vector2f)
            elseif component.type == "Shape"
                color = !haskey(component, "color") || isempty(component.color) ? Vector3(255,255,255) : Vector3(component.color.x, component.color.y, component.color.z)
                layer = !haskey(component, "layer") ? Int32(0) : Int32(component.layer)
                size = !haskey(component, "size") || isempty(component.size) ? Vector2f(1,1) : Vector2f(component.size.x, component.size.y)
                isFilled = !haskey(component, "isFilled") ? true : component.isFilled
                isWorldEntity = !haskey(component, "isWorldEntity") ? true : component.isWorldEntity
                offset = !haskey(component, "offset") ? Vector2f() : Vector2f(component.offset.x, component.offset.y)
                position = !haskey(component, "position") ? Vector2f() : Vector2f(component.position.x, component.position.y)
                alpha = !haskey(component, "alpha") ? Int32(255) : Int32(component.alpha)
                newComponent = Shape(color::Vector3, isFilled::Bool, isWorldEntity::Bool, layer::Int32, offset::Vector2f, position::Vector2f, size::Vector2f, alpha::Int32)
            end
            
            return newComponent
        catch e
            @error string(e)
			Base.show_backtrace(stdout, catch_backtrace())
        end
    end
end

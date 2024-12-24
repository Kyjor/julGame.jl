module SceneModule
    using ..JulGame
    
    export Scene
    mutable struct Scene
        camera::Union{Nothing, JulGame.CameraModule.Camera}
        colliders::Vector{Any}
        entities::Vector{Any}
        rigidbodies::Vector{Any}
        uiElements::Vector{Any}

        function Scene()
            this = new()

            this.camera = nothing
            this.colliders = []
            this.entities = []
            this.rigidbodies = []
            this.uiElements = []

            return this
        end
    end

    function get_entity_by_name(this::Scene, name)
        for entity in this.entities
            if entity.name == name
                return entity
            end
        end

        @warn "No entity with name $name found"
        return nothing
    end

    function get_entities_by_name(this::Scene, name)
        entities = []
        for entity in this.entities
            if entity.name == name
                push!(entities, entity)
            end
        end

        if length(entities) == 0
            @warn "No entity with name $name found"
        end
        return entities
    end

    function get_entity_by_id(this::Scene, id)
        for entity in this.entities
            if entity.id == id
                return entity
            end
        end

        @warn "No entity with id $id found"
        return nothing
    end

    function get_ui_element_by_name(this::Scene, name)
        for entity in this.uiElements
            if entity.name == name
                return entity
            end
        end

        @warn "No entity with name $name found"
        return nothing
    end

end


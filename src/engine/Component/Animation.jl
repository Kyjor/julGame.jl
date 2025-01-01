module AnimationModule 
    using ..Component.JulGame
    import ..Component
    export Animation
    mutable struct Animation
        animatedFPS::Int32
        frames::Vector{Math.Vector4}

        function Animation(frames::Vector{Math.Vector4}, animatedFPS::Int32)
            this = new()
            
            this.animatedFPS = animatedFPS
            this.frames = frames

            return this
        end
    end

    function Component.update_array_value(this::Animation, value, field, index::Int32)
        fieldToUpdate = getfield(this, field)
        if Component.get_type(this, value) == "_Vector4"
            fieldToUpdate[index] = Math.Vector4(value.x, value.y, value.z, value.t)
        end
    end
    
    function Component.append_array(this::Animation)
        push!(this.frames, Math.Vector4(0,0,0,0))
    end
    
    function Component.get_type(this::Animation, item)
        componentFieldType = "$(typeof(item).name.wrapper)"
        return String(split(componentFieldType, '.')[length(split(componentFieldType, '.'))])
    end
end

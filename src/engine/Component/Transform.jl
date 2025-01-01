module TransformModule
    using ..Component.JulGame 
    import ..Component
    
    export Transform
    mutable struct Transform
        position::Math.Vector2f
        scale::Math.Vector2f
            
        function Transform(position::Math.Vector2f = Math.Vector2f(0.0, 0.0), scale::Math.Vector2f = Math.Vector2f(1.0, 1.0))
            this = new()
            
            this.position = position
            this.scale = scale
            
            return this
        end   
    end     

    function Component.set_position(this::Transform, position::Math.Vector2f)
        this.position = position
    end
end

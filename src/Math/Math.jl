module Math
    include("Lerp.jl")
    include("Vector2.jl")
    include("Vector3.jl")
    include("Vector4.jl")

    export normalize
    function normalize(vector::Vector2f)
        magnitude = sqrt(vector.x^2 + vector.y^2)
        return Vector2f(vector.x / magnitude, vector.y / magnitude)
    end

    export distance
    function distance(a::Vector2f, b::Vector2f)
        return sqrt((b.x - a.x)^2 + (b.y - a.y)^2)
    end
    
    export Lerp
    export SmoothLerp
    export Vector2
    export Vector2f
    export Vector3
    export Vector3f
    export Vector4
    export Vector4f
end

module Component
    using ..JulGame
    include("ComponentFunctions.jl")
    include("Transform.jl")
    include("Sprite.jl")
    include("Animation.jl")
    include("Animator.jl")
    include("Collider.jl")
    include("CircleCollider.jl")
    include("Rigidbody.jl")
    include("Shape.jl")
    include("SoundSource.jl")
    
    export AnimationModule
    export AnimatorModule
    export ColliderModule
    export CircleColliderModule
    export RigidbodyModule
    export ShapeModule
    export SoundSourceModule
    export SpriteModule
    export TransformModule
end

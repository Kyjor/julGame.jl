module AnimatorModule
    using ..Component.AnimationModule
    using ..Component.JulGame
    using ..Component.JulGame.Math
    using ..Component.SpriteModule
    import ..Component
    export Animator
    struct Animator
        animations::Vector{Animation}
    end

    export InternalAnimator
    mutable struct InternalAnimator
        animations::Vector{Animation}
        currentAnimation::Animation
        lastFrame::Int32
        lastUpdate::UInt64
        parent::Any
        playOnce::Bool
        sprite::Union{InternalSprite, Ptr{Nothing}}

        function InternalAnimator(parent::Any, animations::Vector{Animation} = Animation[])
            this = new()
            
            this.animations = animations
            this.currentAnimation = length(this.animations) > 0 ? this.animations[1] : C_NULL
            this.lastFrame = 1
            this.lastUpdate = SDL2.SDL_GetTicks()
            this.parent = parent
            this.sprite = C_NULL
            this.playOnce = false

            return this
        end
    end

    function Component.update(this::InternalAnimator, currentRenderTime, deltaTime)
        if this.currentAnimation.animatedFPS < 1 || (this.playOnce && this.lastFrame == length(this.currentAnimation.frames)) || this.sprite == C_NULL || this.sprite === nothing
            return
        end
        deltaTime = (currentRenderTime - this.lastUpdate) / 1000.0
        framesToUpdate = floor(deltaTime / (1.0 / this.currentAnimation.animatedFPS))
        if framesToUpdate > 0
            this.lastFrame = this.lastFrame + framesToUpdate
            this.lastUpdate = currentRenderTime
        end
        this.sprite.crop = this.currentAnimation.frames[this.lastFrame > length(this.currentAnimation.frames) ? (1; this.lastFrame = 1) : this.lastFrame]
    end

    function Component.append_array(this::InternalAnimator)
        push!(this.animations, Animation([Math.Vector4(0,0,0,0)], Int32(60)))
    end
    
    function Component.play_animation_once(this::InternalAnimator, animationIndex::Int)
        if animationIndex > 0 && animationIndex <= length(this.animations)
            this.currentAnimation = this.animations[animationIndex]
            this.playOnce = true
            this.lastFrame = 1

            return
        end

        @warn "Animation index out of bounds"
    end
    
    
    """
    force_frame_update(this::InternalAnimator, frameIndex::Int32)
    
    Updates the sprite crop of the animator to the specified frame index.
    
    # Arguments
    - `this::InternalAnimator`: The animator object.
    - `frameIndex::Int32`: The index of the frame to update the sprite crop to.
    
    # Example
    ```
    animator = Animator([Animation([Math.Vector4(0,0,0,0)], 60)])
    force_frame_update(animator, 1)
    ```
    """
    function force_frame_update(this::InternalAnimator, frameIndex)
        this.sprite.crop = this.currentAnimation.frames[frameIndex]
    end
    export force_frame_update    
end

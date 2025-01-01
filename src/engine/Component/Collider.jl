module ColliderModule
    include("../../utils/Enums.jl")
    using ..Component.JulGame
    import ..Component 

    export Collider
    struct Collider
        enabled::Bool
        isPlatformerCollider::Bool
        isTrigger::Bool
        offset::Math.Vector2f
        size::Math.Vector2f
        tag::String
    end


    export InternalCollider
    mutable struct InternalCollider
        collisionEvents::Vector{Function}
        currentCollisions::Vector{InternalCollider}
        currentRests::Vector{InternalCollider}
        enabled::Bool
        isTrigger::Bool
        isPlatformerCollider::Bool
        offset::Math.Vector2f
        parent::Any
        size::Math.Vector2f
        tag::String
        
        function InternalCollider(parent::Any, size::Math.Vector2f = Math.Vector2f(1,1), offset::Math.Vector2f = Math.Vector2f(), tag::String="Default", isTrigger::Bool=false, isPlatformerCollider::Bool = false, enabled::Bool=true)
            this = new()

            this.collisionEvents = []
            this.currentCollisions = []
            this.currentRests = []
            this.enabled = enabled
            this.isTrigger = isTrigger
            this.isPlatformerCollider = isPlatformerCollider
            this.offset = offset
            this.parent = parent
            this.size = size
            this.tag = tag

            if this.size.x < 0 || this.size.y < 0
                println("Collider size cannot be negative")
                return nothing
            end

            return this
        end
    end

    function Component.get_size(this::InternalCollider)
        return this.size
    end

    function Component.set_size(this::InternalCollider, size::Math.Vector2f)
        this.size = size
    end

    function Component.get_offset(this::InternalCollider)
        return this.offset
    end

    function Component.set_offset(this::InternalCollider, offset::Math.Vector2f)
        this.offset = offset
    end

    function Component.get_tag(this::InternalCollider)
        return this.tag
    end

    function Component.check_collisions(this::InternalCollider)
        colliders = MAIN.scene.colliders
        #Only check the player against other colliders
        colliderSkipCount = 0
        colliderCheckedCount = 0
        i = 0
        onGround = false
        if !this.parent.isActive || !this.enabled
            return
        end

        for collider in colliders
            i += 1
            
            if !collider.parent.isActive || !collider.enabled
                continue
            end
            
            if this != collider
                # check if other collider is within range of this collider, if it isn't then skip it
                if collider.parent.transform.position.x > this.parent.transform.position.x + Component.get_size(this).x || collider.parent.transform.position.x + Component.get_size(collider).x < this.parent.transform.position.x && MAIN.optimizeSpriteRendering
                    colliderSkipCount += 1
                    continue
                end

                colliderCheckedCount += 1
                transform = this.parent.transform
                collision = check_collision(this, collider)
                    transform = this.parent.transform
                    if collision[1] == Top::CollisionDirection
                        push!(this.currentCollisions, collider)
                        for eventToCall in this.collisionEvents
                            Base.invokelatest(eventToCall,(collider=collider, direction=collision[1]))
                        end
                        #Begin to overlap, correct position
                        if !collider.isTrigger && !this.isTrigger
                                this.parent.transform.position = Math.Vector2f(transform.position.x, transform.position.y + collision[2])
                        end
                    end
                    if collision[1] == Left::CollisionDirection
                        push!(this.currentCollisions, collider)
                        for eventToCall in this.collisionEvents
                            Base.invokelatest(eventToCall,(collider=collider, direction=collision[1]))
                        end
                        
                        if !collider.isTrigger && !this.isTrigger
                                #Begin to overlap, correct position
                                this.parent.transform.position = Math.Vector2f(transform.position.x + collision[2], transform.position.y)
                        end
                    end
                    if collision[1] == Right::CollisionDirection
                        push!(this.currentCollisions, collider)
                        for eventToCall in this.collisionEvents
                            Base.invokelatest(eventToCall,(collider=collider, direction=collision[1]))
                        end
                        #Begin to overlap, correct position
                        if !collider.isTrigger && !this.isTrigger
                                this.parent.transform.position = Math.Vector2f(transform.position.x - collision[2], transform.position.y)
                        end
                    end
                    if collision[1] == Bottom::CollisionDirection
                        push!(this.currentCollisions, collider)
                        for eventToCall in this.collisionEvents
                            Base.invokelatest(eventToCall,(collider=collider, direction=collision[1]))
                        end
                        #Begin to overlap, correct position
                        
                        if !collider.isTrigger && !this.isTrigger
                                this.parent.transform.position = Math.Vector2f(transform.position.x, transform.position.y - collision[2])
                                if this.parent.rigidbody.velocity.y >= 0
                                        this.parent.rigidbody.grounded = true
                                end
                        end
                    end
                    if collision[1] == Below::ColliderLocation
                        push!(this.currentCollisions, collider)
                        for eventToCall in this.collisionEvents
                            Base.invokelatest(eventToCall,(collider=collider, direction=collision[1]))
                        end
                    end
                    if collision[3] && this.parent.rigidbody.grounded
                        onGround = true
                    end
                end

            end

            this.parent.rigidbody.grounded = onGround

        return length(this.currentCollisions) > 0
    end

    function Component.add_collision_event(this::InternalCollider, event)
        push!(this.collisionEvents, event)
    end        

    function check_collision(colliderA::InternalCollider, colliderB::InternalCollider)
        posA = (colliderA.parent.transform.position + colliderA.offset) * SCALE_UNITS
        posB = (colliderB.parent.transform.position + colliderB.offset) * SCALE_UNITS
        colliderAXSize = colliderA.parent.transform.scale.x * colliderA.size.x * SCALE_UNITS
        colliderAYSize = colliderA.parent.transform.scale.y * colliderA.size.y * SCALE_UNITS
        colliderBXSize = colliderB.parent.transform.scale.x * colliderB.size.x * SCALE_UNITS
        colliderBYSize = colliderB.parent.transform.scale.y * colliderB.size.y * SCALE_UNITS

        a = SDL2.SDL_Rect(round(posA.x), round(posA.y), round(colliderAXSize), round(colliderAYSize))
        b = SDL2.SDL_Rect(round(posB.x), round(posB.y), round(colliderBXSize), round(colliderBYSize))

        rgba = (r = Ref(UInt8(0)), g = Ref(UInt8(0)), b = Ref(UInt8(0)), a = Ref(UInt8(255)))
        # SDL2.SDL_GetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r, rgba.g, rgba.b, rgba.a)
        # SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, 0, 255, 255, SDL2.SDL_ALPHA_OPAQUE)
        
        result = Ref(SDL2.SDL_Rect(0,0,0,0))
        isIntersection = SDL2.SDL_IntersectRect(Ref(a), Ref(b), result)

        camera = MAIN.scene.camera
        cameraDiff = camera !== nothing ? 
        Math.Vector2((camera.position.x + camera.offset.x) * SCALE_UNITS, (camera.position.y + camera.offset.y) * SCALE_UNITS) : 
        Math.Vector2(0,0)
        isLineIntersectionL = SDL2.SDL_IntersectRectAndLine(Ref(b), Ref(Int32(round(posA.x))), Ref(Int32(round(posA.y + 32))), Ref(Int32(round(posA.x))), Ref(Int32(round(posA.y + 80))))
        #SDL2.SDL_RenderDrawLine(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, round(posA.x - cameraDiff.x), round(posA.y + 32 - cameraDiff.y), round(posA.x - cameraDiff.x), round(posA.y + 80 - cameraDiff.y))

        isLineIntersectionR = SDL2.SDL_IntersectRectAndLine(Ref(b), Ref(Int32(round(posA.x + colliderAXSize))), Ref(Int32(round(posA.y + 32))), Ref(Int32(round(posA.x + colliderAXSize))), Ref(Int32(round(posA.y + 80))))
        #SDL2.SDL_RenderDrawLine(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, round(posA.x - cameraDiff.x + colliderAXSize), round(posA.y + 32 - cameraDiff.y), round(posA.x - cameraDiff.x + colliderAXSize), round(posA.y + 80 - cameraDiff.y))
        if isLineIntersectionL == SDL2.SDL_TRUE
            isLineIntersectionL = true
        else
            isLineIntersectionL = false
        end

        if isLineIntersectionR == SDL2.SDL_TRUE
            isLineIntersectionR = true
        else
            isLineIntersectionR = false
        end

        if isIntersection == SDL2.SDL_TRUE
            a1 = SDL2.SDL_FRect(posA.x, posA.y, colliderAXSize, colliderAYSize)
            b1 = SDL2.SDL_FRect(posB.x, posB.y, colliderBXSize, colliderBYSize)
            # SDL2.SDL_RenderDrawRectF(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, Ref(a1))
            # SDL2.SDL_RenderDrawRectF(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, Ref(b1))
            # SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r[], rgba.g[], rgba.b[], rgba.a[]);

            # println("col a (me): $(a)")
            # println("col b (other): $(b)")
            # println("result: $(result)")
            # println("$(colliderA.parent.name) is colliding with $(colliderB.parent.name)")

            depthHorizontal = result[].w
            depthVertical = result[].h
            horizontalCollisionDir = None::CollisionDirection
            verticalCollisionDir = None::CollisionDirection
            if result[].x == b.x 
                @debug "colliding from left at depth $(depthHorizontal)"
                horizontalCollisionDir = Left::CollisionDirection
            elseif result[].x == a.x
                @debug "colliding from right at depth $(depthHorizontal)"
                horizontalCollisionDir = Right::CollisionDirection
            end
            if result[].y == b.y
                @debug "colliding from top at depth $(depthVertical)"
                verticalCollisionDir = Bottom::CollisionDirection
            elseif result[].y == a.y
                @debug "colliding from botrom at depth $(depthVertical)" 
                verticalCollisionDir = Top::CollisionDirection
            end
            
            if min(depthHorizontal, depthVertical) == depthHorizontal
                return (horizontalCollisionDir, -depthHorizontal/SCALE_UNITS, isLineIntersectionL || isLineIntersectionR)
            else
                return (verticalCollisionDir, depthVertical/SCALE_UNITS, isLineIntersectionL || isLineIntersectionR)
            end
        end

        #SDL2.SDL_SetRenderDrawColor(JulGame.Renderer::Ptr{SDL2.SDL_Renderer}, rgba.r[], rgba.g[], rgba.b[], rgba.a[]);

        return (None::CollisionDirection, 0.0, isLineIntersectionL || isLineIntersectionR)
    end
   end

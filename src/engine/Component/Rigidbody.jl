module RigidbodyModule
    using ..Component.JulGame
    import ..Component
    export Rigidbody
    struct Rigidbody
        mass::Float64
        useGravity::Bool

        function Rigidbody(;mass::Float64 = 1.0, useGravity::Bool = true)
            return new(mass, useGravity)
        end
    end

    export InternalRigidbody
    mutable struct InternalRigidbody 
        acceleration::Math.Vector2f
        drag::Float64
        grounded::Bool
        mass::Float64
        offset::Math.Vector2f
        parent::Any
        useGravity::Bool
        velocity::Math.Vector2f

        function InternalRigidbody(parent::Any; mass::Float64 = 1.0, useGravity::Bool = true)
            this = new()
            
            this.acceleration = Math.Vector2f()
            this.drag = 0.1
            this.grounded = false
            this.mass = mass
            this.offset = Math.Vector2f()
            this.parent = parent
            this.useGravity = useGravity
            this.velocity = Math.Vector2f(0.0, 0.0)
    
            return this
        end
    end

    function Component.update(this::InternalRigidbody, dt)
        dt = clamp(dt, 0, .5)
        velocityMultiplier = Math.Vector2f(1.0, 1.0)
        transform = this.parent.transform
        currentPosition = transform.position
        
        newPosition = transform.position + this.velocity*dt + this.acceleration*(dt*dt*0.5)
        if this.grounded
            newPosition = Math.Vector2f(newPosition.x, currentPosition.y)
            velocityMultiplier = Math.Vector2f(1.0, 0.0)
        end
        newAcceleration = Component.apply_forces(this)
        newVelocity = this.velocity + (this.acceleration+newAcceleration)*(dt*0.5)

        Component.set_position(transform, newPosition)
        set_velocity(this, newVelocity * velocityMultiplier)
        this.acceleration = newAcceleration

        if this.parent.collider != C_NULL
            Component.check_collisions(this.parent.collider)
        end
    end

    function Component.apply_forces(this::InternalRigidbody)
        gravityAcceleration = Math.Vector2f(0.0, this.useGravity ? GRAVITY : 0.0)
        dragForce = 0.5 * this.drag * (this.velocity * this.velocity)
        dragAcceleration = dragForce / this.mass
        return gravityAcceleration - dragAcceleration
    end

    function Component.get_velocity(this::InternalRigidbody)
        return this.velocity
    end

    """
    add_velocity(this::Rigidbody, velocity::Math.Vector2f)

    Add the given velocity to the Rigidbody's current velocity. If the y-component of the velocity is positive, set the `grounded` flag to false.
    
    # Arguments
    - `this::Rigidbody`: The Rigidbody component to set the velocity for.
    - `velocity::Math.Vector2f`: The velocity to set.
    """
    function add_velocity(this::InternalRigidbody, velocity::Math.Vector2f)
        this.velocity = this.velocity + velocity
        if(velocity.y < 0)
            this.grounded = false
            if this.parent.collider != C_NULL
                this.parent.collider.currentRests = []
            end
        end
    end
    export add_velocity
    
    """
    set_velocity(this::Rigidbody, velocity::Math.Vector2f)

    Set the velocity of the Rigidbody component.

    # Arguments
    - `this::Rigidbody`: The Rigidbody component to set the velocity for.
    - `velocity::Vector2f`: The velocity to set.
    """
    function set_velocity(this::InternalRigidbody, velocity::Math.Vector2f)
        this.velocity = velocity
        if(velocity.y < 0)
            #this.grounded = false
        end
    end
    export set_velocity
end

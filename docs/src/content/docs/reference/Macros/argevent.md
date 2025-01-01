---
title: argevent (Macro)
description: Allows for execution of a function at a later time, with parameters. 
---


### Example
```
    function JulGame.initialize(this::PlayerMovement)
        collisionEvent = JulGame.Macros.@argevent (collisionInfo) handle_collisions(this, collisionInfo) # evt can be passed from the caller
        JulGame.Component.add_collision_event(this.parent.collider, collisionEvent)
    end

    function handle_collisions(this::PlayerMovement, collisionInfo)
        otherCollider = collisionInfo.collider

        if otherCollider.tag == "Coin"
            println("grabbed coin")
        end
    end

    function call_collision_event(collisionEvent)
        collisionInfo = (collider=exampleCollider, direction=exampleDirection)
        event(collisionInfo) # this calls handle_collisions, since we registered this event in the initialize function
    end
```
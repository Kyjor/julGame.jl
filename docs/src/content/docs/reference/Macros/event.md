---
title: event (Macro)
description: Allows for execution of a function at a later time. 
---


### Example
```
    event = JulGame.Macros.@event begin
        println("Test")
        println("Other)
    end

    if eventNeedsToBeCalled
        example_function(event) # this can be passed through to another function, where it can be executed later.
    end


    ...


    function example_function(event)
        event()
    end
```
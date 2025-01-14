#todo: separate mouse, keyboard, gamepad, and window into their own files
module InputModule
    using ..JulGame
    using ..JulGame.Math
    
    export Input
    mutable struct Input
        buttonsPressedDown::Vector{String}
        buttonsHeldDown::Vector{String}
        buttonsReleased::Vector{String}
        debug::Bool
        editorCallback::Union{Function, Nothing}
        isWindowFocused::Bool
        main
        mouseButtonsPressedDown::Vector
        mouseButtonsHeldDown::Vector
        mouseButtonsReleased::Vector
        mousePosition
        joystick
        scanCodeStrings::Vector{String}
        scanCodes::Vector
        quit::Bool
        
        #Gamepad
        jaxis
        xDir
        yDir
        numAxes
        numButtons
        numHats
        button

        # Cursor bank 
        cursorBank::Dict{String, Ptr{SDL2.SDL_SystemCursor}} # Key is the name of the cursor, value is the SDL2 cursor

        function Input()
            this = new()

            this.buttonsPressedDown = []
            this.buttonsHeldDown = []
            this.buttonsReleased = []
            this.debug = false
            this.editorCallback = nothing
            this.isWindowFocused = true
            this.mouseButtonsPressedDown = []
            this.mouseButtonsHeldDown = []
            this.mouseButtonsReleased = []
            this.mousePosition = Math.Vector2(0,0)
            this.quit = false
            this.scanCodes = []
            this.scanCodeStrings = String[]
            for m in instances(SDL2.SDL_Scancode)
                codeString = "$(m)"
                code::SDL2.SDL_Scancode = m
                if codeString == "SDL_NUM_SCANCODES"
                    continue
                end
                push!(this.scanCodes, [code, SubString(codeString, 14, length(codeString))])
            end

            SDL2.SDL_Init(UInt64(SDL2.SDL_INIT_JOYSTICK))
            if SDL2.SDL_NumJoysticks() < 1
                println("Warning: No joysticks connected!")
                this.numAxes = 0
                this.numButtons = 0
                this.numHats = 0
            else
                # Load joystick
                this.joystick = SDL2.SDL_JoystickOpen(0)
                if this.joystick == C_NULL
                    println("Warning: Unable to open game controller! SDL Error: ", unsafe_string(SDL2.SDL_GetError()))
                end
                name = SDL2.SDL_JoystickName(this.joystick)
                this.numAxes = SDL2.SDL_JoystickNumAxes(this.joystick)
                this.numButtons = SDL2.SDL_JoystickNumButtons(this.joystick)
                this.numHats = SDL2.SDL_JoystickNumHats(this.joystick)

                println("Now reading from joystick '$(unsafe_string(name))' with:")
                println("$(this.numAxes) axes")
                println("$(this.numButtons) buttons")
                println("$(this.numHats) hats")

            end
            this.jaxis = C_NULL
            this.xDir = 0
            this.yDir = 0
            this.button = 0

            this.cursorBank = Dict{String, SDL2.SDL_SystemCursor}() 
            create_cursor_bank(this)

            return this
        end
    end

    function poll_input(this::Input)
        this.buttonsPressedDown = []
        didMouseEventOccur = false
        event_ref = Ref{SDL2.SDL_Event}()
        while Bool(SDL2.SDL_PollEvent(event_ref))
            evt = event_ref[]
            handle_window_events(this, evt)
            if this.editorCallback !== nothing
                this.editorCallback(evt)
            end
            if evt.type == SDL2.SDL_MOUSEMOTION || evt.type == SDL2.SDL_MOUSEBUTTONDOWN || evt.type == SDL2.SDL_MOUSEBUTTONUP
                didMouseEventOccur = true
                if MAIN.scene.uiElements !== nothing
                    x,y = Int32[1], Int32[1]
                    SDL2.SDL_GetMouseState(pointer(x), pointer(y))
                    
                    this.mousePosition = Math.Vector2(x[1], y[1])
                    if MAIN.scene.camera === nothing
                        @warn ("Camera is not set in the main scene.")
                        continue
                    end

                    insideAnyButton = false
                    for uiElement in MAIN.scene.uiElements
                        # Check position of button to see which we are interacting with
                        eventWasInsideThisButton = true
                        if x[1] < uiElement.position.x + MAIN.scene.camera.startingCoordinates.x
                            eventWasInsideThisButton = false
                        elseif x[1] > MAIN.scene.camera.startingCoordinates.x + uiElement.position.x + uiElement.size.x * MAIN.zoom
                            eventWasInsideThisButton = false
                        elseif y[1] < uiElement.position.y + MAIN.scene.camera.startingCoordinates.y
                            eventWasInsideThisButton = false
                        elseif y[1] > MAIN.scene.camera.startingCoordinates.y + uiElement.position.y + uiElement.size.y * MAIN.zoom
                            eventWasInsideThisButton = false
                        end

                        if !eventWasInsideThisButton
                            uiElement.isHovered = false
                            continue
                        end
                        insideAnyButton = true

                        if split("$(typeof(uiElement))", ".")[end] == "ScreenButton"
                            SDL2.SDL_SetCursor(this.cursorBank["crosshair"])
                        end
                        
                        JulGame.UI.handle_event(uiElement, evt, x[1], y[1])
                    end

                    if !insideAnyButton
                        SDL2.SDL_SetCursor(this.cursorBank["arrow"])
                    end
                end

                handle_mouse_event(this, evt)
            end 

            #if evt.type == SDL2.SDL_JOYAXISMOTION
                if evt.jaxis.which == 0
                    this.jaxis = evt.jaxis
                end
                for i in 0:this.numAxes-1
                    axis = SDL2.SDL_JoystickGetAxis(this.joystick, i)
                    if i < 0
                        println("Axis $i: $(SDL2.SDL_JoystickGetAxis(this.joystick, i))")
                    end
                    JOYSTICK_DEAD_ZONE = 8000

                    if i == 0
                        if axis < -JOYSTICK_DEAD_ZONE
                            this.xDir = -1
                        # Right of dead zone
                        elseif axis > JOYSTICK_DEAD_ZONE
                            this.xDir = 1
                        else
                            this.xDir = 0
                        end
                    elseif i == 1
                        if axis < -JOYSTICK_DEAD_ZONE
                            this.yDir = -1
                        # Right of dead zone
                        elseif axis > JOYSTICK_DEAD_ZONE
                            this.yDir = 1
                        else
                            this.yDir = 0
                        end
                    end

                end
                # println("x:$(this.xDir), y:$(this.yDir)")
                for i in 0:this.numButtons-1
                    button = SDL2.SDL_JoystickGetButton(this.joystick, i)

                    if button != 0
                        println("Button $i: $(button)")
                    end
                    if i == 0 && button == 1
                        this.button = 1
                    elseif i == 0
                        this.button = 0
                    end
                end
                
                for i in 0:this.numHats-1

                    hat = SDL2.SDL_JoystickGetHat(this.joystick, i)
                    if hat != 0
                        println("Hat $i: $(hat)")
                    end
                end
                
            #end

            if evt.type == SDL2.SDL_QUIT
                this.quit = true
                return -1
            end
            if evt.type == SDL2.SDL_KEYDOWN && evt.key.keysym.scancode == SDL2.SDL_SCANCODE_F3
                this.debug = !this.debug
            end
        end
        if !didMouseEventOccur
            this.mouseButtonsPressedDown = []
            this.mouseButtonsReleased = []
        end
        keyboardState = unsafe_wrap(Array, SDL2.SDL_GetKeyboardState(C_NULL), 300; own = false)
        handle_key_event(this, keyboardState)
    end

    function check_scan_code(this::Input, keyboardState, keyState, scanCodes)
        for scanCode in scanCodes
            try
                if keyboardState[Int32(scanCode) + 1] == keyState
                    return true
                end
            catch
                println("Error checking scan code $(scanCode) at index $(Int32(scanCode) + 1)")
            end
        end
        return false
    end    

    function handle_window_events(this::Input, event)
        if event.type != SDL2.SDL_WINDOWEVENT
            return
        end
        windowEvent = event.window.event
        
        # Uncomment to debug window events
        if windowEvent == SDL2.SDL_WINDOWEVENT_SHOWN
            @debug(string("Window $(event.window.windowID) shown"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_HIDDEN
            @debug(string("Window $(event.window.windowID) hidden"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_EXPOSED
            @debug(string("Window $(event.window.windowID) exposed"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_MOVED
            @debug(string("Window $(event.window.windowID) moved to $(event.window.data1),$(event.window.data2)"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_RESIZED # todo: update zoom and viewport size here
            if !JulGame.IS_EDITOR
                @debug(string("Window $(event.window.windowID) resized to $(event.window.data1)x$(event.window.data2)"))
                JulGame.MainLoop.update_viewport(MAIN, event.window.data1, event.window.data2)
            end
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_SIZE_CHANGED
            @debug(string("Window $(event.window.windowID) size changed to $(event.window.data1)x$(event.window.data2)"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_MINIMIZED
            @debug(string("Window $(event.window.windowID) minimized"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_MAXIMIZED
            @debug(string("Window $(event.window.windowID) maximized"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_RESTORED
            @debug(string("Window $(event.window.windowID) restored"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_ENTER
            @debug(string("Mouse entered window $(event.window.windowID)"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_LEAVE
            @debug(string("Mouse left window $(event.window.windowID)"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_FOCUS_GAINED
            @debug(string("Window $(event.window.windowID) gained keyboard focus"))
            this.isWindowFocused = true
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_FOCUS_LOST
            @debug(string("Window $(event.window.windowID) lost keyboard focus"))
            this.isWindowFocused = false

        elseif windowEvent == SDL2.SDL_WINDOWEVENT_CLOSE
            @debug(string("Window $(event.window.windowID) closed"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_TAKE_FOCUS
            @debug(string("Window $(event.window.windowID) is offered a focus"))
        elseif windowEvent == SDL2.SDL_WINDOWEVENT_HIT_TEST
            @debug(string("Window $(event.window.windowID) has a special hit test"))
        else
            @debug(string("Window $(event.window.windowID) got unknown event $(event.window.event)"))   
        end    
    end

    function handle_key_event(this::Input, keyboardState)
        buttonsPressedDown = this.buttonsPressedDown

        count = 1
        for scanCode in this.scanCodes
            button = scanCode[2]
            if check_scan_code(this, keyboardState, 1, [scanCode[1]]) && !(button in this.buttonsHeldDown)
                push!(buttonsPressedDown, button)
                push!(this.buttonsHeldDown, button)
            elseif check_scan_code(this, keyboardState, 0, [scanCode[1]])
                if button in this.buttonsHeldDown
                    deleteat!(this.buttonsHeldDown, findfirst(x -> x == button, this.buttonsHeldDown))
                end
            end
        end
        this.buttonsPressedDown = buttonsPressedDown
    end

    function handle_mouse_event(this::Input, event)
        mouseButtons = []
        mouseButtonsUp = []
        mouseButton = C_NULL
        mouseButtonUp = C_NULL

        if event.button.button == SDL2.SDL_BUTTON_LEFT || event.button.button == SDL2.SDL_BUTTON_MIDDLE || event.button.button == SDL2.SDL_BUTTON_RIGHT
            if !(mouseButton in mouseButtons)
                if event.type == SDL2.SDL_MOUSEBUTTONDOWN
                    mouseButton = event.button.button
                    push!(mouseButtons, mouseButton)
                elseif event.type == SDL2.SDL_MOUSEBUTTONUP
                    mouseButtonUp = event.button.button
                    push!(mouseButtonsUp, mouseButtonUp)
                end
            end
        end

        this.mouseButtonsPressedDown = mouseButtons
        for mouseButton in mouseButtons
            if !(mouseButton in this.mouseButtonsHeldDown)
                push!(this.mouseButtonsHeldDown, mouseButton)
            end
        end
        for mouseButton in mouseButtonsUp
            if mouseButton in this.mouseButtonsHeldDown
                deleteat!(this.mouseButtonsHeldDown, findfirst(x -> x == mouseButton, this.mouseButtonsHeldDown))
            end
        end
        this.mouseButtonsReleased = mouseButtonsUp
    end

    function get_button_held_down(this::Input, button::String)
        if uppercase(button) in this.buttonsHeldDown
            return true
        end
        return false
    end

    function get_button_pressed(this::Input, button::String)
        if uppercase(button) in this.buttonsPressedDown
            return true
        end
        return false
    end

    function get_button_released(this::Input, button::String)
        if uppercase(button) in this.buttonsReleased
            return true
        end
        return false
    end

    function get_mouse_button(this::Input, button::Any)
        if button in this.mouseButtonsHeldDown
            return true
        end
        return false
    end

    function get_mouse_button_pressed(this::Input, button::Any)
        if button in this.mouseButtonsPressedDown
            return true
        end
        return false
    end

    function get_mouse_button_released(this::Input, button::Any)
        if button in this.mouseButtonsReleased
            return true
        end
        return false
    end

    function create_cursor_bank(this::Input)
        this.cursorBank["arrow"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_ARROW)
        this.cursorBank["ibeam"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_IBEAM)
        this.cursorBank["wait"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_WAIT)
        this.cursorBank["crosshair"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_CROSSHAIR)
        this.cursorBank["waitarrow"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_WAITARROW)
        this.cursorBank["sizeall"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_SIZEALL)
        this.cursorBank["sizenesw"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_SIZENESW)
        this.cursorBank["sizenwse"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_SIZENWSE)
        this.cursorBank["sizewe"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_SIZEWE)
        this.cursorBank["sizens"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_SIZENS)
        this.cursorBank["no"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_NO)
        this.cursorBank["hand"] = SDL2.SDL_CreateSystemCursor(SDL2.SDL_SYSTEM_CURSOR_HAND)
    end
end
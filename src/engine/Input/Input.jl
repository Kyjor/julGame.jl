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
        didMouseEventOccur::Bool
        editorCallback::Union{Function, Nothing}
        isWindowFocused::Bool
        main
        mouseButtonsPressedDown::Vector
        mouseButtonsHeldDown::Vector
        mouseButtonsReleased::Vector
        mousePosition
        mousePositionWorld
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

        # Testing
        isTestButtonClicked::Bool

        function Input()
            this = new()

            this.buttonsPressedDown = []
            this.buttonsHeldDown = []
            this.buttonsReleased = []
            this.debug = false
            this.didMouseEventOccur = false
            this.editorCallback = nothing
            this.isWindowFocused = true
            this.mouseButtonsPressedDown = []
            this.mouseButtonsHeldDown = []
            this.mouseButtonsReleased = []
            this.mousePosition = Math.Vector2(0,0)
            this.mousePositionWorld = Math.Vector2(0,0)
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
                @debug("Warning: No joysticks connected!")
                this.numAxes = 0
                this.numButtons = 0
                this.numHats = 0
            else
                # Load joystick
                this.joystick = SDL2.SDL_JoystickOpen(0)
                if this.joystick == C_NULL
                    @debug("Warning: Unable to open game controller! SDL Error: ", unsafe_string(SDL2.SDL_GetError()))
                end
                name = SDL2.SDL_JoystickName(this.joystick)
                this.numAxes = SDL2.SDL_JoystickNumAxes(this.joystick)
                this.numButtons = SDL2.SDL_JoystickNumButtons(this.joystick)
                this.numHats = SDL2.SDL_JoystickNumHats(this.joystick)

                @debug("Now reading from joystick '$(unsafe_string(name))' with:")
                @debug("$(this.numAxes) axes")
                @debug("$(this.numButtons) buttons")
                @debug("$(this.numHats) hats")

            end
            this.jaxis = C_NULL
            this.xDir = 0
            this.yDir = 0
            this.button = 0

            this.cursorBank = Dict{String, SDL2.SDL_SystemCursor}() 
            create_cursor_bank(this)

            this.isTestButtonClicked = false

            return this
        end
    end

    function poll_input(this::Input)
        this.buttonsPressedDown = []
        this.didMouseEventOccur = false
        event_ref = Ref{SDL2.SDL_Event}()
       

        while Bool(SDL2.SDL_PollEvent(event_ref))
            evt = event_ref[]
            handle_window_events(this, evt)

            # @info "polling input"
            x,y = Int32[1], Int32[1]
            SDL2.SDL_GetMouseState(pointer(x), pointer(y))
            this.mousePosition = Math.Vector2(x[1], y[1])
            #@info "new mouse pos: $(this.mousePosition)"

            if this.editorCallback !== nothing
                this.editorCallback(evt)
            end

            if evt.type == SDL2.SDL_MOUSEMOTION || evt.type == SDL2.SDL_MOUSEBUTTONDOWN || evt.type == SDL2.SDL_MOUSEBUTTONUP
                this.didMouseEventOccur = true
                if evt.type == SDL2.SDL_MOUSEBUTTONDOWN
                    println("Mouse button down at $(this.mousePosition)")
                end

                if MAIN.scene.uiElements !== nothing
                    if MAIN.scene.camera === nothing
                        @warn ("Camera is not set in the main scene.")
                        continue
                    end

                    insideAnyElement = false
                    for uiElement in MAIN.scene.uiElements
                        if !uiElement.isActive
                            continue
                        end
                        # Check position of button to see which we are interacting with
                        eventWasInsideThisButton = true
                        if this.mousePosition.x < uiElement.position.x + MAIN.scene.camera.startingCoordinates.x
                            eventWasInsideThisButton = false
                        elseif this.mousePosition.x > MAIN.scene.camera.startingCoordinates.x + uiElement.position.x + uiElement.size.x * MAIN.zoom
                            eventWasInsideThisButton = false
                        elseif this.mousePosition.y < uiElement.position.y + MAIN.scene.camera.startingCoordinates.y
                            eventWasInsideThisButton = false
                        elseif this.mousePosition.y > MAIN.scene.camera.startingCoordinates.y + uiElement.position.y + uiElement.size.y * MAIN.zoom
                            eventWasInsideThisButton = false
                        end

                        if !eventWasInsideThisButton
                            uiElement.isHovered = false
                            continue
                        end
                        insideAnyElement = true

                        if split("$(typeof(uiElement))", ".")[end] == "ScreenButton"
                            SDL2.SDL_SetCursor(this.cursorBank["crosshair"])
                        end
                        
                        JulGame.UI.handle_event(uiElement, evt, this.mousePosition.x, this.mousePosition.y)
                    end

                    if !insideAnyElement
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
                        @debug("Axis $i: $(SDL2.SDL_JoystickGetAxis(this.joystick, i))")
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
                # @debug("x:$(this.xDir), y:$(this.yDir)")
                for i in 0:this.numButtons-1
                    button = SDL2.SDL_JoystickGetButton(this.joystick, i)

                    if button != 0
                        @debug("Button $i: $(button)")
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
                        @debug("Hat $i: $(hat)")
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

            keyboardState = unsafe_wrap(Array, SDL2.SDL_GetKeyboardState(C_NULL), 300; own = false)
            handle_key_event(this, keyboardState)
        end
        if this.isTestButtonClicked
            lift_mouse_after_simulated_click(this)
        end
        if !this.didMouseEventOccur
            this.mouseButtonsPressedDown = []
            this.mouseButtonsReleased = []
        end
    end

    function check_scan_code(this::Input, keyboardState, keyState, scanCodes)
        for scanCode in scanCodes
            try
                if keyboardState[Int32(scanCode) + 1] == keyState
                    return true
                end
            catch
                @error("Error checking scan code $(scanCode) at index $(Int32(scanCode) + 1)")
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
                JulGame.MainLoopModule.update_viewport(MAIN, event.window.data1, event.window.data2)
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
        if event.button.button == SDL2.SDL_BUTTON_LEFT || event.button.button == SDL2.SDL_BUTTON_MIDDLE || event.button.button == SDL2.SDL_BUTTON_RIGHT
            button = event.button.button
            if event.type == SDL2.SDL_MOUSEBUTTONDOWN && !(button in this.mouseButtonsPressedDown)
                push!(this.mouseButtonsPressedDown, button)
            elseif event.type == SDL2.SDL_MOUSEBUTTONUP && !(button in this.mouseButtonsReleased)
                push!(this.mouseButtonsReleased, button)
            end            
        end

        for button in this.mouseButtonsPressedDown
            if !(button in this.mouseButtonsHeldDown)
                push!(this.mouseButtonsHeldDown, button)
            end
        end

        for button in this.mouseButtonsReleased
            if button in this.mouseButtonsHeldDown
                deleteat!(this.mouseButtonsHeldDown, findfirst(x -> x == button, this.mouseButtonsHeldDown))
            end
        end
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

    # Initialize an SDL_Event instance
    function init_sdl_event()::Ptr{SDL2.SDL_Event}
        # Create a vector of UInt8
        data = UInt8[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] 
        
         # Convert the vector to a tuple of size 56
        ntuple_data = Tuple(data)

        # Allocate memory for the SDL_Event struct itself
        ptr_event = Ptr{SDL2.SDL_Event}(Libc.malloc(sizeof(SDL2.SDL_Event)))  # Allocate memory for SDL_Event struct

        # Now, initialize the data field of the struct using unsafe_store!
        unsafe_store!(ptr_event, SDL2.SDL_Event(ntuple_data))

        # Return the pointer to the struct
        return ptr_event
    end

    function init_mouse_button_event()::Ptr{SDL2.SDL_MouseButtonEvent}
        # Allocate memory for SDL_MouseButtonEvent struct
        ptr_event = Ptr{SDL2.SDL_MouseButtonEvent}(Libc.malloc(sizeof(SDL2.SDL_MouseButtonEvent)))
    
        # Initialize the fields directly
        unsafe_store!(ptr_event, SDL2.SDL_MouseButtonEvent(
            0x0,             # type (just an example, you'll set this later)
            0x0,             # timestamp
            0x0,             # windowID
            0x0,             # which (mouse)
            0x0,             # button (mouse button)
            0x0,             # state (pressed/released)
            0x0,             # clicks
            0x0,             # padding
            0x0,             # x (position)
            0x0              # y (position)
        ))
    
        # Return the pointer to the struct
        return ptr_event
    end    

    function simulate_mouse_click(this::Input, window::Ptr{SDL2.SDL_Window}, x::Int32, y::Int32)
        # Move the mouse to the specified position
        SDL2.SDL_WarpMouseInWindow(window, x, y)
        
        # Create a mouse button down event
        mouse_event::Ptr{SDL2.SDL_Event} = init_sdl_event()
        mouse_event.type = SDL2.SDL_MOUSEBUTTONDOWN

        mouse_event.button = SDL2.SDL_MouseButtonEvent(
            SDL2.SDL_MOUSEBUTTONDOWN,  # Type of event
            0,                        # Timestamp (0 for automatic)
            0,                        # Window ID (0 for default window)
            0,                        # Which mouse (0 for the primary mouse)
            SDL2.SDL_BUTTON_LEFT,      # Button being pressed
            SDL2.SDL_PRESSED,          # Button state (pressed)
            1,                         # Clicks (1 for single click)
            0,                         # Padding (unused, set to 0)
            x,                         # X position
            y                          # Y position
        ) 
        SDL2.SDL_PushEvent(mouse_event)
        this.isTestButtonClicked = true
    end

    function lift_mouse_after_simulated_click(this)
        mouse_event::Ptr{SDL2.SDL_Event} = init_sdl_event()
        mouse_event.type = SDL2.SDL_MOUSEBUTTONUP
        mouse_event.button = SDL2.SDL_MouseButtonEvent(
            SDL2.SDL_MOUSEBUTTONUP,  # Type of event
            0,                        # Timestamp (0 for automatic)
            0,                        # Window ID (0 for default window)
            0,                        # Which mouse (0 for the primary mouse)
            SDL2.SDL_BUTTON_LEFT,      # Button being pressed
            SDL2.SDL_RELEASED,          # Button state (pressed)
            1,                         # Clicks (1 for single click)
            0,                         # Padding (unused, set to 0)
            0,                         # X position # todo: get actual mouse position
            0                          # Y position # todo: get actual mouse position
        ) 
        SDL2.SDL_PushEvent(mouse_event)
        this.isTestButtonClicked = false
    end
end # module InputModule
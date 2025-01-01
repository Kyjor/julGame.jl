# Reference: https://github.com/ocornut/imgui/tree/master/examples/example_sdl2_sdlrenderer2

module Editor
    using CImGui
    using CImGui.CSyntax
    using CImGui.CSyntax.CStatic
    using CImGui: ImVec2, ImVec4, IM_COL32, ImS32, ImU32, ImS64, ImU64
    using CImGui.CImGui
    using Dates
    using JulGame: Component, MainLoop, Math, SceneLoaderModule, SDL2, UI
    using NativeFileDialog
    
    global sdlVersion = "2.0.0"
    global sdlRenderer = C_NULL
    global const BackendPlatformUserData = Ref{Any}(C_NULL)

    include(joinpath("..","..","utils","Macros.jl"))

    include.(filter(contains(r".jl$"), readdir(joinpath(@__DIR__, "ImGuiSDLBackend"); join=true)))
    include.(filter(contains(r".jl$"), readdir(joinpath(@__DIR__, "Components"); join=true)))
    include.(filter(contains(r".jl$"), readdir(joinpath(@__DIR__, "Utils"); join=true)))
    include.(filter(contains(r".jl$"), readdir(joinpath(@__DIR__, "Windows"); join=true)))

    function run(is_test_mode::Bool=false)
        isPackageCompiled = ccall(:jl_generating_output, Cint, ()) == 1
        windowTitle = "JulGame Editor v0.1.0"

        info = init_sdl_and_imgui(windowTitle)
        window, renderer, ctx, io, clear_color = info[1], info[2], info[3], info[4], info[5]
        startingSize = ImVec2(1920, 1080)
        sceneTexture = SDL2.SDL_CreateTexture(renderer, SDL2.SDL_PIXELFORMAT_BGRA8888, SDL2.SDL_TEXTUREACCESS_TARGET, startingSize.x, startingSize.y)# SDL2.SDL_SetRenderTarget(renderer, sceneTexture)
        gameTexture = SDL2.SDL_CreateTexture(renderer, SDL2.SDL_PIXELFORMAT_BGRA8888, SDL2.SDL_TEXTUREACCESS_TARGET, 200, 200)# SDL2.SDL_SetRenderTarget(renderer, sceneTexture)
        sceneTextureSize = ImVec2(startingSize.x, startingSize.y)
        gameTextureSize = ImVec2(200, 200)

        style_imGui()
        showDemoWindow = false
        ##############################
        # Project variables
        currentSceneMain = nothing
        currentSceneName = ""
        currentScenePath = ""
        currentSelectedProjectPath = Ref("")
        gameInfo = []
        ##############################
        # Hierarchy variables
        filteredEntities = Entity[]
        hierarchyFilterText = Ref("")
        hierarchyEntitySelections = []
        hierarchyUISelections = Bool[]
        ##############################
        scenesLoadedFromFolder = Ref(String[])
        latest_exceptions = Ref([])

        sceneWindowPos = ImVec2(0, 0)
        sceneWindowSize = ImVec2(startingSize.x, startingSize.y)
        gameWindowSize = ImVec2(startingSize.x, startingSize.y)
        testFrameCount = 0
        testFrameLimit = 100
        quit = false

        scrolling = Ref(ImVec2(0.0, 0.0))
        zoom_level = Ref(1.0)
        playMode = false

        animation_window_dict = Ref(Dict())
        animator_preview_dict = Ref(Dict())

        save_file_timer = 0

        duplicationMode = false

        # Engine Timing
        startTime = Ref(UInt64(0))
        lastPhysicsTime = Ref(UInt64(SDL2.SDL_GetTicks()))

        # Dialogs
        currentDialog::Base.RefValue{String} = Ref("")
        newSceneText = Ref("")
        newProjectText = Ref("")
        newScriptText = Ref("")

        panOffset = Math.Vector2(0, 0)
        camera = JulGame.CameraModule.Camera(Vector2(500,500), Vector2f(),Vector2f(), C_NULL)
        gameCamera = JulGame.CameraModule.Camera(Vector2(500,500), Vector2f(),Vector2f(), C_NULL)
        confirmation_modal = ConfirmationModal("Start/Stop Game"; message="Are you sure you want to start/stop the game? Any unsaved progress will be lost.", confirmText="Yes", cancelText="No", open=false, type="Warning")
        cameraWindow = CameraWindow(true, gameCamera)
        currentProjectConfig = (Width=Ref(Int32(800)), Height=Ref(Int32(600)), FrameRate=Ref(Int32(30)), WindowName=Ref("Game"), PixelsPerUnit=Ref(Int32(16)), AutoScaleZoom=Ref(Bool(0)), IsResizable=Ref(Bool(0)), Fullscreen=Ref(Bool(0)))

        try
            while !quit                    
                try
                    if currentSceneMain === nothing
                        quit = poll_events()
                    else 
                        if JulGame.InputModule.get_button_held_down(currentSceneMain.input, "LEFT")
                            panOffset = Math.Vector2(panOffset.x + 1, panOffset.y)
                        elseif JulGame.InputModule.get_button_held_down(currentSceneMain.input, "RIGHT")
                            panOffset = Math.Vector2(panOffset.x - 1, panOffset.y)
                        elseif JulGame.InputModule.get_button_held_down(currentSceneMain.input, "UP")
                            panOffset = Math.Vector2(panOffset.x, panOffset.y + 1)
                        elseif JulGame.InputModule.get_button_held_down(currentSceneMain.input, "DOWN")
                            panOffset = Math.Vector2(panOffset.x, panOffset.y - 1)
                        end
                    end   
                    start_frame()
                    CImGui.igDockSpaceOverViewport(C_NULL, C_NULL, CImGui.ImGuiDockNodeFlags_PassthruCentralNode, C_NULL) # Creating the "dockspace" that covers the whole window. This allows the child windows to automatically resize.
                    
                    ################################## RENDER HERE
                    
                    ################################# MAIN MENU BAR
                    events = Dict{String, Function}()
                    if currentSceneMain !== nothing
                        events["Save"] = save_scene_event(currentSceneMain.scene.entities, currentSceneMain.scene.uiElements, gameCamera, currentSelectedProjectPath[], String(currentSceneName))
                    end
                    events["New-project"] = create_project_event(currentDialog)
                    events["Select-project"] = select_project_event(currentSceneMain, scenesLoadedFromFolder, currentDialog)
                    events["Reset-camera"] = reset_camera_event(currentSceneMain)
                    events["Regenerate-ids"] = regenerate_ids_event(currentSceneMain)
                    events["New-Scene"] = @event begin
                        currentDialog[] = "New Scene"
                    end
                    events["Play-Mode"] = @event begin confirmation_modal.open = true; end
                    
                    show_main_menu_bar(events, currentSceneMain)
                    ################################# END MAIN MENU BAR
                    if !isPackageCompiled
                        #@c CImGui.ShowDemoWindow(Ref{Bool}(showDemoWindow)) # Uncomment this line to show the demo window and see available widgets
                    end

                    try 
                        @cstatic begin
                            #region Scene List
                            CImGui.Begin("Scene List") 
                            show_help_marker("This is where we will display our scenes. Scenes are where the gameplay happens.")
                            # txt = currentSceneMain === nothing ? "Load Scene" : "Change Scene"
                            # CImGui.Text(txt)

                            # Usage:
                            
                            
                            for scene in scenesLoadedFromFolder[]
                                name = SceneLoaderModule.get_scene_file_name_from_full_scene_path(scene)
                                
                                if CImGui.Button("$(SubString(split(split(scene, "scenes")[2], ".")[1], 2))")
                                    currentSceneName = name
                                    currentScenePath = scene
                                    if currentSceneMain === nothing
                                        JulGame.IS_EDITOR = true
                                        JulGame.PIXELS_PER_UNIT = 16
                                        currentDialog[] = "Open Scene"
                                        currentSelectedProjectPath[] = SceneLoaderModule.get_project_path_from_full_scene_path(scene) 
                                        currentProjectConfig = load_project_config(currentSelectedProjectPath)
                                    else
                                        currentDialog[] = "Open Scene"
                                    end
                                end
                                CImGui.NewLine()
                            end

                            CImGui.End()
                        end
                    catch e
                        handle_editor_exceptions("Scene list:", latest_exceptions, e, is_test_mode)
                    end
                    
                    try 
                        if !playMode && currentSelectedProjectPath[] != "" && unsafe_string(SDL2.SDL_GetWindowTitle(window)) != "$(windowTitle) - $(currentSelectedProjectPath[])"
                            newWindowTitle = "$(windowTitle) - $(currentSelectedProjectPath[])"
                            SDL2.SDL_SetWindowTitle(window, newWindowTitle)
                        end
                    catch e
                        handle_editor_exceptions("Window renaming:", latest_exceptions, e, is_test_mode)
                    end
                    
                    try
                        if currentDialog[] == "Open Scene"
                            #println("Opening scene: $(currentDialog[][2])")
                            if confirmation_dialog(currentDialog) == "ok" && currentSceneName != ""
                                if currentSceneMain === nothing
                                    currentSceneMain = load_scene(currentScenePath, renderer)
                                    gameCamera = currentSceneMain.scene.camera
                                    cameraWindow.camera = gameCamera
                                else
                                    JulGame.change_scene(String(currentSceneName))
                                    gameCamera = currentSceneMain.scene.camera
                                    cameraWindow.camera = gameCamera
                                end
                            end
                        elseif currentDialog[] == "New Scene"
                            newSceneName = new_scene_dialog(currentDialog, newSceneText)
                            if newSceneName != ""
                                currentSceneName = newSceneName
                                currentScenePath = joinpath(currentSelectedProjectPath[], "scenes", "$(newSceneName).json")
                                touch(currentScenePath)
                                file = open(currentScenePath, "w")
                                    println(file, sceneJsonContents)
                                close(file)
                                JulGame.change_scene("$(String(currentSceneName)).json")
                                scenesLoadedFromFolder[] = get_all_scenes_from_folder(currentSelectedProjectPath[])
                            end
                        elseif currentDialog[] == "Select Project"
                            selectedProjectPath = select_project_dialog(currentDialog, scenesLoadedFromFolder)
                            if selectedProjectPath != ""
                                currentSceneMain = nothing
                            end
                        elseif currentDialog[] == "New Project"
                            selectedProjectPath = create_project_dialog(currentDialog, scenesLoadedFromFolder, currentSelectedProjectPath, newProjectText)
                            if selectedProjectPath != ""
                                println("Selected project path: $(selectedProjectPath)")
                            end
                        end
                    catch e
                        handle_editor_exceptions("Dialogs handler:", latest_exceptions, e, is_test_mode)
                    end
                    uiSelected = false
                
                    try
                        if sceneWindowSize !== nothing && sceneTextureSize !== nothing && sceneWindowSize.x != sceneTextureSize.x || sceneWindowSize.y != sceneTextureSize.y
                            SDL2.SDL_DestroyTexture(sceneTexture)
                            sceneTexture = SDL2.SDL_CreateTexture(renderer, SDL2.SDL_PIXELFORMAT_BGRA8888, SDL2.SDL_TEXTUREACCESS_TARGET, sceneWindowSize.x, sceneWindowSize.y)
                            sceneTextureSize = ImVec2(sceneWindowSize.x, sceneWindowSize.y)
                        end
                    catch e
                        handle_editor_exceptions("Scene window resizing:", latest_exceptions, e, is_test_mode)
                    end
                    
                    try
                        if gameCamera !== nothing && gameTextureSize !== nothing && gameCamera.size.x != gameTextureSize.x || gameCamera.size.y != gameTextureSize.y
                            SDL2.SDL_DestroyTexture(gameTexture)
                            gameTexture = SDL2.SDL_CreateTexture(renderer, SDL2.SDL_PIXELFORMAT_BGRA8888, SDL2.SDL_TEXTUREACCESS_TARGET, gameCamera.size.x, gameCamera.size.y)
                            gameTextureSize = ImVec2(gameCamera.size.x, gameCamera.size.y)
                        end
                    catch e
                        handle_editor_exceptions("Game window resizing:", latest_exceptions, e, is_test_mode)
                    end
                    
                    try
                        prevSceneWindowSize = sceneWindowSize
                        
                        wasPlaying = playMode
                        if show_modal(confirmation_modal)
                            playMode = !playMode
                            if playMode
                                startTime[] = SDL2.SDL_GetTicks()
                                 
                                # Animate the text in the window title
                                SDL2.SDL_SetWindowTitle(window, "PLAYING $(windowTitle) - $(currentSelectedProjectPath[])")
                            end
                        end
                        
                        sceneWindowSize = show_scene_window(currentSceneMain, sceneTexture, scrolling, zoom_level, duplicationMode, camera)
                        if playMode != wasPlaying && currentSceneMain !== nothing
                            if playMode
                                JulGame.MainLoop.start_game_in_editor(currentSceneMain, currentSelectedProjectPath[])
                                currentSceneMain.scene.camera = gameCamera 
                            elseif !playMode
                                JulGame.MainLoop.stop_game_in_editor(currentSceneMain)
                                JulGame.change_scene(String(currentSceneName))
                            end
                        end
                        
                        prevGameWindowSize = gameWindowSize
                        gameWindowSize = show_game_window(gameTexture)

                        if gameWindowSize === nothing
                            gameWindowSize = prevGameWindowSize
                        end
                        if sceneWindowSize === nothing
                            sceneWindowSize = prevSceneWindowSize
                        end
                    catch e
                        handle_editor_exceptions("Show modal/scene window:", latest_exceptions, e, is_test_mode)
                    end
                    
                    try
                        #region Hierarchy
                        CImGui.Begin("Hierarchy") 
                        
                        show_help_marker("This is where we will display a list of entities and textboxes for the scene")
                        currentSceneMain === nothing && CImGui.Text("No scene loaded.")
                        if currentSceneMain !== nothing && CImGui.TreeNode("Entities")
                            # remove other entities from hierarchyEntitySelections if currentSceneMain.selectedEntity is not in hierarchyEntitySelections
                            # this happens if we select an entity in the scene view
                            if currentSceneMain.selectedEntity !== nothing && any(entity -> (entity[1] == currentSceneMain.selectedEntity && entity[2] == false), hierarchyEntitySelections)
                                for index in eachindex(hierarchyEntitySelections)
                                    hierarchyEntitySelections[index] = (hierarchyEntitySelections[index][1], currentSceneMain.selectedEntity == hierarchyEntitySelections[index][1])
                                end
                            end 
                             
                            CImGui.SameLine()
                            show_help_marker("This is a list of all entities in the scene. Click on an entity to select it.")
                            CImGui.SameLine()
                            if CImGui.BeginMenu("Add") # TODO: Move to own file as a function
                                CImGui.MenuItem("Add", C_NULL, false, false)
                                if CImGui.BeginMenu("New")
                                    if CImGui.MenuItem("Entity")
                                        JulGame.MainLoop.create_new_entity(currentSceneMain)
                                    end
                                    
                                    CImGui.EndMenu()
                                end
                                CImGui.EndMenu()
                            end
                            CImGui.Unindent(CImGui.GetTreeNodeToLabelSpacing())

                            currentHierarchyFilterText = hierarchyFilterText[]
                            text_input_single_line("get_scene_file_name_from_full_scene_path", hierarchyFilterText) 
                            updateSelectionsBasedOnFilter = hierarchyFilterText[] != currentHierarchyFilterText
                            filteredEntities = filter(entity -> (isempty(hierarchyFilterText[]) || contains(lowercase(entity.name), lowercase(hierarchyFilterText[]))), currentSceneMain.scene.entities)
                            entitiesWithParents = filter(entity -> entity.parent != C_NULL, currentSceneMain.scene.entities)

                            show_help_marker("Hold CTRL and click to select multiple items.")
                            if length(hierarchyEntitySelections) == 0 || length(hierarchyEntitySelections) != length(filteredEntities) || updateSelectionsBasedOnFilter
                                hierarchyEntitySelections= []
                                for entity in filteredEntities
                                    push!(hierarchyEntitySelections, (entity, false))
                                end
                            end

                            for n = eachindex(filteredEntities)
                                if filteredEntities[n].parent != C_NULL
                                    continue
                                end

                                children = filter(entity -> entity.parent == filteredEntities[n], entitiesWithParents)
                                if length(children) == 0
                                    handle_childless_entity_selection(filteredEntities[n], hierarchyEntitySelections, n, currentSceneMain)
                                else
                                    handle_parent_entity_selection(filteredEntities[n], children, hierarchyEntitySelections, n, currentSceneMain, filteredEntities)
                                end
                                handle_drag_and_drop(filteredEntities, n, currentSceneMain, hierarchyEntitySelections)
                            end

                            CImGui.PopStyleVar()
                            CImGui.Indent(CImGui.GetTreeNodeToLabelSpacing())
                            CImGui.TreePop()
                        end

                        CImGui.NewLine()
                        #region UI Elements
                        if currentSceneMain !== nothing && CImGui.TreeNode("UI Elements")
                            CImGui.SameLine()
                            if CImGui.BeginMenu("Add") # TODO: Move to own file as a function
                                CImGui.MenuItem("Add", C_NULL, false, false)
                                if CImGui.BeginMenu("New")
                                    if CImGui.MenuItem("TextBox")
                                        JulGame.MainLoop.create_new_text_box(currentSceneMain) 
                                    end
                                    if CImGui.MenuItem("Screen Button")
                                        JulGame.MainLoop.create_new_screen_button(currentSceneMain)
                                    end
                                    
                                    CImGui.EndMenu()
                                end
                                CImGui.EndMenu()
                            end
                            CImGui.Unindent(CImGui.GetTreeNodeToLabelSpacing())

                            if length(hierarchyUISelections) == 0 || length(hierarchyUISelections) != length(currentSceneMain.scene.uiElements) # || updateUISelectionsBasedOnFilter
                                hierarchyUISelections=fill(false, length(currentSceneMain.scene.uiElements))
                            end

                            for n = eachindex(currentSceneMain.scene.uiElements)
                                CImGui.PushID(n)
                                buf = "$(n): $(currentSceneMain.scene.uiElements[n].name)"
                                if CImGui.Selectable(buf, hierarchyUISelections[n])
                                    # clear selection when CTRL is not held
                                    !unsafe_load(CImGui.GetIO().KeyCtrl) && fill!(hierarchyUISelections, false)
                                    hierarchyUISelections[n] ⊻= 1
                                    uiSelected = true
                                    # currentSceneMain.selectedEntity = currentSceneMain.scene.uiElements[n]
                                end
                                CImGui.PopID()

                            end

                            CImGui.TreePop()
                        end
                    CImGui.End()
                catch e
                    handle_editor_exceptions("Hierarchy window:", latest_exceptions, e, is_test_mode)
                end

                try 
                    show_debug_window(latest_exceptions[])
                catch e
                    @error "Debug window error"
                end
                    
                    try
                        #region Entity Inspector
                        CImGui.Begin("Entity Inspector") 
                        
                        show_help_marker("This is where we will display editable properties of entities")
                        if currentSceneMain !== nothing && currentSceneMain.selectedEntity !== nothing 
                            CImGui.PushID("AddMenu")
                            if CImGui.BeginMenu("Add")
                                ShowEntityContextMenu(currentSceneMain.selectedEntity)
                                CImGui.EndMenu()
                            end
                            CImGui.PopID()
                            CImGui.Separator()
                            for entityField in fieldnames(Entity)
                                show_field_editor(currentSceneMain.selectedEntity, entityField, animation_window_dict, animator_preview_dict, newScriptText)
                            end
        
                            CImGui.Separator()
                            if CImGui.Button("Duplicate") 
                                copy = deepcopy(currentSceneMain.selectedEntity)
                                copy.id = JulGame.generate_uuid()
                                push!(currentSceneMain.scene.entities, copy)
                                currentSceneMain.selectedEntity = copy
                            end
                        end
                        CImGui.End()
                    catch e
                        handle_editor_exceptions("Entity inspector window:", latest_exceptions, e, is_test_mode)
                    end

                    try
                        
                        #region UI Inspector
                        CImGui.Begin("UI Inspector") 
                            show_help_marker("This is where we will display editable properties of textboxes and screen buttons")
                            for uiElementIndex = eachindex(hierarchyUISelections)
                                if hierarchyUISelections[uiElementIndex] # || currentSceneMain.selectedEntity == filteredEntities[entityIndex]
                                    if length(currentSceneMain.scene.uiElements) < uiElementIndex
                                        break
                                    end
                                    
                                    if contains("$(typeof(currentSceneMain.scene.uiElements[uiElementIndex]))", "TextBox")
                                        show_textbox_fields(currentSceneMain.scene.uiElements[uiElementIndex])
                                    else
                                        show_screenbutton_fields1(currentSceneMain.scene.uiElements[uiElementIndex])
                                    end

                                    # CImGui.Separator()
                                    # if CImGui.Button("Duplicate") 
                                    #     push!(currentSceneMain.scene.uiElements, deepcopy(currentSceneMain.scene.uiElements[uiElementIndex]))
                                    # copy.id = JulGame.generate_uuid()
                                    #     # TODO: switch to duplicated entity
                                    # end

                                    CImGui.Separator()
                                    CImGui.Text("Delete UI Element: NO CONFIRMATION")
                                    if CImGui.Button("Delete")
                                        JulGame.destroy_ui_element(currentSceneMain, currentSceneMain.scene.uiElements[uiElementIndex])
                                        break
                                    end
                                    
                                    break # TODO: Remove this when we can select multiple entities and edit them all at once
                                end
                            end
                        CImGui.End()
                    catch e
                        handle_editor_exceptions("UI inspector window:", latest_exceptions, e, is_test_mode)
                    end

                    try
                        show_camera_window(cameraWindow)
                    catch e
                        handle_editor_exceptions("Camera window:", latest_exceptions, e, is_test_mode)
                    end

                    #region Config Window
                    try 
                        CImGui.Begin("Project Config") 
                        show_help_marker("This tab contains configuration fields for the game when it is launched separately (command line or executable)")
                        if currentSelectedProjectPath[] !== ""
                            show_config_fields(currentProjectConfig, currentSelectedProjectPath)
                        end
                        CImGui.End()
                    catch e
                        handle_editor_exceptions("Config window:", latest_exceptions, e, is_test_mode)
                    end

                    SDL2.SDL_SetRenderTarget(renderer, sceneTexture)
                    SDL2.SDL_RenderClear(renderer)
                    try
                        if currentSceneMain !== nothing
                            JulGame.MainLoop.render_scene_sprites_and_shapes(currentSceneMain, camera)
                        end
                    catch e
                        handle_editor_exceptions("Scene window:", latest_exceptions, e, is_test_mode)
                    end

                    SDL2.SDL_SetRenderTarget(renderer, gameTexture)
                    SDL2.SDL_RenderClear(renderer)
                    try 
                        if currentSceneMain !== nothing
                            JulGame.CameraModule.update(gameCamera)
                            JulGame.MainLoop.render_scene_sprites_and_shapes(currentSceneMain, gameCamera)
                        end
                    catch e
                        handle_editor_exceptions("Game window:", latest_exceptions, e, is_test_mode)
                    end

                    try
                        gameInfo = currentSceneMain === nothing ? [] : JulGame.MainLoop.game_loop(currentSceneMain, startTime, lastPhysicsTime, Math.Vector2(sceneWindowPos.x + 8, sceneWindowPos.y + 25), Math.Vector2(sceneWindowSize.x, sceneWindowSize.y)) # Magic numbers for the border of the imgui window. TODO: Make this dynamic if possible
                    catch e
                        handle_editor_exceptions("Game loop:", latest_exceptions, e, is_test_mode)
                    end
                    
                    SDL2.SDL_SetRenderTarget(renderer, C_NULL)
                    SDL2.SDL_RenderClear(renderer)
                    
                    show_game_controls()

                    #region Input
                    try
                        if currentSceneMain !== nothing
                            if currentSceneMain.scene.camera != gameCamera
                                gameCamera = currentSceneMain.scene.camera
                                cameraWindow.camera = gameCamera
                            end

                            if JulGame.InputModule.get_button_held_down(currentSceneMain.input, "LCTRL") && JulGame.InputModule.get_button_pressed(currentSceneMain.input, "S")
                                @info string("Saving scene")
                                events["Save"]()
                            end
                            # delete selected entity
                            if JulGame.InputModule.get_button_pressed(currentSceneMain.input, "DELETE")
                                if currentSceneMain.selectedEntity !== nothing
                                    JulGame.destroy_entity(currentSceneMain, currentSceneMain.selectedEntity)
                                end
                            end
                            # duplicate selected entity with ctrl+d
                            if JulGame.InputModule.get_button_held_down(currentSceneMain.input, "LCTRL") && JulGame.InputModule.get_button_pressed(currentSceneMain.input, "D") && currentSceneMain.selectedEntity !== nothing
                                copy = deepcopy(currentSceneMain.selectedEntity)
                                copy.id = JulGame.generate_uuid()
                                push!(currentSceneMain.scene.entities, copy)
                                currentSceneMain.selectedEntity = copy
                            end
                            # turn on duplication mode with ctrl+shift+d
                            if JulGame.InputModule.get_button_held_down(currentSceneMain.input, "LCTRL") && JulGame.InputModule.get_button_held_down(currentSceneMain.input, "LSHIFT") && JulGame.InputModule.get_button_pressed(currentSceneMain.input, "D") && currentSceneMain.selectedEntity !== nothing
                                duplicationMode = !duplicationMode
                                if duplicationMode
                                    @info "Duplication mode on"
                                    copy = deepcopy(currentSceneMain.selectedEntity)
                                    copy.id = JulGame.generate_uuid()
                                    push!(currentSceneMain.scene.entities, copy)
                                    currentSceneMain.selectedEntity = copy
                                else
                                    @info "Duplication mode off"
                                    JulGame.destroy_entity(currentSceneMain, currentSceneMain.selectedEntity)
                                end
                            end
                        end
                    catch e
                        handle_editor_exceptions("Inputs:", latest_exceptions, e, is_test_mode)
                    end
                    ################################# STOP RENDERING HERE
                    CImGui.Render()
                    SDL2.SDL_RenderSetScale(renderer, unsafe_load(io.DisplayFramebufferScale.x), unsafe_load(io.DisplayFramebufferScale.y));
                    SDL2.SDL_SetRenderDrawColor(renderer, (UInt8)(round(clear_color[1] * 255)), (UInt8)(round(clear_color[2] * 255)), (UInt8)(round(clear_color[3] * 255)), (UInt8)(round(clear_color[4] * 255)));
                    SDL2.SDL_RenderClear(renderer);
                    ImGui_ImplSDLRenderer2_RenderDrawData(CImGui.GetDrawData())
                    
                    screenA = Ref(SDL2.SDL_Rect(round(sceneWindowPos.x), sceneWindowPos.y + 20, sceneWindowSize.x, sceneWindowSize.y - 20))
                    SDL2.SDL_RenderSetViewport(renderer, screenA)
                    ################################################# Injecting game loop into editor
                    if currentSceneMain !== nothing
                        if currentSceneMain.input.editorCallback === nothing
                            currentSceneMain.input.editorCallback = ImGui_ImplSDL2_ProcessEvent
                        end
                        JulGame.InputModule.poll_input(currentSceneMain.input)
                        quit = currentSceneMain.input.quit
                    end
                    #################################################

                    SDL2.SDL_RenderPresent(renderer);
                    if is_test_mode && testFrameCount < testFrameLimit
                        testFrameCount += 1
                    elseif is_test_mode
                        quit = true
                    end
                catch e 
                    @error "Error in renderloop!" exception=e
                    Base.show_backtrace(stderr, catch_backtrace())
                end
            end
        catch e
            backup_file_name = backup_file_name = "$(replace(currentSceneName, ".json" => ""))-backup-$(replace(Dates.format(Dates.now(), "yyyy-mm-ddTHH:MM:SS"), ":" => "-")).json"
            @info string("Backup file name: ", backup_file_name)
            SceneWriterModule.serialize_entities(currentSceneMain.scene.entities, currentSceneMain.scene.uiElements, gameCamera, currentSelectedProjectPath[], backup_file_name)
            Base.show_backtrace(stderr, catch_backtrace())
            @warn "Error in renderloop!" exception=e
        finally
            #TODO: fix these: ImGui_ImplSDLRenderer2_Shutdown();
            # ImGui_ImplSDL2_Shutdown();

            CImGui.DestroyContext(ctx)
            SDL2.SDL_DestroyTexture(sceneTexture)
            SDL2.SDL_DestroyTexture(gameTexture)
            SDL2.SDL_DestroyRenderer(renderer);
            SDL2.SDL_DestroyWindow(window);
            SDL2.SDL_Quit()
            return 0
        end
    end

    function handle_editor_exceptions(error_location, latest_exceptions, e, is_test_mode)
        # Get the stack trace
        bt = stacktrace(catch_backtrace())
                        
        file = ""
        line = ""
        if !isempty(bt)
            top_frame = bt[1]
            file = top_frame.file
            line = top_frame.line
        else
            @info("Stack trace is empty.")
        end

        log_exceptions(error_location, latest_exceptions, e, "$(file):$(line)", is_test_mode)
    end

    function show_config_fields(currentProjectConfig, currentSelectedProjectPath)
            CImGui.Text("Config")
            CImGui.NewLine()
            CImGui.Text("Width")
            CImGui.SameLine()
            CImGui.InputInt("##Width", currentProjectConfig.Width)
            CImGui.NewLine()
            CImGui.Text("Height")
            CImGui.SameLine()
            CImGui.InputInt("##Height", currentProjectConfig.Height)
            CImGui.NewLine()
            CImGui.Text("Frame Rate")
            CImGui.SameLine()
            CImGui.InputInt("##FrameRate", currentProjectConfig.FrameRate)
            CImGui.NewLine()
            CImGui.Text("Window Name")
            CImGui.SameLine()
            buf = "$(currentProjectConfig.WindowName[])"*"\0"^(64)
            CImGui.InputText("##WindowName", buf, length(buf))
            currentText = ""
            for characterIndex = eachindex(buf)
                if Int32(buf[characterIndex]) == 0 
                    if characterIndex != 1
                        currentText = String(SubString(buf, 1, characterIndex-1))
                    end
                    break
                end
            end
            currentProjectConfig.WindowName[] = currentText
            CImGui.NewLine()
            CImGui.Text("Pixels Per Unit")
            CImGui.SameLine()
            CImGui.InputInt("##PixelsPerUnit", currentProjectConfig.PixelsPerUnit)
            CImGui.NewLine()
            CImGui.Text("Auto Scale Zoom")
            CImGui.SameLine()
            CImGui.Checkbox("##AutoScaleZoom", currentProjectConfig.AutoScaleZoom)
            CImGui.NewLine()
            CImGui.Text("Is Resizable")
            CImGui.SameLine()
            CImGui.Checkbox("##IsResizable", currentProjectConfig.IsResizable)
            CImGui.NewLine()
            CImGui.Text("Fullscreen")
            CImGui.SameLine()
            CImGui.Checkbox("##Fullscreen", currentProjectConfig.Fullscreen)
            CImGui.NewLine()

        if CImGui.Button("Save Config")
            save_config_editor(currentProjectConfig, currentSelectedProjectPath)
        end
    end

    function save_config_editor(currentProjectConfig, currentSelectedProjectPath)
        filename = joinpath(currentSelectedProjectPath[], "config.julgame")
        config = Dict{String, String}()
        
        config["WindowName"] = String(currentProjectConfig.WindowName[])
        config["Width"] = string(currentProjectConfig.Width[])
        config["Height"] = string(currentProjectConfig.Height[])
        config["PixelsPerUnit"] = string(currentProjectConfig.PixelsPerUnit[])
        config["Zoom"] = "1.0"
        config["AutoScaleZoom"] = string(Int(currentProjectConfig.AutoScaleZoom[]))
        config["Fullscreen"] = string(Int(currentProjectConfig.Fullscreen[]))
        config["IsResizable"] = string(Int(currentProjectConfig.IsResizable[]))
        config["FrameRate"] = string(currentProjectConfig.FrameRate[])
        
        open(filename, "w") do file
            for (key, value) in config
                println(file, "$key=$value")
            end
        end

        @info "Saved config file to $(filename)"
    end

    function load_project_config(currentSelectedProjectPath)
        filename = joinpath(currentSelectedProjectPath[], "config.julgame")
        config = Dict{String, String}()
        if isfile(filename)
            open(filename, "r") do file
                for line in eachline(file)
                    key, value = split(line, "=")
                    config[key] = value
                end
            end
        end

        Width = Ref(Int32(parse(Int, config["Width"])))
        Height = Ref(Int32(parse(Int, config["Height"])))
        FrameRate = Ref(Int32(parse(Int, config["FrameRate"])))
        WindowName = Ref(config["WindowName"])
        PixelsPerUnit = Ref(Int32(parse(Int, config["PixelsPerUnit"])))
        AutoScaleZoom = Ref(parse(Bool, config["AutoScaleZoom"]))
        IsResizable = Ref(parse(Bool, config["IsResizable"]))
        Fullscreen = Ref(parse(Bool, config["Fullscreen"]))

        return (Width=Width, Height=Height, FrameRate=FrameRate, WindowName=WindowName, PixelsPerUnit=PixelsPerUnit, AutoScaleZoom=AutoScaleZoom, IsResizable=IsResizable, Fullscreen=Fullscreen)
    end
end # module

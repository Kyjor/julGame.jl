function show_scene_window(main, scene_tex_id, scrolling, zoom_level, duplicationMode, camera)
  #  CImGui.SetNextWindowSize((350, 560), CImGui.ImGuiCond_FirstUseEver)
    CImGui.Begin("Scene") || (CImGui.End(); return)
    # GET SIZE OF SCENE TEXTURE
    # w, h = Ref{Int32}(0), Ref{Int32}(0)
    # SDL2.SDL_QueryTexture(scene_tex_id[], Ref{UInt32}(0), Ref{Int32}(0), w, h)
    # println("Size of Scene Texture: ", w[], ", ", h[])
    draw_list = CImGui.GetWindowDrawList()
    io = CImGui.GetIO()
    
    # Canvas setup
    canvas_p0 = CImGui.GetCursorScreenPos()  # ImDrawList API uses screen coordinates!
    canvas_sz = CImGui.GetContentRegionAvail()  # Resize canvas to what's available
    canvas_sz = ImVec2(max(canvas_sz.x, 50.0), max(canvas_sz.y, 50.0))
    canvas_p1 = ImVec2(canvas_p0.x + canvas_sz.x, canvas_p0.y + canvas_sz.y)
    
    canvas_max = ImVec2(340, 560)
    origin = ImVec2(0 + scrolling[].x, 0 + scrolling[].y)  # Lock scrolled origin

    # Draw border and background color
    draw_list = CImGui.GetWindowDrawList()
    
    CImGui.AddRectFilled(draw_list, canvas_p0, canvas_p1, IM_COL32(50, 50, 50, 255))
    CImGui.AddImage(draw_list, scene_tex_id, canvas_p0, canvas_p1, ImVec2(0,0), ImVec2(1,1), IM_COL32(255,255,255,255))
    CImGui.AddRect(draw_list, canvas_p0, canvas_p1, IM_COL32(255, 255, 255, 255))

    # Draw border around actual image that is being edited TODO: Fix this
    # CImGui.AddRect(draw_list, ImVec2(canvas_p0.x + (my_tex_w * zoom_level[]), canvas_p0.y + (my_tex_h * zoom_level[])), ImVec2(canvas_p0.x, canvas_p0.y), IM_COL32(255, 255, 255, 255))

    # Invisible button for interactions
    CImGui.InvisibleButton("canvas", canvas_sz, CImGui.ImGuiButtonFlags_MouseButtonLeft | CImGui.ImGuiButtonFlags_MouseButtonRight)
    is_hovered = CImGui.IsItemHovered()  # Hovered
    is_active = CImGui.IsItemActive()  # Held
    # origin = ImVec2(canvas_p0.x + scrolling[].x, canvas_p0.y + scrolling[].y)  # Lock scrolled origin
    # scrolling[] = ImVec2(min(scrolling[].x, 0.0), min(scrolling[].y, 0.0))
    # scrolling[] = ImVec2(max(scrolling[].x, -canvas_max.x), max(scrolling[].y, -canvas_max.y))
    mouse_pos_in_canvas = ImVec2(unsafe_load(io.MousePos).x - canvas_p0.x, unsafe_load(io.MousePos).y - canvas_p0.y)

    mouse_pos_in_canvas_zoom_adjusted = ImVec2(floor(mouse_pos_in_canvas.x / zoom_level[]), floor(mouse_pos_in_canvas.y / zoom_level[]))
    #rounded = ImVec2(round(mouse_pos_in_canvas_zoom_adjusted.x/ zoom_level[]) * zoom_level[], round(mouse_pos_in_canvas_zoom_adjusted.y/ zoom_level[]) * zoom_level[])
    # Add first and second point
    
    # Pan
    mouse_threshold_for_pan = -1.0 
    mouse_drag_movement = ImVec2(0, 0)
    scale_unit_factor = 64
   
    if is_active && CImGui.IsMouseDragging(CImGui.ImGuiMouseButton_Right, mouse_threshold_for_pan)
        scrolling[] = ImVec2(scrolling[].x + unsafe_load(io.MouseDelta).x, scrolling[].y + unsafe_load(io.MouseDelta).y)
        mouse_drag_movement = ImVec2(unsafe_load(io.MouseDelta).x, unsafe_load(io.MouseDelta).y)
        # if scene is something, update the camera position
        if main !== nothing && camera !== nothing
            camera.position = Math.Vector2f(camera.position.x - (mouse_drag_movement.x/scale_unit_factor), camera.position.y - (mouse_drag_movement.y/scale_unit_factor))
        end
    end

    # Zoom
    if unsafe_load(io.KeyCtrl)
        # zoom_level[] += unsafe_load(io.MouseWheel) * 0.4 # * 0.10
        # zoom_level[] = clamp(zoom_level[], 0.2, 50.0)
    end
    if is_hovered && !unsafe_load(io.KeyCtrl) && (unsafe_load(io.MouseWheelH) != 0.0 || unsafe_load(io.MouseWheel) != 0.0) && main !== nothing && camera !== nothing
        # move camera
        camera.position = Math.Vector2f(camera.position.x - (unsafe_load(io.MouseWheelH)), camera.position.y - (unsafe_load(io.MouseWheel)))
    end
    camPos = main !== nothing && camera !== nothing ? ImVec2((camera.position.x * scale_unit_factor), (camera.position.y * scale_unit_factor)) : ImVec2(0, 0)

    # Context menu
    drag_delta_right = CImGui.GetMouseDragDelta(CImGui.ImGuiMouseButton_Right)
    if CImGui.IsMouseReleased(CImGui.ImGuiMouseButton_Right) && drag_delta_right.x == 0.0 && drag_delta_right.y == 0.0
        CImGui.OpenPopupOnItemClick("context")
    end
    # if left click
    drag_delta_left = CImGui.GetMouseDragDelta(CImGui.ImGuiMouseButton_Left)
    if CImGui.IsMouseReleased(CImGui.ImGuiMouseButton_Left) && is_hovered && drag_delta_left.x == 0.0 && drag_delta_left.y == 0.0
        if duplicationMode
            handle_mouse_click_duplication(main)
        else
            handle_mouse_click(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
        end
    end
    
    # if left click and drag
    if is_hovered && (CImGui.IsMouseDragging(CImGui.ImGuiMouseButton_Left, mouse_threshold_for_pan) || duplicationMode)
        drag_selected_entity(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
    end

    if CImGui.BeginPopup("context")
        if CImGui.MenuItem("Delete", "", false, main.selectedEntity !== nothing)
            println("Delete selected entity")
            JulGame.destroy_entity(main, main.selectedEntity)
        end
        CImGui.EndPopup()
    end

     # Draw grid and lines
     CImGui.PushClipRect(draw_list, canvas_p0, canvas_p1, true)

     GRID_STEP = 64.0 * zoom_level[]
     
     # Adjust starting points for infinite grid
     start_x = canvas_p0.x - mod(camPos.x, GRID_STEP)
     start_y = canvas_p0.y - mod(camPos.y, GRID_STEP)
     
     # Draw vertical grid lines
     for x in start_x:GRID_STEP:canvas_p1.x
         CImGui.AddLine(draw_list, ImVec2(x, canvas_p0.y), ImVec2(x, canvas_p1.y), IM_COL32(200, 200, 200, 40))
     end
     
     # Draw horizontal grid lines
     for y in start_y:GRID_STEP:canvas_p1.y
         CImGui.AddLine(draw_list, ImVec2(canvas_p0.x, y), ImVec2(canvas_p1.x, y), IM_COL32(200, 200, 200, 40))
     end
     
     CImGui.PopClipRect(draw_list)
     
    
    # Draw square around selected entity
    highlight_current_entity(main, draw_list, canvas_p0, canvas_p1, zoom_level, camPos)

    CImGui.End()

    return canvas_sz
end

function handle_mouse_click(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
    # if main is nothing, return
    if main === nothing
        return
    end
    # select nearest entity
    nearest_entity = get_nearest_entity(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
    
    main.selectedEntity = nearest_entity
end

function handle_mouse_click_duplication(main)
    # if main is nothing, return
    if main === nothing
        return
    end

    copy = deepcopy(main.selectedEntity)
    copy.id = JulGame.generate_uuid()
    push!(main.scene.entities, copy)
    main.selectedEntity = copy
end

function get_nearest_entity(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
    # if main is nothing, return
    if main === nothing
        return
    end
    # get all entities
    entities = main.scene.entities
    clicked_pos = ImVec2((mouse_pos_in_canvas_zoom_adjusted.x + camPos.x)/64, (mouse_pos_in_canvas_zoom_adjusted.y + camPos.y)/64)
    for entity in entities
        size = entity.transform.scale
        # entity.collider != C_NULL ? Component.get_size(entity.collider) : entity.transform.scale

        # get the nearest entity
        if clicked_pos.x >= entity.transform.position.x && clicked_pos.x <= entity.transform.position.x + size.x && clicked_pos.y >= entity.transform.position.y && clicked_pos.y <= entity.transform.position.y + size.y
            if main.selectedEntity == entity
                continue
            end
            return entity
        end
    end

    return nothing
end

function highlight_current_entity(main, draw_list, canvas_p0, canvas_p1, zoom_level, camPos)
    # if main is nothing, return
    if main === nothing
        return
    end
    # if selected entity is nothing, return
    if main.selectedEntity === nothing
        return
    end
    entity = main.selectedEntity
    
    # draw rect around selected entity
    # size = selectedEntity.collider != C_NULL ? JulGame.get_size(selectedEntity.collider) : selectedEntity.transform.scale
    CImGui.AddRect(draw_list, ImVec2(canvas_p0.x + (entity.transform.position.x * 64) - camPos.x, canvas_p0.y + entity.transform.position.y * 64 - camPos.y), ImVec2(canvas_p0.x + entity.transform.position.x * 64 + (entity.transform.scale.x * 64) - camPos.x, canvas_p0.y + entity.transform.position.y * 64 + (entity.transform.scale.y * 64) - camPos.y), IM_COL32(255, 0, 0, 255))
end

function drag_selected_entity(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
    # if main is nothing, return
    if main === nothing
        return
    end
    # if selected entity is nothing, return
    if main.selectedEntity === nothing
        return
    end
    entity = main.selectedEntity
    # get the mouse position
    mouse_pos = ImVec2((mouse_pos_in_canvas_zoom_adjusted.x + camPos.x)/64, (mouse_pos_in_canvas_zoom_adjusted.y + camPos.y)/64)
    if unsafe_load(CImGui.GetIO().KeyCtrl)
        mouse_pos = ImVec2(floor(mouse_pos.x), floor(mouse_pos.y))
    end
    # get the selected entity position
    entity_pos = entity.transform.position
    # get the difference between the mouse position and the entity position
    diff = ImVec2(mouse_pos.x - entity_pos.x, mouse_pos.y - entity_pos.y)
    # update the entity position
    entity.transform.position = Math.Vector2f(entity_pos.x + diff.x, entity_pos.y + diff.y)
end
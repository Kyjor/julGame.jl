function show_game_window(scene_tex_id)
    CImGui.Begin("Game") || (CImGui.End(); return)
    draw_list = CImGui.GetWindowDrawList()
    
    # UI elements
    # Canvas setup
    canvas_p0 = CImGui.GetCursorScreenPos()  # ImDrawList API uses screen coordinates!
    canvas_sz = CImGui.GetContentRegionAvail()  # Resize canvas to what's available
    # Actually, do not resize canvas to what's available, but a set size of the scene_tex_id size
    w, h = Ref{Int32}(0), Ref{Int32}(0)
    SDL2.SDL_QueryTexture(scene_tex_id, Ref{UInt32}(0), Ref{Int32}(0), w, h)
    canvas_sz = ImVec2(max(canvas_sz.x, 50.0), max(canvas_sz.y, 50.0))
    #canvas_sz = ImVec2(w[], h[])
    #canvas_sz = ImVec2(200, 200)
    canvas_p1 = ImVec2(canvas_p0.x + canvas_sz.x, canvas_p0.y + canvas_sz.y)
    # do not stretch the image to fit the canvas. create an image_p0 and image_p1
    image_p0 = ImVec2(canvas_p0.x, canvas_p0.y)
    image_p1 = ImVec2(canvas_p0.x + 200, canvas_p0.y + 200)
    # center the image in the canvas
    image_p0 = ImVec2(canvas_p0.x + (canvas_sz.x - (w[])) / 2, canvas_p0.y + (canvas_sz.y - (h[])) / 2)
    image_p1 = ImVec2(image_p0.x + w[], image_p0.y + h[])
    
    # Draw border and background color
    draw_list = CImGui.GetWindowDrawList()
    
    CImGui.AddRectFilled(draw_list, canvas_p0, canvas_p1, IM_COL32(50, 50, 50, 255))
    CImGui.AddImage(draw_list, scene_tex_id, image_p0, image_p1, ImVec2(0,0), ImVec2(1,1), IM_COL32(255,255,255,255))
    CImGui.AddRect(draw_list, canvas_p0, canvas_p1, IM_COL32(255, 255, 255, 255))

    CImGui.End()

    return canvas_sz
end

function handle_mouse_click_game(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
    # if main is nothing, return
    if main === nothing
        return
    end
    # select nearest entity
    nearest_entity = get_nearest_entity_game(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
    
    main.selectedEntity = nearest_entity
end

function handle_mouse_click_game_duplication(main)
    # if main is nothing, return
    if main === nothing
        return
    end

    copy = deepcopy(main.selectedEntity)
    copy.id = JulGame.generate_uuid()
    push!(main.scene.entities, copy)
    main.selectedEntity = copy
end

function get_nearest_entity_game(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
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

function highlight_current_entity_game(main, draw_list, canvas_p0, canvas_p1, zoom_level, camPos)
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

function drag_selected_entity_game(main, canvas_p0, camPos, mouse_pos_in_canvas_zoom_adjusted)
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
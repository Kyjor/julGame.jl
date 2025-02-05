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

    return canvas_sz, image_p0
end
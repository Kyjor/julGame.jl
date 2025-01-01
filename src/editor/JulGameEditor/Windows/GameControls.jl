function show_game_controls()
    @cstatic begin
        CImGui.Begin("Controls")  
            CImGui.Text("Pan scene: Hold right mouse button and move mouse")
            CImGui.NewLine()
            CImGui.Text("Select entity: Click on entity in scene window or in hierarchy window")
            CImGui.NewLine()
            CImGui.Text("Move entity: Hold left mouse button and drag entity")
            CImGui.NewLine()
            CImGui.Text("Duplicate entity: Select entity and click 'Duplicate' in hierarchy window or press 'LCTRL+D' keys")
            CImGui.NewLine()
            CImGui.Text("Duplicate entity brush: Select entity and press 'Shift+LCTRL+D' keys to activate and deactivate")
        CImGui.End()
    end
end

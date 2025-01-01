function show_debug_window(latestExceptions)
    @cstatic begin
        CImGui.Begin("Debug")
        CImGui.Text("The latest 10 exceptions are:")
        # Todo: multiple errors and parse them to give hints. Also color code them.
        counter = 1
        for exception in latestExceptions
            CImGui.Text("[$(counter)] $(exception[2]): $(exception[1])")
            CImGui.Button("Copy to clipboard") && (CImGui.SetClipboardText("[$(counter)] $(exception[2]): $(exception[1])");)
            CImGui.Button("Open in vscode") && (SDL2.SDL_OpenURL("vscode://file/$(exception[3])");)
            counter += 1
        end
        CImGui.End()
    end
end
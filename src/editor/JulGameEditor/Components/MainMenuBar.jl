using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic

"""
    ShowAppMainMenuBar(events)
Create a fullscreen menu bar and populate it.

# Arguments
- `events`: An array of event functions. These are callbacks that are triggered when the user selects a menu item.
"""
function show_main_menu_bar(events, main)
    if CImGui.BeginMainMenuBar()
        @cstatic buf="File"*"\0"^128 begin
            if CImGui.BeginMenu(buf)
                show_file_menu(events, main)
                CImGui.EndMenu()
            end
        end

        @cstatic buf="Scene"*"\0"^128 begin
            if main !== nothing && CImGui.BeginMenu(buf)
                show_scene_menu(events)
                CImGui.EndMenu()
            end

        end
        CImGui.EndMainMenuBar()
    end
end

"""
    show_file_menu(events, main)

Show the file menu in the main menu bar.

# Arguments
- `events`: An array of event functions. These are callbacks that are triggered when the user selects a menu item.
"""
function show_file_menu(events, main)
    if CImGui.MenuItem("New Project", "")
        events["New-project"]()
    end
    if CImGui.MenuItem("Open Project", "")
        events["Select-project"]()
    end
    if main !== nothing && CImGui.MenuItem("New Scene", "")
        events["New-Scene"]()
    end
end

function show_scene_menu(events)
    if CImGui.MenuItem("Save", "Ctrl+S")
        events["Save"]()
    end
    if CImGui.MenuItem("Play/Pause Scene", "")
        events["Play-Mode"]()
    end
    if CImGui.MenuItem("Reset Camera", "Ctrl+R")
        events["Reset-camera"]()
    end

    if CImGui.BeginMenu("Extras")
        if CImGui.MenuItem("Regenerate Ids")
            events["Regenerate-ids"]()
        end
        CImGui.EndMenu()
    end 
end
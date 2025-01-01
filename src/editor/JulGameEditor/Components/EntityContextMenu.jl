using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic

"""
ShowEntityContextMenu(currentEntitySelected)
Show menu that allows user to add new components to an entity
"""
function ShowEntityContextMenu(currentEntitySelected)
    CImGui.MenuItem("Add", C_NULL, false, false)
    if CImGui.BeginMenu("New")
        if CImGui.MenuItem("Animator")
            JulGame.add_animator(currentEntitySelected)
        end
        if CImGui.MenuItem("Collider")
            JulGame.add_collider(currentEntitySelected)
        end
        if CImGui.MenuItem("Rigidbody")
            JulGame.add_rigidbody(currentEntitySelected)
        end
        if CImGui.MenuItem("Shape")
            JulGame.add_shape(currentEntitySelected)
        end
        if CImGui.MenuItem("SoundSource")
            JulGame.add_sound_source(currentEntitySelected)
        end
        if CImGui.MenuItem("Sprite")
            JulGame.add_sprite(currentEntitySelected, true)
        end
        
        CImGui.EndMenu()
    end
end
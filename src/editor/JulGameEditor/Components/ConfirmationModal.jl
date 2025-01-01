mutable struct ConfirmationModal 
    cancelText::String
    confirmText::String
    message::String
    name::String
    open::Bool
    type::String

    function ConfirmationModal(name::String; message::String = "Are you sure?", confirmText::String = "Ok", cancelText::String = "Cancel", open::Bool = false, type::String = "Warning")
        new(cancelText, confirmText, message, name, open, type)
    end
end

function show_modal(this::ConfirmationModal; action = nothing) 
    if !this.open
        return false
    end

    CImGui.OpenPopup(this.name)
    if CImGui.BeginPopupModal(this.name, C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        CImGui.Text(this.message)
        CImGui.NewLine()
        if CImGui.Button(this.confirmText, (120, 0))
            CImGui.CloseCurrentPopup()
            this.open = false
            if action !== nothing
                action()
            end

            return true
        end
        CImGui.SetItemDefaultFocus()
        CImGui.SameLine()
        if CImGui.Button(this.cancelText,(120, 0))
            CImGui.CloseCurrentPopup()
            this.open = false
        end
        CImGui.EndPopup()
    end
    return false
end






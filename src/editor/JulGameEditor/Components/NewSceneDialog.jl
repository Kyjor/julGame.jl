function new_scene_dialog(dialog, newSceneText)
    CImGui.OpenPopup(dialog[])

    if CImGui.BeginPopupModal(dialog[], C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        CImGui.Text("Are you sure you would like to open this scene?\nIf you currently have a scene open, any unsaved changes will be lost.\n\n")
        #CImGui.Separator()
        CImGui.NewLine()
        # show text input for scene name
        text = text_input_single_line("Scene Name", newSceneText) 
        # @cstatic dont_ask_me_next_time=false begin
        #     CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FramePadding, (0, 0))
        #     @c CImGui.Checkbox("Don't ask me next time", &dont_ask_me_next_time)
        #     CImGui.PopStyleVar()
        # end

        if CImGui.Button("OK", (120, 0))
            CImGui.CloseCurrentPopup()
            dialog[] = ""
            text = strip(text)
            # replace spaces with dashes 
            text = replace(text, " " => "-")
            return text
        end
        CImGui.SetItemDefaultFocus()
        CImGui.SameLine()
        if CImGui.Button("Cancel",(120, 0))
            CImGui.CloseCurrentPopup()
            dialog[] = ""
        end
        CImGui.EndPopup()

        return ""
    end
end
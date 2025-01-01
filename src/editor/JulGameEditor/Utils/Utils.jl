using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic

"""
ShowDrag()
Show menu that allows user to add new components to an entity
"""
function ShowDrag()
    @cstatic mode=Cint(0) names=["Bobby", "Beatrice", "Betty", "Brianna", "Barry", "Bernard", "Bibi", "Blaine", "Bryn"] begin
    CImGui.BulletText("Drag and drop to copy/swap items")
    CImGui.Indent()
    Mode_Copy, Mode_Move, Mode_Swap = 0, 1, 2
    CImGui.RadioButton("Copy", mode == Mode_Copy) && (mode = Mode_Copy;)
    CImGui.SameLine()
    CImGui.RadioButton("Move", mode == Mode_Move) && (mode = Mode_Move;)
    CImGui.SameLine()
    CImGui.RadioButton("Swap", mode == Mode_Swap) && (mode = Mode_Swap;)
    for n = 0:length(names)-1
        CImGui.PushID(n)
        (n % 3) != 0 && CImGui.SameLine()
        CImGui.Button(names[n+1], (60,60))

        # our buttons are both drag sources and drag targets here!
        if CImGui.BeginDragDropSource(CImGui.ImGuiDragDropFlags_None)
            @c CImGui.SetDragDropPayload("DND_DEMO_CELL", &n, sizeof(Cint)) # set payload to carry the index of our item (could be anything)
            mode == Mode_Copy && CImGui.Text("Copy $(names[n+1])") # display preview (could be anything, e.g. when dragging an image we could decide to display the filename and a small preview of the image, etc.)
            mode == Mode_Move && CImGui.Text("Move $(names[n+1])")
            mode == Mode_Swap && CImGui.Text("Swap $(names[n+1])")
            CImGui.EndDragDropSource()
        end
        if CImGui.BeginDragDropTarget()
            payload = CImGui.AcceptDragDropPayload("DND_DEMO_CELL")
            if payload != C_NULL
                #@assert CImGui.Get(payload, :DataSize) == sizeof(Cint)
                payload_n = unsafe_load(payload)
                println(payload_n)
                return
                if mode == Mode_Copy
                    names[n+1] = names[payload_n+1]
                end
                if mode == Mode_Move
                    names[n+1] = names[payload_n+1]
                    names[payload_n+1] = ""
                end
                if mode == Mode_Swap
                    tmp = names[n+1]
                    names[n+1] = names[payload_n+1]
                    names[payload_n+1] = tmp
                end
            end
            CImGui.EndDragDropTarget()
        end
        CImGui.PopID()
    end
    CImGui.Unindent()
    end # @cstatic
end

function show_help_marker(desc)
    CImGui.TextDisabled("(?)")
    if CImGui.IsItemHovered()
        CImGui.BeginTooltip()
        CImGui.PushTextWrapPos(CImGui.GetFontSize() * 35.0)
        CImGui.TextUnformatted(desc)
        CImGui.PopTextWrapPos()
        CImGui.EndTooltip()
    end
end
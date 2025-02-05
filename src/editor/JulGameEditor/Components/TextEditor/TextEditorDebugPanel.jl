# void TextEditor::ImGuiDebugPanel(const std::string& panelName)
# {
# 	ImGui::Begin(panelName.c_str());

# 	if (ImGui::CollapsingHeader("Editor state info"))
# 	{
# 		ImGui::Checkbox("Panning", &mPanning);
# 		ImGui::Checkbox("Dragging selection", &mDraggingSelection);
# 		ImGui::DragInt("Cursor count", &mState.mCurrentCursor);
# 		for (int i = 0; i <= mState.mCurrentCursor; i++)
# 		{
# 			ImGui::DragInt2("Interactive start", &mState.mCursors[i].mInteractiveStart.mLine);
# 			ImGui::DragInt2("Interactive end", &mState.mCursors[i].mInteractiveEnd.mLine);
# 		}
# 	}
# 	if (ImGui::CollapsingHeader("Lines"))
# 	{
# 		for (int i = 0; i < mLines.size(); i++)
# 		{
# 			ImGui::Text("%zu", mLines[i].size());
# 		}
# 	}
# 	if (ImGui::CollapsingHeader("Undo"))
# 	{
# 		static std::string numberOfRecordsText;
# 		numberOfRecordsText = "Number of records: " + std::to_string(mUndoBuffer.size());
# 		ImGui::Text("%s", numberOfRecordsText.c_str());
# 		ImGui::DragInt("Undo index", &mState.mCurrentCursor);
# 		for (int i = 0; i < mUndoBuffer.size(); i++)
# 		{
# 			if (ImGui::CollapsingHeader(std::to_string(i).c_str()))
# 			{

# 				ImGui::Text("Operations");
# 				for (int j = 0; j < mUndoBuffer[i].mOperations.size(); j++)
# 				{
# 					ImGui::Text("%s", mUndoBuffer[i].mOperations[j].mText.c_str());
# 					ImGui::Text(mUndoBuffer[i].mOperations[j].mType == UndoOperationType::Add ? "Add" : "Delete");
# 					ImGui::DragInt2("Start", &mUndoBuffer[i].mOperations[j].mStart.mLine);
# 					ImGui::DragInt2("End", &mUndoBuffer[i].mOperations[j].mEnd.mLine);
# 					ImGui::Separator();
# 				}
# 			}
# 		}
# 	}
# 	if (ImGui::Button("Run unit tests"))
# 	{
# 		UnitTests();
# 	}
# 	ImGui::End();
# }
using CImGui

function imgui_debug_panel(panelName::String, mPanning::Ref{Bool}, mDraggingSelection::Ref{Bool}, 
                           mState::EditorState, mLines::Vector{String}, mUndoBuffer::Vector{UndoRecord})
    CImGui.Begin(panelName)

    if CImGui.CollapsingHeader("Editor state info")
        CImGui.Checkbox("Panning", mPanning)
        CImGui.Checkbox("Dragging selection", mDraggingSelection)
        CImGui.DragInt("Cursor count", Ref(mState.mCurrentCursor))
        for i in 0:mState.mCurrentCursor
            CImGui.DragInt2("Interactive start", Ref(mState.mCursors[i+1].mInteractiveStart.mLine))
            CImGui.DragInt2("Interactive end", Ref(mState.mCursors[i+1].mInteractiveEnd.mLine))
        end
    end

    if CImGui.CollapsingHeader("Lines")
        for i in 1:length(mLines)
            CImGui.Text("$(length(mLines[i]))")
        end
    end

    if CImGui.CollapsingHeader("Undo")
        numberOfRecordsText = "Number of records: $(length(mUndoBuffer))"
        CImGui.Text(numberOfRecordsText)
        CImGui.DragInt("Undo index", Ref(mState.mCurrentCursor))
        for i in 1:length(mUndoBuffer)
            if CImGui.CollapsingHeader("$i")
                CImGui.Text("Operations")
                for j in 1:length(mUndoBuffer[i].mOperations)
                    CImGui.Text("$(mUndoBuffer[i].mOperations[j].mText)")
                    CImGui.Text(mUndoBuffer[i].mOperations[j].mType == UndoOperationType.Add ? "Add" : "Delete")
                    CImGui.DragInt2("Start", Ref(mUndoBuffer[i].mOperations[j].mStart.mLine))
                    CImGui.DragInt2("End", Ref(mUndoBuffer[i].mOperations[j].mEnd.mLine))
                    CImGui.Separator()
                end
            end
        end
    end

    if CImGui.Button("Run unit tests")
        unit_tests()
    end

    CImGui.End()
end
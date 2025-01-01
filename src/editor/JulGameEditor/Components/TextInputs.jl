
"""
    text_input_single_line(name::String, filters = CImGui.ImGuiInputTextFlags_None)

Create a single-line text input field.

# Arguments
- `name::String`: The name of the text input field.
- `filters`: Optional. The ImGui filters to apply to the text input field.

# Returns
- `currentText`: The current text entered in the text input field.

"""
function text_input_single_line(name::String, currentText; maxBuf=128, filters = CImGui.ImGuiInputTextFlags_None)
    buf="$(currentText[])"*"\0"^maxBuf 
    CImGui.PushID(name)
    CImGui.InputText(name, buf, length(buf), filters)
    for characterIndex = eachindex(buf)
        if Int32(buf[characterIndex]) == 0 # The end of the buffer will be recognized as a 0
            currentText[] = characterIndex == 1 ? "" : String(SubString(buf, 1, characterIndex - 1))
            break
        end
    end
    CImGui.PopID()
    return currentText[]
end

mutable struct TextInputSingleLine
    name::String
    currentText::String
    maxBuf::Int
    filters::CImGui.ImGuiInputTextFlags

    function TextInputSingleLine(name::String, currentText::String; maxBuf=128, filters = CImGui.ImGuiInputTextFlags_None)
        this = new()

        this.name = name
        this.currentText = currentText
        this.maxBuf = maxBuf
        this.filters = filters

        return this
    end
end
    
    """
        text_input_single_line(this::TextInputSingleLine)

    Create a single-line text input field.

    # Arguments
    - `this::TextInputSingleLine`: The text input field.
    - `filters`: Optional. The ImGui filters to apply to the text input field.

    # Returns
    - `currentText`: The current text entered in the text input field.

    """
    
function text_input_single_line(this::TextInputSingleLine)
    buf = "$(this.currentText)"*"\0"^this.maxBuf
    CImGui.PushID(this.name)
    CImGui.InputText(this.name, buf, length(buf), this.filters)
    for characterIndex = eachindex(buf)
        if Int32(buf[characterIndex]) == 0 # The end of the buffer will be recognized as a 0
            this.currentText = characterIndex == 1 ? "" : String(SubString(buf, 1, characterIndex - 1))
            break
        end
    end
    CImGui.PopID()
    return this.currentText
end
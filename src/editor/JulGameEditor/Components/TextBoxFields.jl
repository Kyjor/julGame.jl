function show_textbox_fields(selectedTextBox, textBoxField)
    fieldName = getFieldName(textBoxField)
    Value = getfield(selectedTextBox, textBoxField)

    if fieldName == "text" || fieldName == "name" 
        buf = "$(Value)"*"\0"^(64)
        CImGui.InputText("$(textBoxField)", buf, length(buf))
        currentTextInTextBox = ""
        for characterIndex = eachindex(buf)
            if Int32(buf[characterIndex]) == 0 
                if characterIndex != 1
                    currentTextInTextBox = String(SubString(buf, 1, characterIndex-1))
                end
                break
            end
        end
        setfield!(selectedTextBox, textBoxField, currentTextInTextBox)
        
        if currentTextInTextBox != Value
            selectedTextBox.text = selectedTextBox.text        
        end
    elseif fieldName == "alpha"
        x = Cint(Value)
        @c CImGui.SliderInt("$(textBoxField)", &x, 0, 255)
        setfield!(selectedTextBox, textBoxField, convert(Int32, round(x)))

        if x != Value
            selectedTextBox.text = selectedTextBox.text
        end

    elseif fieldName == "color"
        x = Cfloat(Value.r)
        y = Cfloat(Value.g)
        z = Cfloat(Value.b)
        w = Cfloat(Value.a)
        @c CImGui.ColorEdit4("$(textBoxField)", &x, &y, &z, &w)
        setfield!(selectedTextBox, textBoxField, Color(convert(Int32, round(x)), convert(Int32, round(y)), convert(Int32, round(z)), convert(Int32, round(w))))

        if x != Value.r || y != Value.g || z != Value.b || w != Value.a
            selectedTextBox.text = selectedTextBox.text
        end
    elseif fieldName == "position"
        x = Cint(Value.x)
        y = Cint(Value.y)
        @c CImGui.InputInt("$(textBoxField) x", &x, 1)
        @c CImGui.InputInt("$(textBoxField) y", &y, 1)
        
        if x != Value.x || y != Value.y
            #selectedTextBox.setVector2Value(textBoxField, convert(Float64, x), convert(Float64, y))
            setfield!(selectedTextBox, textBoxField, Vector2(x, y))
            selectedTextBox.text = selectedTextBox.text
        end
    elseif fieldName == "autoSizeText" || fieldName == "isCenteredX" || fieldName == "isCenteredY" || fieldName == "isWorldEntity" || fieldName == "isActive"
        @c CImGui.Checkbox("$(textBoxField)", &Value)

        if Value != getfield(selectedTextBox, textBoxField)
            setfield!(selectedTextBox, textBoxField, Value)
            selectedTextBox.text = selectedTextBox.text
        end
    elseif fieldName == "fontSize"
        newSize = Cint(Value)
        @c CImGui.InputInt("$(textBoxField)", &newSize, 1)
        
        if newSize != Value
            JulGame.update_font_size(selectedTextBox, newSize)
        end
    end
end

function getFieldName(field)
    return "$(field)"
end
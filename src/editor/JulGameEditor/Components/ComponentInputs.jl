using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using JulGame
using JulGame.Math
using JulGame.UI
using FileWatching
#include("TextBoxFields.jl")
#include("ScreenButtonFields.jl")


"""
show_field_editor(entity, field)
Creates inputs based on the component type and populates them.
"""
function show_field_editor(entity, fieldName, animation_window_dict, animator_preview_dict, newScriptText)
    field = getfield(entity, fieldName)
    if field == C_NULL || field === nothing
        return
    end

    if !is_a_julgame_component(field)
        show_component_field_input(entity, fieldName, newScriptText)
        return
    end

    fieldName::String = replace(split("$(typeof(field))", ".")[end], "Internal" => "") # Example: JulGame.ColliderModule.InternalCollider => InternalCollider => Collider
    if CImGui.TreeNode("$(fieldName)") 
        if delete_button(entity, fieldName)
            CImGui.TreePop()
            return
        end

        if isa(field, SpriteModule.InternalSprite)
            show_sprite_fields(entity.sprite, animation_window_dict)
        elseif isa(field, SoundSourceModule.InternalSoundSource)
            show_sound_source_fields(entity.soundSource)
        elseif isa(field, AnimatorModule.InternalAnimator)
            show_animator_properties(entity.animator, animation_window_dict, animator_preview_dict)
        else
            for field in fieldnames(typeof(field))
                show_component_field_input(getfield(entity, Symbol(lowercase(fieldName))), field, "")
            end
        end

        CImGui.TreePop()
    end
end

"""
    delete_button(entity, fieldName)::Bool

Delete button for a component field.

Parameters:
- `entity`: The entity object.
- `fieldName`: The name of the field to delete.

Returns:
- `true` if the delete button is pressed and the field is deleted.
- `false` otherwise.
"""
function delete_button(entity, fieldName)::Bool
    if fieldName == "Transform"
        return false
    end

    if CImGui.Button("Delete")
        println("Deleting $(fieldName)")
        setfield!(entity, Symbol(lowercase(fieldName)), C_NULL)
        return true
    end

    return false
end

"""
    show_component_field_input(component, componentField)

This function displays the input fields for a given component field. It takes two arguments:
- `component`: The component object.
- `componentField`: The field of the component object.

The function checks the type of the field value and displays the corresponding input fields using CImGui library. It updates the field value based on the user input.

"""
function show_component_field_input(component, componentField, newScriptText)
    fieldValue = getfield(component, componentField)
    if isa(fieldValue, String) && String(componentField) == "id"
        #display id as text and add a button to copy it to clipboard
        CImGui.Text("$(componentField): $(fieldValue)")
        CImGui.SameLine()
        CImGui.Button("Copy") && SDL2.SDL_SetClipboardText(fieldValue)
    elseif isa(fieldValue, Math._Vector2{Float64}) || isa(fieldValue, Math._Vector2{Int32})
        isFloat::Bool = isa(fieldValue, Math._Vector2{Float64}) ? true : false

        x = isFloat ? Cfloat(fieldValue.x) : Cint(fieldValue.x)
        y = isFloat ? Cfloat(fieldValue.y) : Cint(fieldValue.y)
        if CImGui.TreeNode("$(componentField)")
            if isFloat 
                @c CImGui.InputFloat("$(componentField) x", &x, 1)
                @c CImGui.InputFloat("$(componentField) y", &y, 1)
            else
                @c CImGui.InputInt("$(componentField) x", &x, 1)
                @c CImGui.InputInt("$(componentField) y", &y, 1)
            end
            setfield!(component, componentField, (isFloat ? Vector2f(x, y) : Vector2(x, y)))
            CImGui.TreePop()
        end

    elseif isa(fieldValue, Math._Vector3{Float64}) || isa(fieldValue, Math._Vector3{Int32})
        isFloat = isa(fieldValue, Math._Vector3{Float64}) ? true : false

        vec3 = isFloat ? Cfloat[fieldValue.x, fieldValue.y, fieldValue.z] : Cint[fieldValue.x, fieldValue.y, fieldValue.z]

        if CImGui.TreeNode("$(componentField)")   
            if isFloat 
                @c CImGui.InputFloat3("input float3", vec3)
            else
                @c CImGui.InputInt3("input int3", vec3)
            end
        
            setfield!(component, componentField, (isFloat ? Vector3f(vec3[1], vec3[2], vec3[3]) : Vector3(vec3[1], vec3[2], vec3[3])))
            CImGui.TreePop()
        end
            
    elseif isa(fieldValue, Math._Vector4{Float64}) || isa(fieldValue, Math._Vector4{Int32})
        isFloat = isa(fieldValue, Math._Vector4{Float64}) ? true : false

        vec4 = isFloat ? Cfloat[fieldValue.x, fieldValue.y, fieldValue.z, fieldValue.t] : Cint[fieldValue.x, fieldValue.y, fieldValue.z, fieldValue.t]

        if CImGui.TreeNode("$(componentField)")
            if isFloat 
                @c CImGui.InputFloat4("input float4", vec4)
            else
                @c CImGui.InputInt4("input int4", vec4)
            end

            setfield!(component, componentField, (isFloat ? Vector4f(vec4[1], vec4[2], vec4[3], vec4[4]) : Vector4(vec4[1], vec4[2], vec4[3], vec4[4])))
            CImGui.TreePop()
        end

    elseif isa(fieldValue, Bool) 
        @c CImGui.Checkbox("$(componentField)", &fieldValue)
        setfield!(component, componentField, fieldValue)

    elseif isa(fieldValue, String) && String(componentField) != "id"
        buf = "$(fieldValue)"*"\0"^(64)
        CImGui.InputText("$(componentField)", buf, length(buf))
        currentTextInTextBox = ""
        for characterIndex = eachindex(buf)
            if Int32(buf[characterIndex]) == 0 
                if characterIndex != 1
                    currentTextInTextBox = String(SubString(buf, 1, characterIndex-1))
                end
                break
            end
        end
        setfield!(component, componentField, currentTextInTextBox)

    elseif isa(fieldValue, Int32) || isa(fieldValue, Float64)
        isFloat = isa(fieldValue, Float64) ? true : false
        x = isFloat ? Cfloat(fieldValue) : Cint(fieldValue)
        if isFloat 
            @c CImGui.InputFloat("$(componentField)", &x, 1)
            x = Float64(x)
        else
            @c CImGui.InputInt("$(componentField)", &x, 1)
        end
        setfield!(component, componentField, x)
    elseif String(componentField) == "scripts"
        show_script_editor(component, newScriptText)
    elseif isa(fieldValue, Vector) # Then we need to unpack the nested items
        for i = eachindex(fieldValue)
            continue # TODO: Implement this
            if is_a_julgame_component(fieldValue[i])
                if CImGui.TreeNode("$(nestedFieldType) $(i)")
                for field in fieldnames(typeof(fieldValue[i]))
                    show_field_editor(fieldValue[i], field)
                end
                CImGui.TreePop()
            end
            else
                #show_component_field_input(fieldValue, i)
            end
        end
    end
end

"""
        show_animator_properties(animator, animation_window_dict, animator_preview_dict)

Display the properties of an animator object in the user interface.

# Arguments
- `animator`: The animator object to display properties for.

"""
function show_animator_properties(animator, animation_window_dict, animator_preview_dict)
    try
        for field in fieldnames(typeof(animator))
            fieldString = "$(field)"
            
            if fieldString == "animations"
                animationFields=fieldnames(JulGame.AnimationModule.Animation);
                animations = animator.animations
                currentRenderTime = SDL2.SDL_GetTicks()

                CImGui.Button("Add Animation") && Component.append_array(animator)
                for i = eachindex(animations) 
                    if animator.parent.sprite != C_NULL && animator.parent.sprite !== nothing
                        animator_preview_dict_key = "animation-$(animator.parent.id)-$(i)"
                        animator_preview_dict_info = Ref(Dict("lastFrame" => 1, "lastUpdate" => SDL2.SDL_GetTicks()))

                        if haskey(animator_preview_dict[], animator_preview_dict_key)
                            animator_preview_dict_info[] = animator_preview_dict[][animator_preview_dict_key][]
                        else
                            animator_preview_dict[][animator_preview_dict_key] = animator_preview_dict_info
                        end

                        show_image_animation_with_hover_preview(animator, animations[i], currentRenderTime, animator_preview_dict_info)
                    end
                    if CImGui.TreeNode("animation $(i)")
                        for j = eachindex(animationFields)
                            animationFieldString = "$(animationFields[j])"
                            if animationFieldString == "animatedFPS"
                                x = Cint(animations[i].animatedFPS)
                                @c CImGui.InputInt("$(animationFieldString) $(j)", &x, 1)
                                animator.animations[i].animatedFPS = x
                            elseif animationFieldString == "frames"
                                try
                                    CImGui.Button("Add Frame") && Component.append_array(animations[i])
                                    CImGui.Button("Delete") && (deleteat!(animations, i); break;)
                                    for k = eachindex(animations[i].frames)
                                        vec = animations[i].frames[k]
                                        anim_x, anim_y, anim_w, anim_h = vec.x, vec.y, vec.z, vec.t

                                        if animator.parent.sprite != C_NULL && animator.parent.sprite !== nothing
                                            sprite = animator.parent.sprite
                                            show_image_with_hover_preview(sprite.texture, sprite.size.x, sprite.size.y, animations[i].frames[k])
                                        end
                                        if CImGui.TreeNode("frame $(k)")
                                            CImGui.Button("Delete") && (deleteat!(animations[i].frames, k); break;)
                                            if animator.parent.sprite != C_NULL && animator.parent.sprite !== nothing
                                                
                                                points = Ref(Vector{ImVec2}([ImVec2(anim_x, anim_y), ImVec2(anim_x + anim_w, anim_y + anim_h)]))
                                                scrolling = Ref(ImVec2(0.0, 0.0))
                                                adding_line = Ref(false)
                                                zoom_level = Ref(1.0)
                                                grid_step = Ref(Int32(64))

                                                # put these in a ref dictionary
                                                window_info = Ref(Dict("points" => points, "scrolling" => scrolling, "adding_line" => adding_line, "zoom_level" => zoom_level, "grid_step" => grid_step))
                                                # check if animation_window_dict has the key "frame $(k)"
                                                key = "animation-$(animator.parent.id)-$(i)-frame-$(k)"

                                                if haskey(animation_window_dict[], key)
                                                    # animation_window_dict[]["frame $(k)"][]["points"] = points
                                                    window_info[] = animation_window_dict[][key][]
                                                else
                                                    animation_window_dict[][key] = window_info
                                                end
                    
                                                sprite = animator.parent.sprite
                                                anim_x, anim_y, anim_w, anim_h = show_animation_window(key, window_info, sprite.texture, sprite.size.x, sprite.size.y)
                                                if anim_x == -1 && anim_y == -1 && anim_w == -1 && anim_h == -1
                                                    # TODO: fix this anim_x, anim_y, anim_w, anim_h = vec.x, vec.y, vec.z, vec.t
                                                    continue
                                                end
                                            end

                                            vec4i = Cint[anim_x, anim_y, anim_w, anim_h]
                                            @c CImGui.InputInt4("frame input $(k)", vec4i)
                                            window_info[]["points"][][1] = ImVec2(vec4i[1], vec4i[2])
                                            window_info[]["points"][][2] = ImVec2(round(vec4i[1] + vec4i[3]), round(vec4i[2] + vec4i[4]))
                                            Component.update_array_value(animations[i], JulGame.Math.Vector4(Int32(vec4i[1]), Int32(vec4i[2]), Int32(vec4i[3]), Int32(vec4i[4])), animationFields[j], Int32(k))
                                            CImGui.TreePop()
                                        end
                                    end
                                catch e
                                    rethrow(e)
                                end
                            end
                        end
                        CImGui.TreePop()
                    end
                end
            else
                show_component_field_input(animator, field, "")
            end  
        end
    catch e
        rethrow(e)
    end
end

"""
    show_sprite_fields(sprite)

Iterates over the fields of the `sprite` object and displays input fields for each field.
If the field is `imagePath`, it displays an input text field for the image path, a button to load the image,
and updates the `sprite.imagePath` field with the current text in the text box.

# Arguments
- `sprite`: The sprite object to display the fields for.

"""
function show_sprite_fields(sprite, animation_window_dict)
    for field in fieldnames(typeof(sprite))
        fieldString = "$(field)"

        if fieldString == "imagePath"
            CImGui.Text("Image: $(sprite.imagePath == "" ? "None" : sprite.imagePath)")
            
            imageMenuValue = display_files(joinpath(JulGame.BasePath, "assets", "images"), "images")
            if imageMenuValue != ""
                println("imageMenuValue: $imageMenuValue")
                # remove joinpath("assets", "images") from imageMenuValue and set it to imagePath
                imagePath = replace(imageMenuValue, joinpath(JulGame.BasePath, "assets", "images") => "")
                # remove leading / or \\ from imagePath
                if imagePath[1] == '/' || imagePath[1] == '\\'
                    imagePath = imagePath[2:end]
                end

                sprite.imagePath = imagePath
                Component.load_image(sprite, imagePath)
            end 
        elseif fieldString == "crop"
            if sprite.crop === nothing || sprite.crop == C_NULL
                sprite.crop = JulGame.Math.Vector4(0,0,0,0)
            end
            
            crop_x, crop_y, crop_w, crop_h = sprite.crop.x, sprite.crop.y, sprite.crop.z, sprite.crop.t

            points = Ref(Vector{ImVec2}([ImVec2(crop_x, crop_y), ImVec2(crop_x + crop_w, crop_y + crop_h)]))
            scrolling = Ref(ImVec2(0.0, 0.0))
            adding_line = Ref(false)
            zoom_level = Ref(1.0)
            grid_step = Ref(Int32(64))
            # put these in a ref dictionary
            window_info = Ref(Dict("points" => points, "scrolling" => scrolling, "adding_line" => adding_line, "zoom_level" => zoom_level, "grid_step" => grid_step))
            # check if animation_window_dict has the key "frame $(k)"
            key = "crop-$(sprite.parent.id)"
            if haskey(animation_window_dict[], key)
                # animation_window_dict[]["frame $(k)"][]["points"] = points
                window_info[] = animation_window_dict[][key][]
            else
                # print("Adding crop window info for: $key")
                animation_window_dict[][key] = window_info
            end

            CImGui.PushID(sprite.parent.id)
                crop_x, crop_y, crop_w, crop_h = show_animation_window("Sprite crop", window_info, sprite.texture, sprite.size.x, sprite.size.y)
                if crop_x == -1 && crop_y == -1 && crop_w == -1 && crop_h == -1
                    # TODO: fix this crop_x, crop_y, crop_w, crop_h = sprite.crop.x, sprite.crop.y, sprite.crop.z, sprite.crop.t
                    continue
                end
            CImGui.PopID()
            vec4i = Cint[crop_x, crop_y, crop_w, crop_h]
            @c CImGui.InputInt4("crop", vec4i)
            window_info[]["points"][][1] = ImVec2(vec4i[1], vec4i[2])
            window_info[]["points"][][2] = ImVec2(round(vec4i[1] + vec4i[3]), round(vec4i[2] + vec4i[4]))
            sprite.crop = JulGame.Math.Vector4(Int32(vec4i[1]), Int32(vec4i[2]), Int32(vec4i[3]), Int32(vec4i[4]))
        elseif fieldString == "rotation"
            x = Cfloat(sprite.rotation)
            @c CImGui.InputFloat("rotation", &x, 1)
            x = Float64(x)
            sprite.rotation = x
        elseif fieldString == "center"
            #float that is min 0 and max 1
            x = Cfloat(sprite.center.x)
            y = Cfloat(sprite.center.y)
            @c CImGui.InputFloat("center x", &x, 0.01)
            @c CImGui.InputFloat("center y", &y, 0.01)
            x = Float64(x)
            y = Float64(y)
            c = clamp(x, 0, 1)
            y = clamp(y, 0, 1)
            sprite.center = Vector2f(x, y)
        elseif fieldString == "color"
            sprite.color = edit_color("SpriteColor#1", sprite.color)
        else
            show_component_field_input(sprite, field, "")
        end  
    end
end

function edit_color(label::String, color::NTuple{4, Int})
    colorCfloat = Cfloat[color[1]/255, color[2]/255, color[3]/255, color[4]/255]

    @cstatic alpha_preview=true alpha_half_preview=true drag_and_drop=true options_menu=true hdr=false begin
        show_help_marker("Right-click on the individual color widget to show options.")
        CImGui.SameLine()

        misc_flags = (hdr ? CImGui.ImGuiColorEditFlags_HDR : 0) |
                     (drag_and_drop ? 0 : CImGui.ImGuiColorEditFlags_NoDragDrop) |
                     (alpha_half_preview ? CImGui.ImGuiColorEditFlags_AlphaPreviewHalf : 
                     (alpha_preview ? CImGui.ImGuiColorEditFlags_AlphaPreview : 0)) |
                     (options_menu ? 0 : CImGui.ImGuiColorEditFlags_NoOptions) |
                     CImGui.ImGuiColorEditFlags_AlphaBar

        CImGui.ColorEdit4(label, colorCfloat, CImGui.ImGuiColorEditFlags_DisplayRGB | misc_flags)

        if CImGui.IsItemEdited()
            return (Int(abs(round(colorCfloat[1] * 255))), 
                    Int(abs(round(colorCfloat[2] * 255))), 
                    Int(abs(round(colorCfloat[3] * 255))), 
                    Int(abs(round(colorCfloat[4] * 255))))
        end
    end

    return color  # Return original color if not edited
end


"""
    show_textbox_fields(textbox)

Iterates over the fields of the `textbox` object and displays input fields for each field.
If the field is `fontPath`, it displays an input text field for the font path, a button to load the font,
and updates the `sprite.fontPath` field with the current text in the text box.

# Arguments
- `textbox`: The textbox component to display the fields for.

"""
function show_textbox_fields(textbox)
    for field in fieldnames(typeof(textbox))
        fieldString = "$(field)"

        if fieldString == "fontPath"
            nameToDisplay = textbox.fontPath == joinpath("FiraCode-Regular.ttf") ? "Default: FiraCode-Regular.ttf" : textbox.fontPath
            CImGui.Text("Current font: $(nameToDisplay)")

            basePath = joinpath(BasePath, "assets", "fonts")
            fontPath = joinpath(strip(String(textbox.fontPath)))
            if strip(String(textbox.fontPath)) == "" || joinpath(strip(String(textbox.fontPath))) == joinpath("FiraCode-Regular.ttf")
                fontPath = joinpath("FiraCode-Regular.ttf")
            end
            fontMenuValue = display_files(joinpath(JulGame.BasePath, "assets", "fonts"), "fonts"; default="FiraCode-Regular")
            if fontMenuValue != ""
                if fontMenuValue == "Default"
                    fontMenuValue = joinpath("FiraCode-Regular.ttf")
                end

                # remove joinpath("assets", "fonts") from fontMenuValue and set it to fontPath
                fontPath = replace(fontMenuValue, joinpath(JulGame.BasePath, "assets", "fonts") => "")
                # remove leading / or \\ from fontPath
                if fontPath[1] == '/' || fontPath[1] == '\\'
                    fontPath = fontPath[2:end]
                end

                textbox.fontPath = fontPath
                UI.load_font(textbox, basePath, fontPath)
            end 
        else 
            show_textbox_fields(textbox, field)
        end  
    end
end

function show_screenbutton_fields1(screenButton)
    for field in fieldnames(typeof(screenButton))
        fieldString = "$(field)"

        # TODO: if fieldString == "fontPath" || 
        if fieldString == "buttonUpSpritePath" || fieldString == "buttonDownSpritePath"
            CImGui.Text("$(getfield(screenButton, Symbol(fieldString)))")

            if fieldString == "fontPath"
                # TODO: CImGui.Button("Load Font") && (UI.load_font(screenButton, joinpath(pwd()), joinpath("FiraCode-Regular.ttf")))
            elseif fieldString == "buttonUpSpritePath"
                imageMenuValue = display_files(joinpath(JulGame.BasePath, "assets", "images"), "images", "button up")
                if imageMenuValue != ""
                    @debug String("loading button up: $imageMenuValue")
                    # remove joinpath("assets", "images") from imageMenuValue and set it to imagePath
                    imagePath = replace(imageMenuValue, joinpath(JulGame.BasePath, "assets", "images") => "")
                    # remove leading / or \\ from imagePath
                    if imagePath[1] == '/' || imagePath[1] == '\\'
                        imagePath = imagePath[2:end]
                    end

                    UI.load_button_sprite_editor(screenButton, imagePath, true)
                end 
            elseif fieldString == "buttonDownSpritePath"
                imageMenuValue = display_files(joinpath(JulGame.BasePath, "assets", "images"), "images", "button down")
                if imageMenuValue != ""
                    @debug String("loading button up: $imageMenuValue")
                    # remove joinpath("assets", "images") from imageMenuValue and set it to imagePath
                    imagePath = replace(imageMenuValue, joinpath(JulGame.BasePath, "assets", "images") => "")
                    # remove leading / or \\ from imagePath
                    if imagePath[1] == '/' || imagePath[1] == '\\'
                        imagePath = imagePath[2:end]
                    end

                    UI.load_button_sprite_editor(screenButton, imagePath, false)
                end 
            end
        else 
            show_screenbutton_fields(screenButton, field)
        end  
    end
end

"""
    show_sound_source_fields(soundSource)

Display the fields of a `soundSource` object and provide user input for each field.

# Arguments
- `soundSource`: The sound source object to display and edit.

"""
function show_sound_source_fields(soundSource)
    for field in fieldnames(typeof(soundSource))
        fieldString = "$(field)"

        if fieldString == "path"
            CImGui.Text("Sound: $(soundSource.path == "" ? "None" : soundSource.path)")

            soundMenuValue = display_files(joinpath(JulGame.BasePath, "assets", "sounds"), "sounds")
            if soundMenuValue != ""
                # remove joinpath("assets", "sounds") from soundMenuValue and set it to soundPath
                soundPath = replace(soundMenuValue, joinpath(JulGame.BasePath, "assets", "sounds") => "")
                # remove leading / or \\ from soundPath
                if soundPath[1] == '/' || soundPath[1] == '\\'
                    soundPath = soundPath[2:end]
                end

                soundSource.path = soundPath
                Component.load_sound(soundSource, soundPath, soundSource.isMusic)
            end
        else
            show_component_field_input(soundSource, field, "")
        end  
    end
end

"""
    is_a_julgame_component(field)

Check if the given `field` is a component of the JulGame library.

# Arguments
- `field`: The field to check.

# Returns
- `true` if the `field` is a component of the JulGame library, `false` otherwise.
"""
function is_a_julgame_component(field)
    return isa(field, JulGame.TransformModule.Transform) || isa(field, JulGame.SpriteModule.InternalSprite) || isa(field, JulGame.ColliderModule.InternalCollider) || isa(field, JulGame.RigidbodyModule.InternalRigidbody) || isa(field, JulGame.SoundSourceModule.InternalSoundSource) || isa(field, JulGame.AnimatorModule.InternalAnimator) || isa(field, JulGame.ShapeModule.InternalShape) || isa(field, JulGame.CircleColliderModule.InternalCircleCollider) || isa(field, JulGame.AnimationModule.Animation)
end

function create_new_script(name)
    path = joinpath(JulGame.BasePath, "scripts", "$(name).jl")
    touch(joinpath(path))
    file = open(path, "w")
        println(file, newScriptContent(name))
    close(file)

    SDL2.SDL_OpenURL("vscode://file/$(path)")
end

function show_script_editor(entity, newScriptText)
    if CImGui.TreeNode("Scripts")
        show_help_marker("Add a script here to run it on the entity.")
        text = text_input_single_line("Name", newScriptText) 
        CImGui.SameLine()
        if CImGui.Button("Create New Script")
            create_new_script(text)
            include(joinpath(JulGame.BasePath, "scripts", "$(text).jl"))
            newScript = Base.invokelatest(eval, Symbol(text))
            newScript = Base.invokelatest(newScript)
            newScript.parent = entity
            push!(entity.scripts, newScript)
        end
        
        script = display_files(joinpath(JulGame.BasePath, "scripts"), "scripts", "Add Script")
        if script != ""
            Base.include(JulGame.ScriptModule, joinpath(JulGame.BasePath, "scripts", "$(script).jl"))
            module_name = getfield(JulGame.ScriptModule, Symbol("$(script)Module"))
            constructor = Base.invokelatest(getfield, module_name, Symbol(script)) 
            newScript = Base.invokelatest(constructor)
            newScript.parent = entity
            push!(entity.scripts, newScript)
        end

        for i = eachindex(entity.scripts)
            scriptName = split("$(typeof(entity.scripts[i]))", ".")[end]
            if CImGui.TreeNode("$(i): $(scriptName)")
                if CImGui.Button("Open Script")
                    path = joinpath(JulGame.BasePath, "scripts", "$(scriptName).jl")
                    SDL2.SDL_OpenURL("vscode://file/$(path)")
                end

                if CImGui.Button("Reload $scriptName:$(i)")
                    include(joinpath(JulGame.BasePath, "scripts", "$(scriptName).jl"))
                    module_name = Base.invokelatest(eval, Symbol("$(scriptName)Module"))
                    constructor = Base.invokelatest(getfield, module_name, Symbol(scriptName)) 
                    entity.scripts[i] = Base.invokelatest(constructor)
                    entity.scripts[i].parent = entity
                end

                CImGui.Button("Delete $(i)") && (deleteat!(entity.scripts, i); return;)
                for field in fieldnames(typeof(entity.scripts[i]))
                    if field == :parent || !(fieldtype(typeof(entity.scripts[i]), field) <: EditorExport)
                        continue
                    end
                    if isdefined(entity.scripts[i], Symbol(field)) 
                        display_script_field_input(entity.scripts[i], field)
                    else 
                        init_undefined_field(entity.scripts[i], field)
                    end
                end

                CImGui.TreePop()
            end
        end
        CImGui.TreePop()
    end
end

function display_script_field_input(script, field)
    ftype = typeof(getproperty(script, field))
    if ftype == String
        buf = "$(getproperty(script, field))"*"\0"^(64)
        CImGui.InputText("$(field)", buf, length(buf))
        currentTextInTextBox = ""
        for characterIndex = eachindex(buf)
            if Int32(buf[characterIndex]) == 0 
                if characterIndex != 1
                    currentTextInTextBox = String(SubString(buf, 1, characterIndex-1))
                end
                break
            end
        end
        setproperty!(script, field, currentTextInTextBox)
    elseif ftype == Float64 || ftype == Float32
        x = ftype(getproperty(script, field))
        x = Cfloat(x)
        @c CImGui.InputFloat("$(field)", &x, 1)
        setproperty!(script, field, ftype(x))
    elseif ftype <: Int64 || ftype <: Int32 || ftype <: Int16 || ftype <: Int8
        x = ftype(getproperty(script, field))
        x = convert(Int32, x)
        @c CImGui.InputInt("$(field)", &x, 1)
        x = convert(ftype, x)
        setproperty!(script, field, x)
    elseif ftype == Bool
        x = getproperty(script, field)
        @c CImGui.Checkbox("$(field)", &x)
        setproperty!(script, field, x)
    end
end

function init_undefined_field(script, field)
    ftype = typeof(getproperty(script, field))
    if ftype == String
        setproperty!(script, field, "")
    elseif ftype <: Number
        setproperty!(script, field, 0)
    elseif ftype == Bool
        setproperty!(script, field, false)
    end
end

function scriptObj(name::String, fields::Array)
    () -> (name; fields)
end

mutable struct EditorExport{T}
    value::T

    # Inner constructor
    function EditorExport(value::T) where T
        return new{T}(value)  # Use `new` to construct the object
    end    
end

# Overload `getproperty` to access `value` transparently
function Base.getproperty(editor::EditorExport{T}, sym::Symbol) where T
    if sym === :value
        return getfield(editor, :value)  # Preserve direct access to `value`
    else
        return editor.value  # Redirect other accesses to `value`
    end
end

# Overload `setproperty!` to modify `value` transparently
function Base.setproperty!(editor::EditorExport{T}, sym::Symbol, new_value) where T
    if sym === :value
        setfield!(editor, :value, new_value)  # Directly update `value`
    else
        editor.value = new_value  # Redirect updates to `value`
    end
end 

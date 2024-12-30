abstract type Script end

function Base.getproperty(script::Script, property::Symbol)
    if isa(getfield(script, property), EditorExport)
        return getfield(script, property).value
    end

    return getfield(script, property)
end

function Base.setproperty!(script::Script, property::Symbol, value)
    field = findfirst(f->f==property, fieldnames(typeof(script)))

    if fieldtype(typeof(script), field) <: EditorExport
        setfield!(script, property, EditorExport(value))
    else
        setfield!(script, property, value)
    end
end

# TODO: Add a way to add custom fields to scripts
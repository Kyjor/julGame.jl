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

mutable struct Enum{T}
    states::Dict{Symbol,Union{T,Nothing}}
    current_state::Symbol
    current_value::T
end

function Enum{T}(pairs...) where T
    states = Dict{Symbol,Union{T,Nothing}}()
    first_state = nothing  # Track the first state added

    for (i, pair) in enumerate(pairs)
        if pair isa Pair  # If it's a key-value pair
            states[pair.first] = pair.second
        elseif pair isa Symbol  # If it's just a symbol, store as nothing
            states[pair] = nothing
        else
            error("Invalid entry: $pair. Must be Symbol or Pair{Symbol, T}")
        end

        if i == 1  # Capture the first state added
            first_state = pair isa Pair ? pair.first : pair
        end
    end

    if first_state === nothing
        error("StatefulEnum must have at least one state.")
    end

    return Enum{T}(states, first_state, states[first_state])
end

# Check if a state exists
has_state(se::Enum, state::Symbol) = haskey(se.states, state)

# Get value safely
function get_value(se::Enum{T}, state::Symbol) where T
    return get(se.states, state, nothing)
end

# Set value for a state
function set_value!(se::Enum{T}, state::Symbol, value::T) where T
    if haskey(se.states, state)
        se.states[state] = value
    else
        error("State $state does not exist in the enum")
    end
end

# Enable dot access (states.test)
function Base.getproperty(se::Enum{T}, key::Symbol) where T
    key === :states && return getfield(se, :states)  # Allow direct access to states field
    key === :current_state && return getfield(se, :current_state)  # Allow direct access to current_state field
    key === :current_value && return get(se.states, se.current_state, nothing)  # Fetch value of current state
    return get(se.states, key, nothing)  # Return state value (or nothing if not found)
end

# Enable dot assignment (states.test = "new_value")
function Base.setproperty!(se::Enum{T}, key::Symbol, value) where T
    if key === :states
        setfield!(se, :states, value)  # Allow modifying states dictionary
    elseif key === :current_state 
        setfield!(se, :current_state, value)  # Allow modifying current_state
    elseif haskey(se.states, key)
        se.states[key] = value  # Modify existing state
    else
        error("State $key does not exist in this enum")
    end
end
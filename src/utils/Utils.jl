
function CallSDLFunction(func::Function, args...)
    SDL2.SDL_ClearError()

    # Call SDL function and check for errors
    ret = func(args...)
    if (isa(ret, Number) && ret < 0) || ret == C_NULL
        @error "SDL Error: $(unsafe_string(SDL2.SDL_GetError())) 
        || with function $(func) 
        || with args $(args)" 

        Base.show_backtrace(stdout, catch_backtrace())
    end

    return ret
end
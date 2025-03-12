module ErrorLoggingModule
    using Dates

    export ErrorLogger
    mutable struct ErrorLogger
        condition
        errorStack::Vector{Any}
        task 

        function ErrorLogger()
            this = new()
            
            this.errorStack = Vector{Any}[]
            this.condition = Condition()
            this.task = nothing
            run_error_coroutine(this)
        
            return this
        end
    end

    export log_error

    """
        log_error(message::String, exception=nothing)

    Log an error message with timestamp and optional exception details.
    """
    function log_error(this::ErrorLogger, message::String, exception_stack::Union{Nothing, Base.ExceptionStack}=nothing)
        timestamp = Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS")
        # check for duplicate errors before pushing
        for (i, error) in enumerate(this.errorStack)
            if error.message == message
                this.errorStack[i] = (message = message, exception_stack = exception_stack)
                @debug "Error message already logged"
                return
            end
        end
        push!(this.errorStack, (message = message, exception_stack = exception_stack))
    end

    function run_error_coroutine(this::ErrorLogger)
        if this.task !== nothing
            @debug "Error logging coroutine already running"
            return
        end
        @debug "Starting error logging coroutine"
        this.task = @task begin
            try
                while true
                    if length(this.errorStack) > 0
                        error_message, exception_stack = pop!(this.errorStack)
                        if exception_stack !== nothing
                            for exception in exception_stack
                                print_error(this,error_message, exception)
                            end
                        end
                    end
        
                    wait(this.condition)
                end
            catch e
                @error "Error in logging coroutine: $e"
            end
        end
        schedule(this.task)
    end

    function print_error(this::ErrorLogger, e, exception)
        err_str = string(e)
        formatted_err = format_method_error(err_str)  # Format MethodError
        truncated_err = length(formatted_err) > 1500 ? formatted_err[1:1500] * "..." : formatted_err
        full_err_string = "Error occurred : $(e)\n"

        st = Base.stacktrace(exception.backtrace)
        # Format and print each frame
        actual_frames = 0
        for (i, frame) in enumerate(st)
            if  string(frame.file) != "./essentials.jl" && 
                #!contains(string(frame.file), "JulGame") && 
                string(frame.file) != "./client.jl" && 
                string(frame.file) != "./boot.jl" && 
                string(frame.file) != "./loading.jl" && 
                string(frame.file) != "./Base.jl" &&
                string(frame.file) != "./dict.jl"

                actual_frames += 1
                full_err_string *= "[$actual_frames] $(frame.func) at $(frame.file):$(frame.line)\n"
            end
            wait(this.condition)
        end
    
        @error full_err_string
    end

    function format_method_error(error_msg::String)
        # Match "MethodError(FUNCTION_NAME, (ARGUMENTS))"
        if occursin(r"MethodError\((.+?), \((.+)\)\)", error_msg)
            m = match(r"MethodError\((.+?), \((.+)\)\)", error_msg)
            func_name = m[1]
            args = m[2]
    
            # Separate top-level arguments while tracking nested depth
            depth = 0
            simplified_args = String[]
            current_arg = ""
    
            for char in args
                if char == '(' || char == '['
                    depth += 1
                elseif char == ')' || char == ']'
                    depth -= 1
                end
    
                if char == ',' && depth == 0
                    push!(simplified_args, strip(current_arg))
                    current_arg = ""
                else
                    current_arg *= char
                end
            end
            push!(simplified_args, strip(current_arg))  # Add last argument
    
            # Process each argument: keep type info, replace deep details with "(...)"
            for i in 1:length(simplified_args)
                arg = simplified_args[i]
    
                # Extract "Module.Type(...)" and replace details with "(...)"
                if occursin(r"(\w+\.)+\w+\(", arg)
                    simplified_args[i] = match(r"((\w+\.)+\w+)\(", arg)[1] * "(...)" 
    
                # Handle numbers: Convert to "Int" or "Float64"
                elseif occursin(r"^\d+\.?\d*$", arg)
                    try
                        parsed_num = Meta.parse(arg)
                        if isa(parsed_num, Integer)
                            simplified_args[i] = "Int"
                        elseif isa(parsed_num, AbstractFloat)
                            simplified_args[i] = "Float64"
                        end
                    catch
                        simplified_args[i] = "(...)"
                    end
                end
            end
    
            return "MethodError($func_name, (" * join(simplified_args, ", ") * "))"
        end

        return error_msg  # Return original if no match
    end
end
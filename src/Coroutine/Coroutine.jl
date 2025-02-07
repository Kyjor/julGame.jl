module CoroutineModule
    using ..JulGame

    export Coroutine
    mutable struct Coroutine
        condition
        task

        function Coroutine(condition = nothing)
            this = new()

            this.condition = condition

            return this
        end
    end

    function start_coroutine(this::Coroutine, func, params...)
        this.task = @task func(params...)
        schedule(this.task)

        push!(JulGame.Coroutines, this)
        this.condition = this.condition === nothing ? MAIN.coroutine_condition : Condition()

        return this
    end

    function start_coroutine(func, params...)
        this = Coroutine(MAIN.coroutine_condition)
        this.task = @task func(params...)
        schedule(this.task)

        push!(JulGame.Coroutines, this)

        return this
    end

    function wait_for_coroutine(this::Coroutine)
        wait(this.condition)
    end

    function wait_for_coroutine()
        wait(MAIN.coroutine_condition)
    end
end

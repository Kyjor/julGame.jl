module CoroutineModule
    using ..JulGame

    export Coroutine
    mutable struct Coroutine
        conditon
        task

        function Coroutine()
            this = new()

            this.conditon = Condition()
            
            return this
        end
    end

    function start_coroutine(this::Coroutine, func, params...)
        this.task = @task func(params...)
        schedule(this.task)

        return this
    end
end

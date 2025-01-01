module JulGameEditor
    include("../Editor.jl")
    
    function run()
       Editor.run()
    end

    julia_main() = run()
end
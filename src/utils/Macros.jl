module Macros
    export @event
    macro event(expr)
        esc(:(()->($expr)))
    end

    export @argevent
    macro argevent(args, expr)
        esc(:(($args)->($expr)))
    end
end
module LoggingModule
export start_logger, log_error

const error_channel = Channel{String}(10)
function producer(c::Channel)
    put!(c, "start")
    for n=1:4
        put!(c, 2n)
    end
    put!(c, "stop")
end

function start_logger()
    @async begin
        while true
            err_msg = take!(error_channel)
            println("Error on separate thread: ", err_msg)
        end
    end
end

function log_error(msg::String)
    put!(error_channel, msg)
end
end
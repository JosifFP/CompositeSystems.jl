Base.Broadcast.broadcastable(x::ResultSpec) = Ref(x)
Base.Broadcast.broadcastable(x::Result) = Ref(x)

include("shortfall.jl")
include("flow.jl")

function resultchannel(
    method::SimulationSpec, results::T, threads::Int
) where T <: Tuple{Vararg{ResultSpec}}

    types = accumulatortype.(method, results)
    return Channel{Tuple{types...}}(threads)

end

function merge!(xs::T, ys::T) where T <: Tuple{Vararg{ResultAccumulator}}
    #println("pegado foreach(merge!, xs, ys)")
    return foreach(merge!, xs, ys)
end

function finalize(
    results::Channel{<:Tuple{Vararg{ResultAccumulator}}},
    system::SystemModel{N,L,T,U},
    threads::Int
) where {N,L,T,U}

    total_result = take!(results)

    for _ in 2:threads
        thread_result = take!(results)
        #println("pegado merge!(total_result, thread_result)")
        merge!(total_result, thread_result)
    end
    close(results)

    return finalize.(total_result, system)

end

Base.Broadcast.broadcastable(x::ResultSpec) = Ref(x)
Base.Broadcast.broadcastable(x::Result) = Ref(x)

include("shortfall.jl")
include("availability.jl")
include("flow.jl")


function resultchannel(
    method::SimulationSpec, results::T, threads::Int
) where T <: Tuple{Vararg{ResultSpec}}

    types = accumulatortype.(method, results)
    return Channel{Tuple{types...}}(threads)

end

merge!(xs::T, ys::T) where T <: Tuple{Vararg{ResultAccumulator}} =
    foreach(merge!, xs, ys)

function finalize(
    results::Channel{<:Tuple{Vararg{ResultAccumulator}}},
    system::SystemModel{N,L,T,U}
) where {N,L,T,U}

    total_result = take!(results)
    close(results)

    return finalize.(total_result, system)

end

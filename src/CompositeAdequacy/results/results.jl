Base.broadcastable(x::ResultSpec) = Ref(x)
Base.broadcastable(x::Result) = Ref(x)

include("shortfall.jl")
include("availability.jl")
include("utilization.jl")

""
function resultchannel(
    method::SimulationSpec, 
    results::T, 
    threads::Int) where T <: Tuple{Vararg{ResultSpec}}

    types = accumulatortype.(method, results)

    return Channel{Tuple{types...}}(threads)
end

""
function resultchannel(
    method::SimulationSpec, 
    results::ResultSpec, 
    threads::Int)

    types = accumulatortype.(method, results)

    return Channel{Tuple{types...}}(threads)
end

""
function resultremotechannel(
    method::SimulationSpec, 
    results::T,
    workers::Int
    )  where T <: Tuple{Vararg{ResultSpec}}

    types = accumulatortype.(method, results)

    return Distributed.RemoteChannel(()->Channel{Tuple{types...}}(workers))
end

""
function resultremotechannel(
    method::SimulationSpec, 
    results::ResultSpec,
    workers::Int
    )

    types = accumulatortype.(method, results)

    return Distributed.RemoteChannel(()->Channel{types}(workers))
end

merge!(xs::T, ys::T) where T <: Tuple{Vararg{ResultAccumulator}} = foreach(merge!, xs, ys)

""
function merge!(
    xs::RemoteChannel{Channel{T}}, 
    ys::Channel{T}
) where {T <: Tuple{Vararg{ResultAccumulator}}}
    
    while !isempty(ys)
        y = take!(ys)
        put!(xs, y)
    end
    close(ys)
end

""
function finalize!(
    results::Channel{R}, 
    system::SystemModel{N,L,T}, 
    threads::Int) where {N,L,T, R <: Tuple{Vararg{ResultAccumulator}}}

    total_result = take!(results)

    for _ in 2:threads
        thread_result = take!(results)
        merge!(total_result, thread_result)
    end

    close(results)
    return finalize.(total_result, system)
end

""
function finalize!(
    results::RemoteChannel{Channel{R}}, 
    system::SystemModel{N,L,T},
    workers::Int) where {N,L,T, R <: Tuple{Vararg{ResultAccumulator}}}

    total_result = take!(results)

    for _ in 2:workers
        worker_result = take!(results)
        merge!(total_result, worker_result)
    end
    close(results)
    return finalize.(total_result, system)
end

""
function take_Results!(
    results::Channel{R}, 
    threads::Int) where { R <: Tuple{Vararg{ResultAccumulator}}}

    total_result = take!(results)

    for _ in 2:threads
        thread_result = take!(results)
        merge!(total_result, thread_result)
    end

    close(results)
    return total_result
end

""
function finalize!(
    results::RemoteChannel{Channel{R}}, 
    system::SystemModel{N,L,T},
    workers::Int) where {N,L,T, R <: ResultAccumulator}

    total_result = take!(results)

    for _ in 2:workers
        worker_result = take!(results)
        merge!(total_result, worker_result)
    end
    close(results)
    return finalize.(total_result, system)
end

""
function take_Results!(
    results::Channel{R}, 
    threads::Int) where { R <: ResultAccumulator}

    total_result = take!(results)

    for _ in 2:threads
        thread_result = take!(results)
        merge!(total_result, thread_result)
    end

    close(results)
    return total_result
end
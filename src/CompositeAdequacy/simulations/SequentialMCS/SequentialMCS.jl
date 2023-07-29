include("utils.jl")

"""
This code snippet is using multi-threading and distributed computing to parallelize 
the assess function by running multiple instances of it simultaneously on different threads
and machines. The Threads.@spawn macro is used to create new threads, each of which will execute 
the assess function using a different seed from the sampleseeds channel. The results of each 
thread are stored in the results channel, and the function finalize is called on the results
after all threads have finished executing.
"""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    resultspecs::ResultSpec...
) where {N}

    #Number of workers excluding the master process
    nworkers = Distributed.nprocs()
    nthreads = method.threaded ? Base.Threads.nthreads() : 1
    
    # Use RemoteChannel for distributed computing
    results = resultremotechannel(method, resultspecs, nworkers)

    # Compute on worker processes
    if nworkers > 1
        @info("CompositeSystems will distribute the workload across $(nworkers) nodes")

        @sync begin
            @async begin
                # Compute on the master process/worker
                master_result = assess_slave(system, method, settings, nworkers, nthreads, 1, resultspecs...)
                put!(results, master_result)
            end

            for k in 2:nworkers
                @async begin
                    result = fetch(Distributed.pmap(
                        i -> assess_slave(system, method, settings, nworkers, nthreads, i, resultspecs...), k))
                    put!(results, result)
                end
            end
        end
    else
        # In case there is only one worker, just run the master process
        master_result = assess_slave(system, method, settings, nworkers, nthreads, 1, resultspecs...)
        put!(results, master_result)
    end

    return finalize(results, system, nworkers)
end

"""
This code snippet is using multi-threading to parallelize the assess function by running 
multiple instances of it simultaneously on different threads. The Threads.@spawn macro is 
used to create new threads, each of which will execute the assess function using a different 
seed from the sampleseeds channel. The results of each thread are stored in the results channel, 
and the function finalize is called on the results after all threads have finished executing.
"""
function assess_single(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    resultspecs::ResultSpec...
) where {N}

    nthreads = method.threaded ? Base.Threads.nthreads() : 1
    sampleseeds = Channel{Int}(2*nthreads)
    results = resultchannel(method, resultspecs, nthreads)
    Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:nthreads
            Threads.@spawn assess(system, method, settings, sampleseeds, results, resultspecs...)
        end
    else
        assess(system, method, settings, sampleseeds, results, resultspecs...)
    end
    
    #return finalize(results, system, threads)
    return take_Results!(results, nthreads)
end

"Distributed computing version of 'assess' function.
Return results as an accumulator that needs to be merged into other worker' accumulators"
function assess_slave(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    nworkers::Int,
    nthreads::Int,
    worker::Int,
    resultspecs::ResultSpec...
) where {N}

    settings.optimizer === nothing && __init__()
    sampleseeds = Channel{Int}(2*nthreads)
    results = resultchannel(method, resultspecs, nthreads)
    nsamples_per_worker = div(method.nsamples, nworkers)
    start_index = (worker - 1) * nsamples_per_worker + 1
    end_index = min(worker * nsamples_per_worker, method.nsamples)
    Threads.@spawn CompositeAdequacy.makeseeds(sampleseeds, start_index, end_index)

    if method.threaded
        for _ in 1:nthreads
            Threads.@spawn CompositeAdequacy.assess(system, method, settings, sampleseeds, results, resultspecs...)
        end
    else
        CompositeAdequacy.assess(system, method, settings, sampleseeds, results, resultspecs...)
    end
    
    return take_Results!(results, nthreads)
end

"""
This assess function is designed to perform a Monte Carlo simulation using the Sequential Monte 
Carlo (SMC) method. The function uses the pm variable to store an abstract model of the system, 
and the StateTransition variables to store the system's states. It also creates several recorders 
using the accumulator function, and an RNG (random number generator) of type Philox4x. The function 
then iterates over the sampleseeds channel, using each seed to initialize the RNG and the system states, 
and performs the Monte Carlo simulation for each sample.
The results of each thread are stored in the results channel using the put! function. 
After all the threads have finished executing, the finalize function is called on the 
results to process the results and return the final result.
"""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    sampleseeds::Channel{Int},
    results::Union{R, Distributed.RemoteChannel{R}},
    resultspecs::ResultSpec...
) where {N, R <: Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}}}

    pm = settings.optimizer === nothing ? abstract_model(system, settings, GRB_ENV[]) : abstract_model(system, settings, nothing)

    statetransition = StateTransition(system)
    build_problem!(pm, system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, statetransition, pm.topology, system) #creates the up/down sequence for each device.

        for t in 1:N
            update!(rng, statetransition, pm.topology, system, t)
            solve!(pm, system, settings, t)
            foreach(recorder -> record!(recorder, pm.topology, system, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
        settings.count_samples && @info("sample = $(s)")
    end

    Base.finalize(JuMP.backend(pm.model).optimizer)
    put!(results, recorders)
    return results
end

"""
The initialize! function creates an initial state of the system by using the Philox4x 
random number generator to randomly determine the availability of different assets 
(buses, branches, common branches, generators, and storages) for each time step.
"""
function initialize!(rng::AbstractRNG, 
    statetransition::StateTransition, topology::Topology, system::SystemModel{N}) where N

    initialize_availability!(rng, statetransition.branches_available, 
        statetransition.branches_nexttransition, system.branches, N)

    initialize_availability!(rng, statetransition.commonbranches_available, 
        statetransition.commonbranches_nexttransition, system.commonbranches, N) 
    
    initialize_availability!(rng, statetransition.generators_available, 
        statetransition.generators_nexttransition, system.generators, N)

    initialize_availability!(rng, statetransition.storages_available, 
        statetransition.storages_nexttransition, system.storages, N)    

    OPF.update_states!(topology, statetransition)
    return
end

"The function update! updates the system states for a given time step t."
function update!(rng::AbstractRNG, 
    statetransition::StateTransition, topology::Topology, system::SystemModel{N}, t::Int) where N
    
    update_availability!(rng, statetransition.branches_available, 
        statetransition.branches_nexttransition, system.branches, t, N)
    
    update_availability!(rng, statetransition.commonbranches_available, 
        statetransition.commonbranches_nexttransition, system.commonbranches, t, N)

    update_availability!(rng, statetransition.generators_available, 
        statetransition.generators_nexttransition, system.generators, t, N)

    update_availability!(rng, statetransition.storages_available, 
        statetransition.storages_nexttransition, system.storages, t, N)

    OPF.update_states!(topology, statetransition, t)
    #apply_common_outages!(topology, system.branches, t)
    return
end

include("result_shortfall.jl")
include("result_availability.jl")
include("result_utilization.jl")
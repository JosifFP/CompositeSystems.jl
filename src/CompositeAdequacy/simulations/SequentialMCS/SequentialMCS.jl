include("utils.jl")

"""
This code snippet is using multi-threading to parallelize the assess function by running multiple instances of it simultaneously on different threads.
The Threads.@spawn macro is used to create new threads, each of which will execute the assess function using a different seed from the sampleseeds channel. 
The results of each thread are stored in the results channel, and the function finalize is called on the results after all threads have finished executing.
"""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    resultspecs::ResultSpec...
) where {N}

    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            Threads.@spawn assess(system, method, settings, sampleseeds, results, resultspecs...)
        end
    else
        assess(system, method, settings, sampleseeds, results, resultspecs...)
    end

    return finalize(results, system, method.threaded ? threads : 1)
    
end

"""
This assess function is designed to perform a Monte Carlo simulation using the Sequential Monte Carlo (SMC) method.
The function uses the pm variable to store an abstract model of the system, and the systemstates variable to store the system's states. 
It also creates several recorders using the accumulator function, and an RNG (random number generator) of type Philox4x.
The function then iterates over the sampleseeds channel, using each seed to initialize the RNG and the system states, 
and performs the Monte Carlo simulation for each sample.
"""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}},
    resultspecs::ResultSpec...
) where {N}

    pm = abstract_model(system, settings)
    systemstates = SystemStates(system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    for s in sampleseeds
        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize_states!(rng, systemstates, system) #creates the up/down sequence for each device.

        if OPF.is_empty(pm.model.moi_backend)
            initialize_powermodel!(pm, system, systemstates)
        end

        for t in 1:N
            #println("t=$(t)")
            update!(pm, system, systemstates, settings, t)
            foreach(recorder -> record!(recorder, systemstates, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
        reset_model!(pm, system, systemstates, settings, s)
        
    end

    put!(results, recorders)

end

"""
The initialize_states! function creates an initial state of the system by using the Philox4x random number generator to randomly determine the availability 
of different assets (buses, branches, common branches, generators, and storages) for each time step.
"""
function initialize_states!(rng::AbstractRNG, states::SystemStates, system::SystemModel{N}) where N

    singlestates = NextTransition(system)
    initialize_all_states!(rng, states, singlestates, system)

    for t in 2:N
        @inbounds @fastmath update_all_states!(rng, states, singlestates, system, t)
    end
    initialize_availability!(field(states, :buses), field(system, :buses), N)
    return
end

""
function initialize_powermodel!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates)
    build_method!(pm, system, 1)
    return
end

"The function update! updates the system states and power model for a given time step t. 
It does this by first updating the topology of the system with the function update_topology!, 
then updating the method and power model with update_method!, and finally optimizing the method with optimize_method!"
function update!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, settings::Settings, t::Int)
    update_topology!(pm, system, states, settings, t)
    update_method!(pm, system, states, t)
    optimize_method!(pm, system, states, t)
    return
end

include("result_shortfall.jl")
include("result_availability.jl")
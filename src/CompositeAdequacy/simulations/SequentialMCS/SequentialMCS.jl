include("utils.jl")

"""
This code snippet is using multi-threading to parallelize the assess function by running 
multiple instances of it simultaneously on different threads. The Threads.@spawn macro is 
used to create new threads, each of which will execute the assess function using a different 
seed from the sampleseeds channel. The results of each thread are stored in the results channel, 
and the function finalize is called on the results after all threads have finished executing.
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
This assess function is designed to perform a Monte Carlo simulation using the Sequential Monte 
Carlo (SMC) method. The function uses the pm variable to store an abstract model of the system, 
and the States variable to store the system's states. It also creates several recorders 
using the accumulator function, and an RNG (random number generator) of type Philox4x. The function 
then iterates over the sampleseeds channel, using each seed to initialize the RNG and the system states, 
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
    state = States(system)
    statetransition = StateTransition(system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        settings.count_samples && println("s=$(s)")
        OPF.is_empty(pm.model.moi_backend) && build_problem!(pm, system) #This function MUST be placed below the sampleseeds loop.
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, state, statetransition, system) #creates the up/down sequence for each device.

        for t in 1:N
            update!(rng, state, statetransition, system, t)
            solve!(pm, state, system, settings, t)
            foreach(recorder -> record!(recorder, state, system, s, t), recorders)
            # if s==3 && (t==2659 || t==2658)
            #     println("t=$(t), 
            #     state.buses_cap_curtailed_p=$(state.buses_cap_curtailed_p), 
            #     state.branches_available=$(state.branches_available), 
            #     statetransition.branches_available=$(statetransition.branches_available),
            #     state.buses_available=$(state.buses_available)")
            #     println(pm.model)
            # end
        end

        foreach(recorder -> reset!(recorder, s), recorders)
        reset_model!(pm, settings, s, method.nsamples)
    end

    put!(results, recorders)
end

"""
The initialize! function creates an initial state of the system by using the Philox4x 
random number generator to randomly determine the availability of different assets 
(buses, branches, common branches, generators, and storages) for each time step.
"""
function initialize!(
    rng::AbstractRNG, states::States, statetransition::StateTransition, system::SystemModel{N}) where N

    initialize_availability!(rng, statetransition.branches_available, 
        statetransition.branches_nexttransition, system.branches, N)

    initialize_availability!(rng, statetransition.commonbranches_available, 
        statetransition.commonbranches_nexttransition, system.commonbranches, N)
    
    initialize_availability!(rng, statetransition.generators_available, 
        statetransition.generators_nexttransition, system.generators, N)

    initialize_availability!(rng, statetransition.storages_available, 
        statetransition.storages_nexttransition, system.storages, N)

    update_other_states!(states, statetransition, system, sampleid=1)

    return
end

"The function update! updates the system states for a given time step t. 
It updates the topology of the system with the function update_topology!, 
then updates the method and power model with update_problem!"
function update!(
    rng::AbstractRNG, states::States, statetransition::StateTransition, system::SystemModel{N}, t::Int) where N
    
    update_availability!(rng, statetransition.branches_available, 
        statetransition.branches_nexttransition, system.branches, t, N)
    
    update_availability!(rng, statetransition.commonbranches_available, 
        statetransition.commonbranches_nexttransition, system.commonbranches, t, N)

    update_availability!(rng, statetransition.generators_available, 
        statetransition.generators_nexttransition, system.generators, t, N)

    update_availability!(rng, statetransition.storages_available, 
        statetransition.storages_nexttransition, system.storages, t, N)

    update_other_states!(states, statetransition, system)
    #apply_common_outages!(states, system.branches, t)

    return
end

"""
Optimizes the power model and update the system states based on the results of the optimization. 
The function first checks if there are any changes in the branch, storage, or generator states at time step t 
compared to the previous time step. If there are any changes, the function calls JuMP.optimize!(pm.model) 
to optimize the power model and then calls optimize_model! to update the results. 
If there are no changes, it fills the states.buses_cap_curtailed_p variable with zeros.
"""
function solve!(
    pm::AbstractPowerModel, 
    states::States, system::SystemModel{N}, settings::Settings, t::Int) where N

    update_topology!(pm, system, states, settings, t)

    update_container!(states.stored_energy, states.storages_available, system.storages)

    update_problem!(pm, system, states, t)

    changes = !all([states.branches_available; states.generators_available; states.storages_available])
    
    changes && JuMP.optimize!(pm.model)

    build_result!(pm, system, states, settings, t; changes=changes)

    record_other_states!(states, system)

    return
end

include("result_shortfall.jl")
include("result_availability.jl")
include("result_utilization.jl")
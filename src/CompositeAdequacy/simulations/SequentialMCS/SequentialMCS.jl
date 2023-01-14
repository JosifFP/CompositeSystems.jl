include("utils.jl")

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

""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}},
    resultspecs::ResultSpec...
) where {N}

    model = jump_model(settings.modelmode, settings.optimizer)
    pm = abstract_model(settings.powermodel, Topology(system), model)
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

        for t in 2:N
            update!(pm, system, systemstates, t)
            foreach(recorder -> record!(recorder, systemstates, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
        reset_model!(pm, systemstates, settings, s)
        
    end

    put!(results, recorders)

end

""
function initialize_states!(rng::AbstractRNG, states::SystemStates, system::SystemModel{N}; transitions::Bool=true) where N

    if transitions == false
        #initialize_availability!(field(states, :buses), field(system, :buses), N)
        initialize_availability!(rng, field(states, :branches), field(system, :branches), N)
        initialize_availability!(rng, field(states, :commonbranches), field(system, :commonbranches), N)
        initialize_availability!(rng, field(states, :generators), field(system, :generators), N)
        initialize_availability!(rng, field(states, :storages), field(system, :storages), N)
    else
        singlestates = NextTransition(system)
        initialize_availability!(rng, singlestates.branches_available, singlestates.branches_nexttransition, system.branches, N)
        initialize_availability!(rng, singlestates.commonbranches_available, singlestates.commonbranches_nexttransition, system.commonbranches, N)
        initialize_availability!(rng, singlestates.generators_available, singlestates.generators_nexttransition, system.generators, N)
        initialize_availability!(rng, singlestates.storages_available, singlestates.storages_nexttransition, system.storages, N)

        for t in 1:N
            update_availability!(rng, singlestates.branches_available, singlestates.branches_nexttransition, system.branches, t, N)
            update_availability!(rng, singlestates.commonbranches_available, singlestates.commonbranches_nexttransition, system.commonbranches, t, N)
            update_availability!(rng, singlestates.generators_available, singlestates.generators_nexttransition, system.generators, t, N)
            update_availability!(rng, singlestates.storages_available, singlestates.storages_nexttransition, system.storages, t, N)
            view(field(states, :branches),:,t) .= singlestates.branches_available[:]
            view(field(states, :commonbranches),:,t) .= singlestates.commonbranches_available[:]
            view(field(states, :generators),:,t) .= singlestates.generators_available[:]
            view(field(states, :storages),:,t) .= singlestates.storages_available[:]
            apply_common_outages!(states, system, t)
        end
        initialize_availability!(field(states, :buses), field(system, :buses), N)
    end
    return
end

""
function initialize_powermodel!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates; results::Bool=false)

    initialize_pm_containers!(pm, system; timeseries=false)
    build_method!(pm, system, 1)
    JuMP.optimize!(pm.model)
    results == true && build_result!(pm, system, states, 1)
    return

end

""
function update!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    
    update_topology!(pm, system, states, t)
    update_method!(pm, system, states, t)
    JuMP.optimize!(pm.model)
    build_result!(pm, system, states, t)
    return

end

#include("result_report.jl")
include("result_shortfall.jl")

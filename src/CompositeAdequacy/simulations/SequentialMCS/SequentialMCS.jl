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
            Threads.@spawn assess(system, method, deepcopy(settings), sampleseeds, results, resultspecs...)
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

    topology = Topology(system)
    model = OPF.JumpModel(settings.modelmode, deepcopy(settings.optimizer))
    pm = PowerModel(settings.powermodel, topology, model)
    systemstates = SystemStates(system)

    initialize_powermodel!(pm, system)
    recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
    rng = Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE

    for s in sampleseeds
        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize_states!(rng, systemstates, system) #creates the up/down sequence for each device.

        for t in 2:N
            if systemstates.system[t] ≠ true
                update_model!(pm, system, systemstates, t)
            end
            foreach(recorder -> record!(recorder, pm, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
        reset_model!(pm, system, settings, s)
    end

    put!(results, recorders)

end

""
function initialize_states!(rng::AbstractRNG, states::SystemStates, system::SystemModel{N}) where N

    initialize_availability!(rng, field(states, :branches), field(system, :branches), N)
    initialize_availability!(rng, field(states, :generators), field(system, :generators), N)
    initialize_availability!(rng, field(states, :storages), field(system, :storages), N)
    initialize_availability!(rng, field(states, :generatorstorages), field(system, :generatorstorages), N)
    initialize_availability_system!(states, field(system, :generators), field(system, :loads), N)

    return

end

""
function initialize_powermodel!(pm::AbstractPowerModel, system::SystemModel)

    initialize_pm_containers!(pm, system; timeseries=false)
    build_method!(pm, system, 1)
    optimize_method!(pm)
    build_result!(pm, system, 1)

end


""
function update_model!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    #update_idxs!(filter(i->BaseModule.field(states, :shunts, i, t), field(system, :shunts, :keys)), topology(pm, :shunts_idxs))    
    #update_idxs!(filter(i->BaseModule.field(states, :generators, i, t), field(system, :generators, :keys)), topology(pm, :generators_idxs))
    update_idxs!(filter(i->BaseModule.field(states, :branches, i, t), field(system, :branches, :keys)), topology(pm, :branches_idxs))    
    update_method!(pm, system, states, t)
    OPF.optimize!(pm.model)
    build_result!(pm, system, t)
    return

end

""
function solve!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    build_method!(pm, system, states, t)
    optimize_method!(pm)
    build_result!(pm, system, t)
    return

end


#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

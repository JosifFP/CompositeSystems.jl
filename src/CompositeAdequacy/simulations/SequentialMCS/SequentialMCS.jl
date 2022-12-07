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

    systemstates = SystemStates(system)
    model = JumpModel(settings.modelmode, deepcopy(settings.optimizer))
    pm = PowerModel(settings.powermodel, Topology(system), model)

    #model for non-contingency states
    #ncmodel = JumpModel(settings.modelmode, deepcopy(settings.optimizer))
    #ncpm = PowerModel(settings.powermodel, Topology(system), ncmodel)

    recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
    rng = Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE

    for s in sampleseeds
        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize_states!(rng, systemstates, system) #creates the up/down sequence for each device.

        if OPF.is_empty(pm.model.moi_backend)
            initialize_powermodel!(pm, system, systemstates)
        end

        for t in 2:N
            #println("t=$(t)")
            update!(pm, system, systemstates, t)
            resolve!(pm, system, systemstates, t)
            foreach(recorder -> record!(recorder, systemstates, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
        reset_model!(pm, systemstates, settings, s)
        
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
function initialize_powermodel!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates; results::Bool=false)

    initialize_pm_containers!(pm, system; timeseries=false)

    if length(system.storages) > 0
        build_method_stor!(pm, system, states, 1)
    else
        build_method!(pm, system, states, 1)
    end
    
    optimize_method!(pm)

    if results == true
        build_result!(pm, system, states, 1)
    end

end

""
function update!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
        
    #update_idxs!(filter(i->BaseModule.field(states, :generators, i, t), field(system, :generators, :keys)), topology(pm, :generators_idxs))
    #update_idxs!(filter(i->BaseModule.field(states, :shunts, i, t), field(system, :shunts, :keys)), topology(pm, :shunts_idxs)) 
    update_idxs!(filter(i->BaseModule.field(states, :branches, i, t), field(system, :branches, :keys)), topology(pm, :branches_idxs))

    #if all(view(field(states, :branches),:,t)) == false 
        #simplify!(system, states, pm.topology, t)
    #end
    # update_idxs!(filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), topology(pm, :buses_idxs))
    return

end

function resolve!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    update_method!(pm, system, states, t)
    optimize_method!(pm)
    build_result!(pm, system, states, t)
    
    return

end

""
function solve!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    build_method!(pm, system, states, t)
    optimize_method!(pm)
    build_result!(pm, system, states, t)
    return

end


#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

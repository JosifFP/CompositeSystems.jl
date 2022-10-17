include("utils.jl")
include("systemstates.jl")

function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    resultspecs::ResultSpec...
) where {N}

    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    
    Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            Threads.@spawn assess(deepcopy(system), method, sampleseeds, results, resultspecs...)
        end
    else
        assess(system, method, sampleseeds, results, resultspecs...)
    end

    return finalize(results, system, method.threaded ? threads : 1)
    
end

""
function assess(
    system::SystemModel{N}, 
    method::SequentialMCS,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}},
    resultspecs::ResultSpec...
) where {N}

    systemstates = SystemStates(system, method)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    system::SystemModel{N}, 
    for s in sampleseeds
        println("s=$(s)")
        pm = PowerFlowProblem(AbstractDCOPF, Model(method.optimizer; add_bridges = false) , Topology(system))
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstates, system) #creates the up/down sequence for each device.

        for t in 1:N
            if field(systemstates, :condition)[t] ≠ true
                update!(field(pm, :topology), systemstates, system, t)
                solve!(pm, systemstates, system, t)
                empty_model!(pm)
            end
            #foreach(recorder -> record!(recorder, system, pm, s, t), recorders)
        end
        foreach(recorder -> record!(recorder, system, pm, s), recorders)
        foreach(recorder -> reset!(recorder, s), recorders)
    end

    put!(results, recorders)

end

""
function initialize!(rng::AbstractRNG, states::SystemStates, system::SystemModel{N}) where N

    initialize_availability!(rng, field(states, :branches), field(system, :branches), N)
    initialize_availability!(rng, field(states, :generators), field(system, :generators), N)
    initialize_availability!(rng, field(states, :storages), field(system, :storages), N)
    initialize_availability!(rng, field(states, :generatorstorages), field(system, :generatorstorages), N)
    
    for t in 1:N
        if all([field(states, :branches)[:,t]; field(states, :generators)[:,t]; field(states, :storages)[:,t]; field(states, :generatorstorages)[:,t]]) ≠ true
            field(states, :condition)[t] = 0 
        end
    end

    return

end

""
function solve!(pm::AbstractPowerModel, states::SystemStates, system::SystemModel, t::Int)

    #all(field(states, :branches)[:,t]) == true ? type = Transportation : type = DCOPF
    type = DCOPF
    build_method!(pm, system, t, type)
    optimize!(pm.model)
    build_result!(pm, system, t)
end

""
function update!(topology::Topology, states::SystemStates, system::SystemModel, t::Int)

    #update_statess!(system, states, t)
    if field(states, :condition)[t] ≠ true
        
        key_buses = field(system, Buses, :keys)

        update_asset_idxs!(
            topology, field(system, :loads), field(states, :loads), key_buses, t)

        update_asset_idxs!(
            topology, field(system, :shunts), field(states, :shunts), key_buses, t)

        update_asset_idxs!(
            topology, field(system, :generators), field(states, :generators), key_buses, t)

        update_asset_idxs!(
            topology, field(system, :storages), field(states, :storages), key_buses, t)

        update_asset_idxs!(
            topology, field(system, :generatorstorages), field(states, :generatorstorages), key_buses, t)

        update_branch_idxs!(
            topology, system, field(states, :branches), key_buses, t)

    end

    return

end

""
function empty_model!(pm::AbstractPowerModel)

    #if isempty(pm.model)==false empty!(pm.model) end
    empty!(pm.model)
    empty!(pm.var[:va])
    empty!(pm.var[:pg])
    empty!(pm.var[:p])
    empty!(pm.var[:plc])
    return
end

#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

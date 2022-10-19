include("utils.jl")

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
            Threads.@spawn assess(system, method, sampleseeds, results, resultspecs...)
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
    #topology = Topology(system)
    pm = PowerFlowProblem(system, method, field(method, :settings), Topology(system))    #DON'T MOVE THIS LINE
    recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
    rng = Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE

    for s in sampleseeds
        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstates, system) #creates the up/down sequence for each device.

        for t in 1:N
            if field(systemstates, :system)[t] ≠ true
                #println("t=$(t)")
                update!(field(pm, :topology), systemstates, system, t)
                solve!(pm, system, t)
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
    initialize_availability!(
        field(states, :branches), field(states, :generators), field(states, :storages),
        field(states, :generatorstorages), field(states, :system), N)

    return

end

""
function update!(topology::Topology, states::SystemStates, system::SystemModel, t::Int)

    #update_statess!(system, states, t)
    if field(states, :system)[t] ≠ true
        
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
function solve!(pm::AbstractPowerModel, system::SystemModel, t::Int)

    build_method!(pm, system, t)
    optimize!(pm.model)
    build_result!(pm, system, t)
end

""
function empty_model!(pm::AbstractPowerModel)

    #if isempty(pm.model)==false empty!(pm.model) end
    empty!(pm.model)
    return
end

#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

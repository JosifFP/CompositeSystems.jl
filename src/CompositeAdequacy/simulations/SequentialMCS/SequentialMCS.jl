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
    systemstates = SystemStates(system, method)
    pm = Initialize_model(system, topology, settings)
    recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
    rng = Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE

    for s in sampleseeds

        iszero(s%10) &&  OPF.set_optimizer(pm.model, deepcopy(field(settings, :optimizer)); add_bridges = false)

        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstates, system) #creates the up/down sequence for each device.

        for t in 1:N
            if systemstates.system[t] ≠ true
                update!(pm.topology, systemstates, system, t)
                solve!(pm, system, t)
                empty!(pm.model)
            end
        end

        foreach(recorder -> record!(recorder, system, pm, s), recorders)
        foreach(recorder -> reset!(recorder, s), recorders)
        empty_model!(system, pm, settings)
    end

    put!(results, recorders)

end

""
function initialize!(rng::AbstractRNG, states::SystemStates, system::SystemModel{N}) where N

    fill!(field(states, :branches), 1)
    fill!(field(states, :generators), 1)

    initialize_availability!(rng, field(states, :branches), field(system, :branches), N)
    initialize_availability!(rng, field(states, :generators), field(system, :generators), N)
    initialize_availability!(rng, field(states, :storages), field(system, :storages), N)
    initialize_availability!(rng, field(states, :generatorstorages), field(system, :generatorstorages), N)

    @inbounds for t in 1:N

        total_load::Float16 = sum(field(system, :loads, :pd)[:,t])
        total_gen::Float16 = sum(field(system, :generators, :pmax)[i] for i in filter(k -> field(states, :generators)[k,t], field(system, :generators, :keys)))

        if all(field(states, :branches)[:,t]) == false
            states.system[t] = false
        else
            if total_load >= total_gen
                states.system[t] = false
            elseif count(field(states, :generators)[:,t]) < length(system.generators) - 1
                states.system[t] = false
            end

        end
    end

    #initialize_availability!(states, N)
    #states = propagate_outages!(states, system.branches, settings, N)
    return

end

""
function update!(topology::Topology, states::SystemStates, system::SystemModel, t::Int)

    #update_idxs!(
    #    filter(i->states.buses[i]!= 4,field(system, :buses, :keys)), topology(pm, :buses_idxs))

    #update_idxs!(
    #    filter(i->field(states, :loads, i, t), field(system, :loads, :keys)), 
    #    topology(pm, :loads_idxs), topology(pm, :loads_nodes), field(system, :loads, :buses))

    update_idxs!(
        filter(i->field(states, :shunts, i, t), field(system, :shunts, :keys)), 
        topology.shunts_idxs, topology.shunts_nodes, field(system, :shunts, :buses))    

    update_idxs!(
        filter(i->field(states, :generators, i, t), field(system, :generators, :keys)), 
        topology.generators_idxs, field(topology, :generators_nodes), field(system, :generators, :buses))

    update_branch_idxs!(
        field(system, :branches), topology.branches_idxs, topology.arcs, field(system, :arcs), field(states, :branches), t)    

    #update_idxs!(
    #    filter(i->field(states, :storages, i, t), field(system, :storages, :keys)),
    #    topology(pm, :storages_idxs), topology(pm, :storages_nodes), field(system, :storages, :buses))

    #update_idxs!(
    #    filter(i->field(states, :generatorstorages, i, t), field(system, :generatorstorages, :keys)), 
    #    topology(pm, :generatorstorages_idxs), topology(pm, :generatorstorages_nodes), field(system, :generatorstorages, :buses))    

    return

end

""
function solve!(pm::AbstractPowerModel, system::SystemModel, t::Int)

    build_method!(pm, system, t)
    optimize_method!(pm.model)
    build_result!(pm, system, t)
    return

end


#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

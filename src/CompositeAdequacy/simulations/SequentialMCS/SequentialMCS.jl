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
    cache = Cache(system, method, multiperiod=false)
    pm = PowerFlowProblem(system, field(settings, :powermodel), method, cache, settings)

    Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            Threads.@spawn assess(system, pm, method, cache, settings, sampleseeds, results, resultspecs...)
        end
    else
        assess(system, pm, method, cache, sampleseeds, results, resultspecs...)
    end

    return finalize(results, system, method.threaded ? threads : 1)
    
end

""
function assess(
    system::SystemModel{N},
    pm::AbstractPowerModel,
    method::SequentialMCS,
    cache::Cache,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}},
    resultspecs::ResultSpec...
) where {N}

    systemstates = SystemStates(system, method)
    recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
    rng = Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE

    for s in sampleseeds
        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstates, system) #creates the up/down sequence for each device.

        for t in 1:N
            if systemstates.system[t] ≠ true
                update!(pm, systemstates, system, t)
                solve!(pm, system, t)
                empty_method!(pm, cache)
            end
        end

        foreach(recorder -> record!(recorder, system, pm, s), recorders)
        foreach(recorder -> reset!(recorder, s), recorders)
        fill!(pm.sol, 0)
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
            elseif count(field(states, :generators)[:,t]) < length(system.generators)
                states.system[t] = false
            end

        end
    end

    #initialize_availability!(states, N)
    #states = propagate_outages!(states, system.branches, settings, N)
    return

end

""
function update!(pm::AbstractPowerModel, states::SystemStates, system::SystemModel, t::Int)

    #update_idxs!(
    #    filter(i->states.buses[i]!= 4,field(system, :buses, :keys)), topology(pm, :buses_idxs))

    #update_idxs!(
    #    filter(i->field(states, :loads, i, t), field(system, :loads, :keys)), 
    #    topology(pm, :loads_idxs), topology(pm, :loads_nodes), field(system, :loads, :buses))

    update_idxs!(
        filter(i->field(states, :shunts, i, t), field(system, :shunts, :keys)), 
        topology(pm, :shunts_idxs), topology(pm, :shunts_nodes), field(system, :shunts, :buses))    

    update_idxs!(
        filter(i->field(states, :generators, i, t), field(system, :generators, :keys)), 
        topology(pm, :generators_idxs), topology(pm, :generators_nodes), field(system, :generators, :buses))

    update_branch_idxs!(
        field(system, :branches), topology(pm, :branches_idxs), topology(pm, :arcs), field(system, :arcs), field(states, :branches), t)    

    #update_idxs!(
    #    filter(i->field(states, :storages, i, t), field(system, :storages, :keys)),
    #    topology(pm, :storages_idxs), topology(pm, :storages_nodes), field(system, :storages, :buses))

    #update_idxs!(
    #    filter(i->field(states, :generatorstorages, i, t), field(system, :generatorstorages, :keys)), 
    #    topology(pm, :generatorstorages_idxs), topology(pm, :generatorstorages_nodes), field(system, :generatorstorages, :buses))    

    build_method!(pm, system, t)

    return

end

""
function solve!(pm::AbstractPowerModel, system::SystemModel, t::Int)

    optimize!(pm.model)
    build_result!(pm, system, t)

end


#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

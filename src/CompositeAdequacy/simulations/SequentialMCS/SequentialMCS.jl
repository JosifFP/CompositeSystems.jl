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

    recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
    rng = Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE

    for s in sampleseeds
        println("s=$(s)")
        systemstates = SystemStates(system, method)
        pm = PowerFlowProblem(system, method, field(method, :settings))
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstates, system) #creates the up/down sequence for each device.

        for t in 1:N
            if field(systemstates, :system)[t] ≠ true
                #println("t=$(t)")
                update!(field(pm, :topology), systemstates, system, t)
                solve!(pm, system, t)
                empty_model!(pm, t)
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
    initialize_availability!(states, field(states, :system), N)

    return

end

""
function update!(topology::Topology, states::SystemStates, system::SystemModel, t::Int)

    update_idxs!(
        filter(i->field(states, :loads, t)[i], field(system, Loads, :keys)), 
        field(topology, :loads_idxs), field(topology, :loads_nodes), field(system, Loads, :buses))

    update_idxs!(
        filter(i->field(states, :shunts, t)[i], field(system, Shunts, :keys)), 
        field(topology, :shunts_idxs), field(topology, :shunts_nodes), field(system, Shunts, :buses))    

    update_idxs!(
        filter(i->field(states, :generators, t)[i], field(system, Generators, :keys)), 
        field(topology, :generators_idxs), field(topology, :generators_nodes), field(system, Generators, :buses))

    update_idxs!(
        filter(i->field(states, :storages, t)[i], field(system, Storages, :keys)),
        field(topology, :storages_idxs), field(topology, :storages_nodes), field(system, Storages, :buses))

    update_idxs!(
        filter(i->field(system, :generatorstorages)[i], field(system, GeneratorStorages, :keys)), 
        field(topology, :generatorstorages_idxs), field(topology, :generatorstorages_nodes), field(system, GeneratorStorages, :buses))    
        
    update_branch_idxs!(
        field(system, :branches), field(topology, :branches_idxs), field(topology, :arcs), field(system, :arcs), field(states, :branches), t)

    return

end

""
function solve!(pm::AbstractPowerModel, system::SystemModel, t::Int)

    build_method!(pm, system, t)
    optimize!(pm.model)
    build_result!(pm, system, t)
end

""
function empty_model!(pm::AbstractPowerModel, t)

    #if isempty(pm.model)==false empty!(pm.model) end
    empty!(pm.model)
    reset_variables!(field(pm, :var), field(pm, :var_cache))

    return
end

#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

include("utils.jl")

function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    pm::AbstractPowerModel,
    resultspecs::ResultSpec...
) where {N}

    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)

    Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            Threads.@spawn assess(system, method, pm, sampleseeds, results, resultspecs...)
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
    pm::AbstractPowerModel,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}},
    resultspecs::ResultSpec...
) where {N}

    recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
    rng = Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE

    for s in sampleseeds
        println("s=$(s)")
        systemstates = SystemStates(system, method)
        #pm = PowerFlowProblem(system, method, field(method, :settings))
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstates, system) #creates the up/down sequence for each device.

        for t in 1:N
            if field(systemstates, :system)[t] ≠ true
                #println("t=$(t)")
                update!(field(pm, :topology), systemstates, system, t)
                solve!(pm, system, t)
                empty_optcontainers!(pm, t)
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
        filter(i->view(states, :loads, i, t), field(system, :loads, :keys)), 
        field(topology, :loads_idxs), field(topology, :loads_nodes), field(system, :loads, :buses))

    update_idxs!(
        filter(i->view(states, :shunts, i, t), field(system, :shunts, :keys)), 
        field(topology, :shunts_idxs), field(topology, :shunts_nodes), field(system, :shunts, :buses))    

    update_idxs!(
        filter(i->view(states, :generators, i, t), field(system, :generators, :keys)), 
        field(topology, :generators_idxs), field(topology, :generators_nodes), field(system, :generators, :buses))

    update_idxs!(
        filter(i->view(states, :storages, i, t), field(system, :storages, :keys)),
        field(topology, :storages_idxs), field(topology, :storages_nodes), field(system, :storages, :buses))

    update_idxs!(
        filter(i->field(system, :generatorstorages)[i], field(system, :generatorstorages, :keys)), 
        field(topology, :generatorstorages_idxs), field(topology, :generatorstorages_nodes), field(system, :generatorstorages, :buses))    
        
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


#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

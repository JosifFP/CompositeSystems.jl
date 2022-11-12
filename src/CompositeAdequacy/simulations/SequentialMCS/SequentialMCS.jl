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
    systemstates = SystemStates(system)
    pm = Initialize_model(system, topology, settings)
    recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
    rng = Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE

    for s in sampleseeds

        iszero(s%10) &&  OPF.set_optimizer(pm.model, deepcopy(field(settings, :optimizer)); add_bridges = false)

        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize_states!(rng, systemstates, system) #creates the up/down sequence for each device.

        for t in 1:N
            if systemstates.system[t] ≠ true
                #update!(pm.topology, systemstates, system, t)
                solve!(pm, system, systemstates, t)
                empty!(pm.model)
            end
            foreach(recorder -> record!(recorder, pm, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
        empty_model!(system, pm, settings)
        #GC.gc()
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

    #initialize_availability!(states, N)
    #states = propagate_outages!(states, system.branches, settings, N)
    return

end




""
function update!(topology::Topology, states::SystemStates, system::SystemModel, t::Int)


    return

end

""
function solve!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    build_method!(pm, system, states, t)
    optimize_method!(pm.model)
    build_result!(pm, system, t)
    #GC.gc()
end



#update_energy!(states.stors_energy, system.storages, t)
#update_energy!(states.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

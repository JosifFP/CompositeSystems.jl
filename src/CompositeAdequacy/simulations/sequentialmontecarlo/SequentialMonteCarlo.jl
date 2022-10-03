include("SystemState.jl")
include("utils.jl")

struct SequentialMonteCarlo <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool

    function SequentialMonteCarlo(;
        samples::Int=1_000, seed::Int=rand(UInt64),
        verbose::Bool=false, threaded::Bool=false
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))
        new(samples, UInt64(seed), verbose, threaded)
    end

end

function assess(
    system::SystemModel{N},
    method::SequentialMonteCarlo,
    optimizer,
    resultspecs::ResultSpec...
) where {N}

    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    @spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            @spawn assess(system, optimizer, method, sampleseeds, results, resultspecs...)
        end
    else
        assess(system, optimizer, method, sampleseeds, results, resultspecs...)
    end

    return finalize(results, system, method.threaded ? threads : 1)
    
end

"It generates a sequence of seeds from a given number of samples"
function makeseeds(sampleseeds::Channel{Int}, nsamples::Int)
    for s in 1:nsamples
        put!(sampleseeds, s)
    end
    close(sampleseeds)
end

function assess(
    system::SystemModel{N}, optimizer, method::SequentialMonteCarlo,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMonteCarlo}}}},
    resultspecs::ResultSpec...
) where {R<:ResultSpec, N}

    local systemstate = SystemState(system)
    local recorders = accumulator.(system, method, resultspecs)
    local rng = Philox4x((0, 0), 10)
    local pm = BuildAbstractPowerModel!(DCPowerModel, JuMP.direct_model(optimizer), ref)

    for s in sampleseeds
        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        iter = initialize!(rng, systemstate, system) #creates the up/down sequence for each device.

        for (_,t) in enumerate(iter)
            #println("t=$(t)")
            solve!(systemstate, system, t)
            foreach(recorder -> record!(recorder, pm, s, t), recorders)
            RestartAbstractPowerModel!(pm, ref)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
    end

    put!(results, recorders)

end

""
function initialize!(rng::AbstractRNG, state::SystemState, system::SystemModel{N}) where N

    initialize_availability!(rng, state.gens_available, system.generators, N)
    initialize_availability!(rng, state.stors_available, system.storages, N)
    initialize_availability!(rng, state.genstors_available, system.generatorstorages, N)
    initialize_availability!(rng, state.branches_available, system.branches, N)
    
    tmp = []
    for t in 1:N
        if all([state.gens_available[:,t]; state.genstors_available[:,t]; state.stors_available[:,t]; state.branches_available[:,t]]) == false 
            state.condition[t] = 0 
            push!(tmp,t)
        end
    end

    return tmp

end

""
function solve!(state::SystemState, system::SystemModel{N}, t::Int) where {N}

    update_system!(state, system, t)

end


#ref_add!(ref(pm))
#state.branches_available[:,t] == true ? sol(pm)[:type] = type = Transportation : sol(pm)[:type] = type = DCOPF
#sol(pm)[:type] = type = Transportation
#build_method!(pm, type)
#JuMP.optimize!(pm.model)
#build_result!(pm, system.loads, t)


#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")
include("result_report.jl")


function update_system!(state::SystemState, system::SystemModel{N}, t::Int) where {N}

    system.branches.status[:] = state.branches_available[:,t]
    system.generators[:] = state.gens_available[:,t]
    system.storages[:] = state.stors_available[:,t]
    system.generatorstorages[:] = state.genstors_available[:,t]

    for k in system.branches.keys
        if system.branches.status[k] ≠ 0
            f_bus = system.branches.f_bus[k]
            t_bus = system.branches.t_bus[k]
            if system.buses.bus_type[f_bus] == 4 || system.buses.bus_type[t_bus] == 4
                Memento.info(_LOGGER, "deactivating branch $(k):($(f_bus),$(t_bus)) due to connecting bus status")
                system.branches.status[k] = 0
            end
        end
    end
    
    for k in system.buses.keys
        if system.buses.bus_type[k] == 4
            if system.loads.status[k] ≠ 0 system.loads.status[k] = 0 end
            if system.shunts.status[k] ≠ 0 system.shunts.status[k] = 0 end
            if system.generators.status[k] ≠ 0 system.generators.status[k] = 0 end
            if system.storages.status[k] ≠ 0 system.storages.status[k] = 0 end
            if system.generatorstorages.status[k] ≠ 0 system.generatorstorages.status[k] = 0 end
        end
    end

    tmp_arcs_from = [(i,a,b) for (i,a,b) in system.topology.arcs_from if system.branches.status[i] == true]
    tmp_arcs_to   = [(i,a,b) for (i,a,b) in system.topology.arcs_to if system.branches.status[i] == true]
    tmp_arcs = [(i,a,b) for (i,a,b) in system.topology.arcs if system.branches.status[i] == true]

    (bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage) = PRATSBase.bus_components(tmp_arcs, system.buses, system.loads, system.shunts, system.generators, system.storages)

    for k in system.buses.keys
        system.topology.bus_gens[k] = bus_gens[k]
        system.topology.bus_loads[k] = bus_loads[k]
        system.topology.bus_shunts[k] = bus_shunts[k]
        system.topology.bus_storage[k] = bus_storage[k]
    
        if system.topology.bus_arcs[k] ≠ bus_arcs[k]
            system.topology.bus_arcs[k] = bus_arcs[k]
        end
    
    end

    tmp_buspairs = PRATSBase.calculate_buspair_parameters(system.buses, system.branches)

    for bp in keys(system.topology.buspairs)
        if haskey(tmp_buspairs, bp) ≠ true
            println(bp)
            empty!(system.topology.buspairs[bp])
        end
    end

    return
end

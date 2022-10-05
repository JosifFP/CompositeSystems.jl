include("SystemState.jl")
include("utils.jl")

struct SequentialMonteCarlo <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool

    function SequentialMonteCarlo(;
        samples::Int=1_000, seed::Int=rand(UInt64),
        verbose::Bool=false, threaded::Bool=true
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))
        new(samples, UInt64(seed), verbose, threaded)
    end

end

function assess(
    system::SystemModel{N,L,T,U},
    method::SequentialMonteCarlo,
    optimizer,
    resultspecs::ResultSpec...
) where {N,L,T,U}

    threads = nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    
    @spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            Threads.@spawn assess(system, optimizer, method, sampleseeds, results, resultspecs...)
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
    system::SystemModel{N,L,T,U}, optimizer, method::SequentialMonteCarlo,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMonteCarlo}}}},
    resultspecs::ResultSpec...
) where {R<:ResultSpec,N,L,T,U}

    local pm = BuildAbstractPowerModel!(DCPowerModel, JuMP.direct_model(optimizer))
    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system) #creates the up/down sequence for each device.

        for t in 1:N
            println("t=$(t)")
            #if t in iter
            update!(pm, systemstate, system, t)
            solve!(pm, systemstate, system, t) 
            #end
            foreach(recorder -> record!(recorder, system, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
    end

    Base.put!(results, recorders)
end

""
function initialize!(rng::AbstractRNG, state::SystemState, system::SystemModel{N}) where N

    initialize_availability!(rng, field(state, :gens_available), field(system, :generators), N)
    initialize_availability!(rng, field(state, :stors_available), field(system, :storages), N)
    initialize_availability!(rng, field(state, :genstors_available), field(system, :generatorstorages), N)
    initialize_availability!(rng, field(state, :branches_available), field(system, :branches), N)
    
    tmp = []
    for t in 1:N
        if all([
            field(state, :gens_available)[:,t]; 
            field(state, :stors_available)[:,t]; 
            field(state, :genstors_available)[:,t]; 
            field(state, :branches_available)[:,t]]) == false 
            field(state, :condition)[t] = 0 
            push!(tmp,t)
        end
    end

    return tmp

end

""
function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel{N}, t::Int) where {N}

    all(field(state, :branches_available)[:,t]) == true ? type = Transportation : type = DCOPF
    build_method!(pm, system, t, type)
    JuMP.optimize!(pm.model)
    build_result!(pm, system, t)

end

""
function update!(pm::AbstractPowerModel, state::SystemState, system::SystemModel, t::Int)
    
    if JuMP.isempty(pm.model)==false JuMP.empty!(pm.model) end
    if isempty(pm.sol)==false empty!(pm.sol) end

    field(system, Loads, :plc)[:] = fill!(field(system, Loads, :plc)[:], 0)

    field(system, Loads, :pd)[:,t] = field(system, Loads, :pd)[:,t]*1.25
    field(system, Branches, :status)[:] = field(state, :branches_available)[:,t]
    field(system, Generators, :status)[:] = field(state, :gens_available)[:,t]
    field(system, Storages, :status)[:] = field(state, :stors_available)[:,t]
    field(system, GeneratorStorages, :status)[:] = field(state, :genstors_available)[:,t]
    

    for k in field(system, Branches, :keys)
        if field(system, Branches, :status)[k] ≠ 0
            f_bus = field(system, Branches, :f_bus)[k]
            t_bus = field(system, Branches, :t_bus)[k]
            if field(system, Buses, :bus_type)[f_bus] == 4 || field(system, Buses, :bus_type)[t_bus] == 4
                Memento.info(_LOGGER, "deactivating branch $(k):($(f_bus),$(t_bus)) due to connecting bus status")
                field(system, Branches, :status)[k] = 0
            end
        end
    end
    
    for k in field(system, Buses, :keys)
        if field(system, Buses, :bus_type)[k] == 4
            if field(system, Loads, :status)[k] ≠ 0 field(system, Loads, :status)[k] = 0 end
            if field(system, Shunts, :status)[k] ≠ 0 field(system, Shunts, :status)[k] = 0 end
            if field(system, Generators, :status)[k] ≠ 0 field(system, Generators, :status)[k] = 0 end
            if field(system, Storages, :status)[k] ≠ 0 field(system, Storages, :status)[k] = 0 end
            if field(system, GeneratorStorages, :status)[k] ≠ 0 field(system, GeneratorStorages, :status)[k] = 0 end
        end
    end

    #tmp_arcs_from = [(l,i,j) for (l,i,j) in field(system, Topology, :arcs_from) if field(system, Branches, :status)[l] ≠ 0]
    #tmp_arcs_to   = [(l,i,j) for (l,i,j) in field(system, Topology, :arcs_to) if field(system, Branches, :status)[l] ≠ 0]
    tmp_arcs = [(l,i,j) for (l,i,j) in field(system, Topology, :arcs) if field(system, Branches, :status)[l] ≠ 0]

    (bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage) = get_bus_components(
        tmp_arcs, field(system, :buses), field(system, :loads), field(system, :shunts), field(system, :generators), field(system, :storages))

    for k in field(system, Buses, :keys)
        field(system, Topology, :bus_gens)[k] = bus_gens[k]
        field(system, Topology, :bus_loads)[k] = bus_loads[k]
        field(system, Topology, :bus_shunts)[k] = bus_shunts[k]
        field(system, Topology, :bus_storage)[k] = bus_storage[k]
    
        if field(system, Topology, :bus_arcs)[k] ≠ bus_arcs[k]
            field(system, Topology, :bus_arcs)[k] = bus_arcs[k]
        end
    
    end

    tmp_buspairs = calc_buspair_parameters(field(system, :buses), field(system, :branches))

    for k in keys(field(system, Topology, :buspairs))
        if haskey(tmp_buspairs, k) ≠ true
            empty!(field(system, Topology, :buspairs)[k])
        else
            field(system, Topology, :buspairs)[k] = tmp_buspairs[k]
        end
    end

    return
end

""
function RestartAbstractPowerModel!(pm::AbstractPowerModel, system::SystemModel)

    if JuMP.isempty(pm.model)==false JuMP.empty!(pm.model) end
    empty!(pm.sol)
    field(system, Loads, :plc)[:] = fill!(field(system, Loads, :plc)[:], 0)
    return
end

#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")
#include("result_report.jl")

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

    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)
    pm = BuildAbstractPowerModel!(DCPowerModel, JuMP.direct_model(optimizer))

    for s in sampleseeds
        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        iter = initialize!(rng, systemstate, system) #creates the up/down sequence for each device.

        for (_,t) in enumerate(iter)
            println("t=$(t)")
            solve!(pm, systemstate, system, t)
            foreach(recorder -> record!(recorder, pm, s, t), recorders)
            RestartAbstractPowerModel!(pm)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
    end

    put!(results, recorders)

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

    update_system!(state, system, t)
    all(field(state, :branches_available)[:,t]) == true ? type = Transportation : type = DCOPF
    build_method!(pm, system, t, type)
    JuMP.optimize!(pm.model)
    build_result!(pm, field(system, :loads), t)

end


#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")
include("result_report.jl")


function update_system!(state::SystemState, system::SystemModel{N}, t::Int) where {N}
    
    field(system, Loads, :pd)[:,t] = field(system, Loads, :pd)[:,t]*1.5
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

    for (k,v) in field(system, Topology, :buspairs)
        if haskey(tmp_buspairs, k) ≠ true
            empty!(v)
        end
    end

    return
end

""
function update!(system::SystemModel{N}) where {N}

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

    for (k,v) in field(system, Topology, :buspairs)
        if haskey(tmp_buspairs, k) ≠ true
            empty!(v)
        end
    end

    return
end


function get_bus_components(arcs::Vector{Tuple{Int, Int, Int}}, buses::Buses, loads::Loads, shunts::Shunts, generators::Generators, storages::Storages)

    tmp = Dict((i, Tuple{Int,Int,Int}[]) for i in field(buses, :keys))
    for (l,i,j) in arcs
        push!(tmp[i], (l,i,j))
    end
    bus_arcs = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    for k in field(loads, :keys)
        if field(loads, :status)[k] ≠ 0 push!(tmp[field(loads, :buses)[k]], k) end
    end
    bus_loads = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    for k in field(shunts, :keys)
        if field(shunts, :status)[k] ≠ 0 push!(tmp[field(shunts, :buses)[k]], k) end
    end
    bus_shunts = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    for k in field(generators, :keys)
        if field(generators, :status)[k] ≠ 0 push!(tmp[field(generators, :buses)[k]], k) end
    end
    bus_gens = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    for k in field(storages, :keys)
        if field(storages, :status)[k] ≠ 0 push!(tmp[field(storages, :buses)[k]], k) end
    end
    bus_storage = tmp

    return (bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage)

end

"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses::Buses, branches::Branches)

    bus_lookup = [i for i in field(buses, :keys) if field(buses, :bus_type)[i] ≠ 4]
    branch_lookup = [i for i in field(branches, :keys) if field(branches, :status)[i] == 1 && field(branches, :f_bus)[i] in bus_lookup && field(branches, :t_bus)[i] in bus_lookup]
    
    buspair_indexes = Set((field(branches, :f_bus)[i], field(branches, :t_bus)[i]) for i in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)
    
    for l in branch_lookup
        i = field(branches, :f_bus)[l]
        j = field(branches, :t_bus)[l]
        bp_angmin[(i,j)] = max(bp_angmin[(i,j)], field(branches, :angmin)[l])
        bp_angmax[(i,j)] = min(bp_angmax[(i,j)], field(branches, :angmax)[l])
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    
    buspairs = Dict((i,j) => Dict(
        "branch"=>Int(bp_branch[(i,j)]),
        "angmin"=>Float16(bp_angmin[(i,j)]),
        "angmax"=>Float16(bp_angmax[(i,j)]),
        "tap"=>Float16(field(branches, :tap)[bp_branch[(i,j)]]),
        "vm_fr_min"=>Float16(field(buses, :vmin)[i]),
        "vm_fr_max"=>Float16(field(buses, :vmax)[i]),
        "vm_to_min"=>Float16(field(buses, :vmin)[j]),
        "vm_to_max"=>Float16(field(buses, :vmax)[j]),
        ) for (i,j) in buspair_indexes
    )
    
    # add optional parameters
    for bp in buspair_indexes
        buspairs[bp]["rate_a"] = field(branches, :rate_a)[bp_branch[bp]]
    end
    
    return buspairs

end
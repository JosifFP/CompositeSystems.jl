include("SystemState.jl")
include("utils.jl")

struct SequentialMCS <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool

    function SequentialMCS(;
        samples::Int=1_000, seed::Int=rand(UInt64),
        verbose::Bool=false, threaded::Bool=true
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))
        new(samples, UInt64(seed), verbose, threaded)
    end

end

function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    resultspecs::ResultSpec...
) where {N}

    nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2, "constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
    optimizer = optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])


    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    
    Base.Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            Base.Threads.@spawn assess(system, optimizer, method, sampleseeds, results, resultspecs...)
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
    system::SystemModel{N}, optimizer, method::SequentialMCS,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}},
    resultspecs::ResultSpec...
) where {N}

    #Model(optimizer; add_bridges = false) #direct_model(optimizer)
    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    for s in sampleseeds
        println("s=$(s)")
        pm = PowerFlowProblem(AbstractOPF, Model(optimizer; add_bridges = false) , Topology(system))
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system) #creates the up/down sequence for each device.

        for t in 1:N
            if field(systemstate, :condition)[t] ≠ true
                update!(pm.topology, systemstate, system, t)
                solve!(pm, systemstate, system, t)
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
function initialize!(rng::AbstractRNG, state::SystemState, system::SystemModel{N}) where N

    initialize_availability!(rng, field(state, :branches), field(system, :branches), N)
    initialize_availability!(rng, field(state, :generators), field(system, :generators), N)
    initialize_availability!(rng, field(state, :storages), field(system, :storages), N)
    initialize_availability!(rng, field(state, :generatorstorages), field(system, :generatorstorages), N)
    
    for t in 1:N
        if all([field(state, :branches)[:,t]; field(state, :generators)[:,t]; field(state, :storages)[:,t]; field(state, :generatorstorages)[:,t]]) ≠ true
            field(state, :condition)[t] = 0 
        end
    end

    return

end

""
function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel, t::Int)

    #all(field(state, :branches)[:,t]) == true ? type = Transportation : type = DCOPF
    type = DCOPF
    build_method!(pm, system, t, type)
    optimize!(pm.model)
    build_result!(pm, system, t)
end

""
function update!(topology::Topology, state::SystemState, system::SystemModel, t::Int)

    #update_states!(system, state, t)
    if field(state, :condition)[t] ≠ true
        
        key_buses = field(system, Buses, :keys)

        update_asset_idxs!(
            topology, field(system, :loads), field(state, :loads), key_buses, t)

        update_asset_idxs!(
            topology, field(system, :shunts), field(state, :shunts), key_buses, t)

        update_asset_idxs!(
            topology, field(system, :generators), field(state, :generators), key_buses, t)

        update_asset_idxs!(
            topology, field(system, :storages), field(state, :storages), key_buses, t)

        update_asset_idxs!(
            topology, field(system, :generatorstorages), field(state, :generatorstorages), key_buses, t)

        update_branch_idxs!(
            topology, system, field(state, :branches), key_buses, t)

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

#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")

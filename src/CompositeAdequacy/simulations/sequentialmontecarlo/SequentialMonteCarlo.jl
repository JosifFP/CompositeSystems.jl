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
    system::SystemModel,
    method::SequentialMonteCarlo,
    resultspecs::ResultSpec...
)
    add_load_curtailment_info!(system.network)

    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)

    optimizer = [JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0), JuMP.optimizer_with_attributes(Juniper.Optimizer, 
    "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])]

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

    #sequences = UpDownSequence(system)
    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)

    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system) #creates the up/down sequence for each device.

        for t in 1:N
            
            pm = advance!(PRATSBase.conversion_to_pm_data(system.network), systemstate, system, optimizer, t; systemstate.condition[t])
            solve!(pm, systemstate, system, t)
            foreach(recorder -> record!(recorder, system, s, t), recorders)

        end

        foreach(recorder -> reset!(recorder, s), recorders)

    end

    put!(results, recorders)

end

function initialize!(rng::AbstractRNG, state::SystemState, system::SystemModel{N}) where N

    initialize_availability!(rng, state.gens_available, system.generators, N)
    initialize_availability!(rng, state.stors_available, system.storages, N)
    initialize_availability!(rng, state.genstors_available, system.generatorstorages, N)
    initialize_availability!(rng, state.branches_available, system.branches, N)
    update_condition!(state, N)

    return

end

function advance!(network_data::Dict{String,Any}, 
    state::SystemState, system::SystemModel{N}, 
    optimizer, t::Int, condition::Bool=true) where {N}

    update_data_from_system!(network_data, system, t)
    pm = solve_model(network_data, DCPPowerModel, optimizer; condition)

    return pm

end

function advance!(network_data::Dict{String,Any}, 
    state::SystemState, system::SystemModel{N}, 
    optimizer, t::Int, condition::Bool=false) where {N}

    update_data_from_system!(network_data, system, t)
    apply_contingencies!(network_data, state, system, t)
    PRATSBase.SimplifyNetwork!(network_data)
    pm = solve_model(network_data, DCMLPowerModel, optimizer; condition)

    return pm
    
end

function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel, t::Int)

    update_data!(network_data, results["solution"])

    for i in eachindex(system.branches.keys)
        system.branches.pf[i,t] = Float16.(network_data["branch"][string(i)]["pf"])
        system.branches.pt[i,t] = Float16.(network_data["branch"][string(i)]["pt"])
    end

    for i in eachindex(system.generators.keys)
        system.generators.pg[i,t] = network_data["gen"][string(i)]["pg"]
    end

    return system

end


function solve_model(data::Dict{String,<:Any}, model_type, optimizer; kwargs...)

    pm =  InitializeAbstractPowerModel(data, model_type, optimizer; kwargs...)
    ref_add!(pm.ref)
    build_model(pm)
    optimization(pm)
    return pm
end

CompositeAdequacy.solve_model(network_data, CompositeAdequacy.DCMLPowerModel, optimizer; condition = systemstate.condition[1])


#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
#include("result_shortfall.jl")
include("result_flow.jl")

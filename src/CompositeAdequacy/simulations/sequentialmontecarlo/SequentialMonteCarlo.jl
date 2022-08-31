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
    #threads = 1
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    @spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            @spawn assess(system, method, sampleseeds, results, resultspecs...)
        end
    else
        assess(system, method, sampleseeds, results, resultspecs...)
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
    system::SystemModel{N}, method::SequentialMonteCarlo,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMonteCarlo}}}},
    resultspecs::ResultSpec...
) where {R<:ResultSpec, N}

    sequences = UpDownSequence(system)
    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)
    network_data = PRATSBase.conversion_to_pm_data(system.network)
    optimizer = [JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0), JuMP.optimizer_with_attributes(Juniper.Optimizer, 
    "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])]

    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system, sequences) #creates the up/down sequence for each device.

        for t in 1:N
            
            advance!(sequences, systemstate, system, t)
            update_data_from_system!(network_data, system, t)
            solve!(network_data, systemstate, system, optimizer, t)
            foreach(recorder -> record!(recorder, system, s, t), recorders)

        end

        foreach(recorder -> reset!(recorder, s), recorders)

    end

    put!(results, recorders)

end

function initialize!(
    rng::AbstractRNG, state::SystemState, system::SystemModel{N}, sequences::UpDownSequence
) where N

    initialize_availability!(rng, sequences.Up_gens, system.generators, N)
    initialize_availability!(rng, sequences.Up_stors, system.storages, N)
    initialize_availability!(rng, sequences.Up_genstors, system.generatorstorages, N)
    initialize_availability!(rng, sequences.Up_branches, system.branches, N)

    fill!(state.stors_energy, 0)
    fill!(state.genstors_energy, 0)

    return sequences

end

function advance!(sequences::UpDownSequence, state::SystemState, system::SystemModel{N}, t::Int) where N

    update_availability!(state.gens_available, sequences.Up_gens[:,t], length(system.generators))
    update_availability!(state.stors_available,sequences.Up_stors[:,t], length(system.storages))
    update_availability!(state.genstors_available,sequences.Up_genstors[:,t], length(system.generatorstorages))
    update_availability!(state.branches_available,sequences.Up_branches[:,t], length(system.branches))
    update_condition!(state, state.condition)
    update_energy!(state.stors_energy, system.storages, t)
    update_energy!(state.genstors_energy, system.generatorstorages, t)

end

function solve!(network_data::Dict{String,Any}, state::SystemState, system::SystemModel, optimizer, t::Int)

    #if 0 in [state.gens_available; state.stors_available; state.genstors_available; state.branches_available] == true
    if state.condition == false
        apply_contingencies!(system, state, system)
        PRATSBase.SimplifyNetwork!(network_data)
        results = PRATSBase.OptimizationProblem(network_data, PRATSBase.dc_opf_lc, optimizer[2])

    else
        results = PRATSBase.OptimizationProblem(network_data, PRATSBase.dc_opf, optimizer[1])
    end

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

include("result_shortfall.jl")
include("result_flow.jl")
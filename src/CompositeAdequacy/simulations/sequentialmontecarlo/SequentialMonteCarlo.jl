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

    nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0)
    mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
    minlp_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"time_limit"=>1.0, "log_levels"=>[])
    #minlp_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "time_limit"=>1.5, "log_levels"=>[])
    optimizer = [nl_solver, mip_solver, minlp_solver]


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

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system) #creates the up/down sequence for each device.
        data = Dict{String,Any}()
        #println("s=$(s)")

        for t in 1:N
            pm = solve!(systemstate, system, data, optimizer, t, systemstate.condition[t]) #systemstate.condition[t])
            foreach(recorder -> record!(recorder, pm, system, s, t), recorders)
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

    for t in 1:N
         if all([state.gens_available[:,t]; state.genstors_available[:,t]; state.stors_available[:,t]; state.branches_available[:,t]]) == false state.condition[t] = Failed end
    end

    return

end

function solve!(state::SystemState, system::SystemModel, data::Dict{String,Any}, optimizer, t::Int, condition::Type{Failed})

    fill_data!(state, system, data, t, condition)
    return SolveModel(data, DCMLPowerModel, optimizer)
    #empty!(data)

end

function solve!(state::SystemState, system::SystemModel, data::Dict{String,Any}, optimizer, t::Int, condition::Type{Success})

    fill_data!(state, system, data, t, condition)
    return SolveModel(data, DCPPowerModel, optimizer)
    #empty!(data)

end

#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")

""
function fill_data!(state::SystemState, system::SystemModel, data::Dict{String,<:Any}, t::Int, ::Type{Success})

    push!(data, 
    "bus" => system.network.bus,
    "dcline" => system.network.dcline,
    "gen" => system.network. gen,
    "branch" => system.network. branch,
    "storage" => system.network.storage,
    "switch" => system.network.switch,
    "shunt" => system.network.shunt,
    "load" => system.network.load)

    for i in eachindex(system.generators.keys)
        data["gen"][string(i)]["pg"] = system.generators.pg[i,t]
    end

    for i in eachindex(system.loads.keys)
        data["load"][string(i)]["qd"] = Float16.(system.loads.pd[i,t]*
            Float32.(data["load"][string(i)]["qd"] / data["load"][string(i)]["pd"]))
        data["load"][string(i)]["pd"] = system.loads.pd[i,t].*1.5
    end
    return

end

""
function fill_data!(state::SystemState, system::SystemModel, data::Dict{String,<:Any}, t::Int, ::Type{Failed})

    push!(data, 
    "bus" => system.network.bus,
    "dcline" => system.network.dcline,
    "gen" => system.network. gen,
    "branch" => system.network. branch,
    "storage" => system.network.storage,
    "switch" => system.network.switch,
    "shunt" => system.network.shunt,
    "load" => system.network.load)

    for i in eachindex(system.generators.keys)
        data["gen"][string(i)]["pg"] = system.generators.pg[i,t]
        if state.gens_available[i] == false data["gen"][string(i)]["gen_status"] = state.gens_available[i,t] end
    end

    for i in eachindex(system.storages.keys)
        if state.stors_available[i] == false data["storage"][string(i)]["status"] = state.stors_available[i,t] end
    end

    for i in eachindex(system.loads.keys)
        data["load"][string(i)]["qd"] = Float16.(system.loads.pd[i,t]*
            Float32.(data["load"][string(i)]["qd"] / data["load"][string(i)]["pd"]))
        data["load"][string(i)]["pd"] = system.loads.pd[i,t].*1.5
    end

    if all(state.branches_available[:,t]) == false
        for i in eachindex(system.branches.keys)
            if state.branches_available[i] == false data["branch"][string(i)]["br_status"] = state.branches_available[i,t] end
        end
    end

    PRATSBase.SimplifyNetwork!(data)
    return
end
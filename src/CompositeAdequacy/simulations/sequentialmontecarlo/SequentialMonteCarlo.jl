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
    optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"time_limit"=>1.0, "log_levels"=>[])
    #minlp_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "time_limit"=>1.5, "log_levels"=>[])
    #optimizer = [nl_solver, mip_solver, minlp_solver]

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
    dictionary = Dict{Symbol,Any}()
    fill_dictionary!(system, dictionary)
    pm = InitializeAbstractPowerModel(dictionary, AbstractDCPModel, optimizer)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system) #creates the up/down sequence for each device.
        println("s=$(s)")

        for t in 1:N
            #println("t=$(t)")
            solve!(pm, systemstate, system, t, systemstate.condition[t])
            foreach(recorder -> record!(recorder, pm, system, s, t), recorders)
            empty_pm!(pm)
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
        if all([state.gens_available[:,t]; state.genstors_available[:,t]; state.stors_available[:,t]; state.branches_available[:,t]]) == false 
            state.condition[t] = Failed 
        end
    end

end

""
function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel, t::Int, condition::Type{Failed})

    update_ref!(state, system, pm.ref, t, condition)
    build_model!(pm, LMOPFMethod)
    optimization!(pm, LMOPFMethod)
    build_result!(pm, LMOPFMethod)

end

""
function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel, t::Int, condition::Type{Success})

    update_ref!(state, system, pm.ref, t, condition)
    build_model!(pm, OPFMethod)
    optimization!(pm, OPFMethod)

    if JuMP.termination_status(pm.model) ≠ JuMP.LOCALLY_SOLVED
        var_load_curtailment(pm)
        JuMP.@objective(pm.model, Min, sum(pm.ref[:load][i]["cost"]*pm.model[:plc][i] for i in keys(pm.ref[:load])))
        JuMP.delete(pm.model, JuMP.all_constraints(pm.model, AffExpr, MOI.EqualTo{Float64}))
        constraint_nodal_power_balance(pm, LMOPFMethod)
        constraint_branch_pf_limits(pm)
        constraint_hvdc_line(pm)
        optimization!(pm, LMOPFMethod)
        build_result!(pm, LMOPFMethod)
    else
        build_result!(pm, OPFMethod)
    end

end

#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")


""
function fill_dictionary!(system::SystemModel, dictionary::Dict{Symbol,<:Any})

    push!(dictionary, 
    :bus => system.network.bus,
    :dcline => system.network.dcline,
    :gen => system.network. gen,
    :branch => system.network. branch,
    :storage => system.network.storage,
    :switch => system.network.switch,
    :shunt => system.network.shunt,
    :load => system.network.load)

    return dictionary

end

""
function update_ref!(state::SystemState, system::SystemModel, dictionary::Dict{Symbol,<:Any}, t::Int, ::Type{Success})

    for i in eachindex(system.generators.keys)
        dictionary[:gen][i]["pg"] = system.generators.pg[i,t]
    end

    for i in eachindex(system.loads.keys)
        #dictionary[:load][i]["qd"] = Float16.(system.loads.pd[i,t]*Float32.(dictionary[:load][i]["qd"] / dictionary[:load][i]["pd"]))
        dictionary[:load][i]["pd"] = system.loads.pd[i,t]
    end

end

""
function update_ref!(state::SystemState, system::SystemModel, dictionary::Dict{Symbol,<:Any}, t::Int, ::Type{Failed})

    for i in eachindex(system.generators.keys)
        dictionary[:gen][i]["pg"] = system.generators.pg[i,t]
        if state.gens_available[i] == false dictionary[:gen][i]["gen_status"] = state.gens_available[i,t] end
    end

    for i in eachindex(system.storages.keys)
        if state.stors_available[i] == false dictionary[:storage][i]["status"] = state.stors_available[i,t] end
    end

    for i in eachindex(system.loads.keys)
        #dictionary[:load][i]["qd"] = Float16.(system.loads.pd[i,t]*Float32.(dictionary[:load][i]["qd"] / dictionary[:load][i]["pd"]))
        dictionary[:load][i]["pd"] = system.loads.pd[i,t].*1.5
    end

    if all(state.branches_available[:,t]) == false
        for i in eachindex(system.branches.keys)
            if state.branches_available[i] == false dictionary[:branch][i]["br_status"] = state.branches_available[i,t] end
        end
    end

    PRATSBase.SimplifyNetwork!(dictionary)
    ref_add!(dictionary)

end


""
function empty_pm!(pm::AbstractPowerModel)

    empty!(pm.model)
    pm.ref = deepcopy(pm.dictionary)
    empty!(pm.load_curtailment)
    pm.termination_status = ""

end
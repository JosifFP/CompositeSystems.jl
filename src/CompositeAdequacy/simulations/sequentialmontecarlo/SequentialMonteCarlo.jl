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

    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)

    nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0)
    #mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
    #optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"time_limit"=>1.0, "log_levels"=>[])
    optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "time_limit"=>1.5, "log_levels"=>[])

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
    pm = InitializeAbstractPowerModel(system.network, dictionary, AbstractDCPModel, optimizer)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        iter = initialize!(rng, systemstate, system) #creates the up/down sequence for each device.
        println("s=$(s)")

        for (_,t) in enumerate(iter)
            #println("t=$(iter[i])")
            solve!(pm, systemstate, system, t, systemstate.condition[t])
            foreach(recorder -> record!(recorder, pm.load_curtailment, system.loads, s, t), recorders)
            empty_pm!(pm, system.network, dictionary)
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
    
    tmp = []
    for t in 1:N
        if all([state.gens_available[:,t]; state.genstors_available[:,t]; state.stors_available[:,t]; state.branches_available[:,t]]) == false 
            state.condition[t] = Failed 
            push!(tmp,t)
        end
    end

    return tmp

end

""
function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel, t::Int, condition::Type{Failed})
    pm.type = LMOPFMethod
    update_ref!(state, system, pm.ref, t, condition)
    build_model!(pm)
    optimization!(pm)
    build_result!(pm, system.network.load)
    #return pm
end

""
function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel, t::Int, condition::Type{Success})

    pm.type = OPFMethod
    build_result!(pm, system.network.load)
    #return pm
end

#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")

""
function fill_dictionary!(network::Network, dictionary::Dict{Symbol,<:Any})

    push!(dictionary, 
    :bus => network.bus,
    :dcline => network.dcline,
    :gen => network.gen,
    :branch => network. branch,
    :storage => network.storage,
    :switch => network.switch,
    :shunt => network.shunt,
    :load => network.load)

    return dictionary

end

""
function update_ref!(state::SystemState, system::SystemModel, dictionary::Dict{Symbol,<:Any}, t::Int, type::Type{Success})

    update_gen!(system.generators, dictionary, state.gens_available, t, type)
    update_load!(system.loads, dictionary, t)
    ref_add!(dictionary)

end

""
function update_ref!(state::SystemState, system::SystemModel, dictionary::Dict{Symbol,<:Any}, t::Int, type::Type{Failed})

    update_gen!(system.generators, dictionary, state.gens_available, t, type)
    update_stor!(system.storages, dictionary, state.stors_available, t)
    update_load!(system.loads, dictionary, t)
    update_branches!(system.branches, dictionary, state.branches_available, t)
    PRATSBase.SimplifyNetwork!(dictionary)
    ref_add!(dictionary)

end

""
function empty_pm!(pm::AbstractPowerModel, network::Network, dictionary::Dict{Symbol,<:Any})
    if JuMP.isempty(pm.model)==false JuMP.empty!(pm.model) end
    pm.ref = fill_dictionary!(network, dictionary)
    empty!(pm.load_curtailment)
    pm.termination_status = 0

end
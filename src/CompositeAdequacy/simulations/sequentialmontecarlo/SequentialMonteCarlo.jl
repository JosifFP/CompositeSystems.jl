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

    if optimizer === nothing
        model = JuMP.Model()
        @debug "The optimization model has no optimizer attached"
    else
        model = JuMP.direct_model(optimizer)
        JuMP.set_string_names_on_creation(model, false)
        #model = JuMP.Model(optimizer, add_bridges=false)
    end

    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)
    ref = initialize_ref(system.network; multinetwork=false)
    pm = BuildAbstractPowerModel!(DCPowerModel, model, ref)


    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        iter = initialize!(rng, systemstate, system) #creates the up/down sequence for each device.

        for (_,t) in enumerate(iter)
            println("t=$(t)")
            update!(pm, systemstate, system, t)
            solve!(pm, systemstate, t)
            foreach(recorder -> record!(recorder, pm, s, t), recorders)
            RestartAbstractPowerModel!(pm, initialize_ref(system.network; multinetwork=false))
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
function update!(pm::AbstractPowerModel, state::SystemState, system::SystemModel{N}, t::Int; nw::Int=0) where {N}

    ext(pm, nw)[:load_initial] = update_load!(system.loads, ref(pm, nw, :load), t)
    update_gen!(system.generators, ref(pm, nw, :gen), state.gens_available, t)

    if all(state.gens_available[:,t]) == true && all(state.branches_available[:,t]) == false
        update_stor!(system.storages, ref(pm, nw, :storage), state.stors_available, t)
        update_branches!(system.branches, ref(pm, nw, :branch), state.branches_available, t)
        PRATSBase.SimplifyNetwork!(ref(pm, nw))
    end
    ref_add!(ref(pm, nw))
    return

end

""
function solve!(pm::AbstractPowerModel, state::SystemState, t::Int; nw::Int=0)

    state.branches_available[:,t] == true ? ext(pm,nw)[:type] = type = Transportation : ext(pm,nw)[:type] = type = DCOPF
    build_method!(pm, type; nw)
    optimization!(pm, type; nw)
    build_result!(pm, type; nw)
    return

end


#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")

""
function empty_pm!(pm::AbstractPowerModel, ref::Dict{Symbol,Any})

    if JuMP.isempty(pm.model)==false JuMP.empty!(pm.model) end
    pm.ref = ref
    pm.var = _initialize_dict_from_ref(ref)
    pm.con = _initialize_dict_from_ref(ref)
    pm.sol = _initialize_dict_from_ref(ref)
    pm.ext = _initialize_dict_from_ref(ref)
    
end

#nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
#mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"time_limit"=>1.0, "log_levels"=>[])
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "branch_strategy"=>:PseudoCost ,"time_limit"=>1.5, "log_levels"=>[])
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "log_levels"=>[])

# ""
# function update_refs!(state::SystemState, system::SystemModel{N}, refs::Dict{Symbol,<:Any}, iter) where {N}

#     #tmp = Dict{Int, Type}()
#     for (_,nw) in enumerate(iter)
        
#         #state.condition == Success ? ext(pm,nw)[:type] = Transportation : ext(pm,nw)[:type] = LMDCOPF
#         #type = ext(pm,nw)[:type]
#         update_load!(system.loads, refs[:nw][nw], nw)
#         update_gen!(system.generators, refs[:nw][nw], state.gens_available, nw)

#         if all(state.gens_available[:,nw]) == true
#             update_stor!(system.storages, refs[:nw][nw], state.stors_available, nw)
#             update_branches!(system.branches, refs[:nw][nw], state.branches_available, nw)
#             PRATSBase.SimplifyNetwork!(refs[:nw][nw])
#         end

#         ref_add!(refs[:nw][nw])
#     end

#     return refs
# end
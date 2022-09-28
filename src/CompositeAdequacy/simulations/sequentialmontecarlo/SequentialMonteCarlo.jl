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

    for s in sampleseeds
        println("s=$(s)")
        local ref = MutableNetwork(system.network)
        local pm = BuildAbstractPowerModel!(DCPowerModel, JuMP.direct_model(optimizer), ref)
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        iter = initialize!(rng, systemstate, system) #creates the up/down sequence for each device.

        for (_,t) in enumerate(iter)
            #println("t=$(t)")
            #update!(pm, systemstate, system, t)
            solve!(pm, systemstate, system, t)
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
function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel{N}, t::Int) where {N}

    update_load!(system.loads, ref(pm, :load), t)
    update_gen!(system.generators, ref(pm, :gen), state.gens_available, t)

    if all(state.gens_available[:,t]) == true && all(state.branches_available[:,t]) == false
        update_stor!(system.storages, ref(pm, :storage), state.stors_available, t)
        update_branches!(system.branches, ref(pm, :branch), state.branches_available, t)
    end

    ref_add!(ref(pm))
    state.branches_available[:,t] == true ? sol(pm)[:type] = type = Transportation : sol(pm)[:type] = type = DCOPF
    build_method!(pm, type)
    JuMP.optimize!(pm.model)
    build_result!(pm, system.loads, t)
    return pm

end

#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")
include("result_report.jl")
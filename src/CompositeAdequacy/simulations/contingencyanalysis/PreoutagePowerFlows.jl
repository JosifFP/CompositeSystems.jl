struct PreoutagePowerFlows <: SimulationSpec

    verbose::Bool
    threaded::Bool

    PreoutagePowerFlows(;verbose::Bool=false, threaded::Bool=true) =
        new(verbose, threaded)

end

function assess(
    system::SystemModel{N},
    method::PreoutagePowerFlows,
    resultspecs::ResultSpec...
) where {N}

    nregions = length(system.regions)
    nstors = length(system.storages)
    ngenstors = length(system.generatorstorages)

    threads = nthreads()
    periods = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)

    @spawn makeperiods(periods, N)

    if method.threaded
        for _ in 1:threads
            @spawn assess(system, method, periods, results, resultspecs...)
        end
    else
        assess(system, method, periods, results, resultspecs...)
    end

    return finalize(results, system, method.threaded ? threads : 1)

end

function makeperiods(periods::Channel{Int}, N::Int)
    for t in 1:N
        put!(periods, t)
    end
    close(periods)
end

function assess(
    system::SystemModel{N,L,T,P,E}, method::Convolution,
    periods::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{Convolution}}}},
    resultspecs::ResultSpec...
) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit}

    accs = accumulator.(system, method, resultspecs)

    for t in periods

        distr = CapacityDistribution(system, t)
        foreach(acc -> record!(acc, t, distr), accs)

    end

    put!(results, accs)

end

include("result_shortfall.jl")
include("result_surplus.jl")

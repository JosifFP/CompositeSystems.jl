# Shortfall

mutable struct SMCShortfallAccumulator <: ResultAccumulator{SequentialMCS,Shortfall}

    # Cross-simulation LOL period count mean/variances
    periodsdropped_total::MeanVariance
    periodsdropped_bus::Vector{MeanVariance}
    periodsdropped_period::Vector{MeanVariance}
    periodsdropped_busperiod::Matrix{MeanVariance}

    # Running LOL period counts for current simulation
    periodsdropped_total_currentsim::Int
    periodsdropped_bus_currentsim::Vector{Int}

    # Cross-simulation UE mean/variances
    unservedload_total::MeanVariance
    unservedload_bus::Vector{MeanVariance}
    unservedload_period::Vector{MeanVariance}
    unservedload_busperiod::Matrix{MeanVariance}

    # Running UE totals for current simulation
    unservedload_total_currentsim::Float16
    unservedload_bus_currentsim::Vector{Float16}

end

function merge!(
    x::SMCShortfallAccumulator, y::SMCShortfallAccumulator
)

    merge!(x.periodsdropped_total, y.periodsdropped_total)
    foreach(merge!, x.periodsdropped_bus, y.periodsdropped_bus)
    foreach(merge!, x.periodsdropped_period, y.periodsdropped_period)
    foreach(merge!, x.periodsdropped_busperiod, y.periodsdropped_busperiod)

    merge!(x.unservedload_total, y.unservedload_total)
    foreach(merge!, x.unservedload_bus, y.unservedload_bus)
    foreach(merge!, x.unservedload_period, y.unservedload_period)
    foreach(merge!, x.unservedload_busperiod, y.unservedload_busperiod)

    return

end

accumulatortype(::SequentialMCS, ::Shortfall) = SMCShortfallAccumulator

function accumulator(
    sys::SystemModel{N}, ::SequentialMCS, ::Shortfall
) where {N}

    nloads = length(sys.loads.keys)

    periodsdropped_total = meanvariance()
    periodsdropped_bus = [meanvariance() for _ in 1:nloads]
    periodsdropped_period = [meanvariance() for _ in 1:N]
    periodsdropped_busperiod = [meanvariance() for _ in 1:nloads, _ in 1:N]

    periodsdropped_total_currentsim = 0
    periodsdropped_bus_currentsim = zeros(Int, nloads)

    unservedload_total = meanvariance()
    unservedload_bus = [meanvariance() for _ in 1:nloads]
    unservedload_period = [meanvariance() for _ in 1:N]
    unservedload_busperiod = [meanvariance() for _ in 1:nloads, _ in 1:N]

    unservedload_total_currentsim = 0
    unservedload_bus_currentsim = zeros(Float16, nloads)

    return SMCShortfallAccumulator(
        periodsdropped_total, periodsdropped_bus,
        periodsdropped_period, periodsdropped_busperiod,
        periodsdropped_total_currentsim, periodsdropped_bus_currentsim,
        unservedload_total, unservedload_bus,
        unservedload_period, unservedload_busperiod,
        unservedload_total_currentsim, unservedload_bus_currentsim)

end

function record!(
    acc::SMCShortfallAccumulator,
    sys::SystemModel{N,L,T,S},
    pm::AbstractPowerModel,
    sampleid::Int, t::Int
) where {N,L,T,S}

    totalshortfall = 0
    isshortfall = false
    busshortfalls = sol(pm)[:plc]

    for r in sys.loads.keys

        busshortfall = busshortfalls[r]
        isbusshortfall = busshortfall > 0

        fit!(acc.periodsdropped_busperiod[r,t], isbusshortfall)
        fit!(acc.unservedload_busperiod[r,t], busshortfall)
    
        if isbusshortfall

            isshortfall = true
            totalshortfall += busshortfall

            acc.periodsdropped_bus_currentsim[r] += 1
            acc.unservedload_bus_currentsim[r] += busshortfall

        end
    
    end

    if isshortfall
        acc.periodsdropped_total_currentsim += 1
        acc.unservedload_total_currentsim += totalshortfall
    end

    fit!(acc.periodsdropped_period[t], isshortfall)
    fit!(acc.unservedload_period[t], totalshortfall)

    return

end


function record!(
    acc::SMCShortfallAccumulator,
    sys::SystemModel{N,L,T,S},
    pm::AbstractPowerModel,
    sampleid::Int
) where {N,L,T,S}

    nloads = length(CompositeAdequacy.field(pm, Topology, :loads_idxs))
    #isshortfall = zeros(Bool, nloads)

    for t in 1:N

        totalshortfall = 0
        isshortfall = false

        for r in nloads

            busshortfall = field(pm, Topology, :plc)[r,t]
            isbusshortfall = busshortfall > 0
    
            fit!(acc.periodsdropped_busperiod[r,t], isbusshortfall)
            fit!(acc.unservedload_busperiod[r,t], busshortfall)
        
            if isbusshortfall
    
                isshortfall = true
                totalshortfall += busshortfall
    
                acc.periodsdropped_bus_currentsim[r] += 1
                acc.unservedload_bus_currentsim[r] += busshortfall
    
            end
        
        end
    
        if isshortfall
            acc.periodsdropped_total_currentsim += 1
            acc.unservedload_total_currentsim += totalshortfall
        end
    
        fit!(acc.periodsdropped_period[t], isshortfall)
        fit!(acc.unservedload_period[t], totalshortfall)

    end

    return

end


function reset!(acc::SMCShortfallAccumulator, sampleid::Int)

    # Store busal / total sums for current simulation
    fit!(acc.periodsdropped_total, acc.periodsdropped_total_currentsim)
    fit!(acc.unservedload_total, acc.unservedload_total_currentsim)

    for r in eachindex(acc.periodsdropped_bus)
        fit!(acc.periodsdropped_bus[r], acc.periodsdropped_bus_currentsim[r])
        fit!(acc.unservedload_bus[r], acc.unservedload_bus_currentsim[r])
    end

    # Reset for new simulation
    acc.periodsdropped_total_currentsim = 0
    fill!(acc.periodsdropped_bus_currentsim, 0)
    acc.unservedload_total_currentsim = 0
    fill!(acc.unservedload_bus_currentsim, 0)

    return

end

function finalize(
    acc::SMCShortfallAccumulator,
    system::SystemModel{N,L,T,S},
) where {N,L,T,S}

    ep_total_mean, ep_total_std = mean_std(acc.periodsdropped_total)
    ep_bus_mean, ep_bus_std = mean_std(acc.periodsdropped_bus)
    ep_period_mean, ep_period_std = mean_std(acc.periodsdropped_period)
    ep_busperiod_mean, ep_busperiod_std =
        mean_std(acc.periodsdropped_busperiod)

    _, ue_total_std = mean_std(acc.unservedload_total)
    _, ue_bus_std = mean_std(acc.unservedload_bus)
    _, ue_period_std = mean_std(acc.unservedload_period)
    ue_busperiod_mean, ue_busperiod_std =
        mean_std(acc.unservedload_busperiod)

    nsamples = first(acc.unservedload_total.stats).n
    P = PRATSBase.powerunits["MW"]
    E = PRATSBase.energyunits["MWh"]
    p2e = conversionfactor(S,L,T,P,E)

    return ShortfallResult{N,L,T,E}(
        nsamples, 
        length(ep_bus_mean), 
        system.timestamps,
        ep_total_mean, 
        ep_total_std, 
        ep_bus_mean, 
        ep_bus_std,
        ep_period_mean, 
        ep_period_std,
        ep_busperiod_mean, 
        ep_busperiod_std,
        p2e*ue_busperiod_mean, 
        p2e*ue_total_std,
        p2e*ue_bus_std, 
        p2e*ue_period_std, 
        p2e*ue_busperiod_std)
end

# ShortfallSamples

struct SMCShortfallSamplesAccumulator <:
    ResultAccumulator{SequentialMCS,ShortfallSamples}

    shortfall::Array{Float16,3}

end

function merge!(
    x::SMCShortfallSamplesAccumulator, y::SMCShortfallSamplesAccumulator
)

    x.shortfall .+= y.shortfall
    return

end

accumulatortype(::SequentialMCS, ::ShortfallSamples) = SMCShortfallSamplesAccumulator

function accumulator(
    sys::SystemModel{N}, simspec::SequentialMCS, ::ShortfallSamples
) where {N}

    nloads = length(sys.loads.keys)
    shortfall = zeros(Int, nloads, N, simspec.nsamples)

    return SMCShortfallSamplesAccumulator(shortfall)

end

function record!(
    acc::SMCShortfallSamplesAccumulator,
    system::SystemModel{N,L,T,S},
    sampleid::Int, t::Int
) where {N,L,T,S}

    for r in field(system, Loads, :keys)
        acc.shortfall[r,t,sampleid] = field(system, Loads, :plc)[r]
    end
    return

end

reset!(acc::SMCShortfallSamplesAccumulator, sampleid::Int) = nothing

function finalize(
    acc::SMCShortfallSamplesAccumulator,
    system::SystemModel{N,L,T,S},
) where {N,L,T,S}

    P = PRATSBase.powerunits["MW"]
    E = PRATSBase.energyunits["MWh"]
    p2e = conversionfactor(S,L,T,P,E)
    return ShortfallSamplesResult{N,L,T,P,E}(
        system.loads.keys, system.timestamps, p2e*acc.shortfall)

end
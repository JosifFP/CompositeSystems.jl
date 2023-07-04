"Utilization"
struct SMCUtilizationAccumulator <: ResultAccumulator{SequentialMCS,Utilization}

    util_branch::Vector{MeanVariance} # util: utilization branch
    util_branchperiod::Matrix{MeanVariance}
    util_branch_currentsim::Vector{Float64}
    ptv_branch::Vector{MeanVariance}  # ptv: probability of thermal violation
    ptv_branchperiod::Matrix{MeanVariance}
    ptv_branch_currentsim::Vector{Float64}
end

""
function merge!(x::SMCUtilizationAccumulator, y::SMCUtilizationAccumulator)

    foreach(merge!, x.util_branch, y.util_branch)
    foreach(merge!, x.util_branchperiod, y.util_branchperiod)
    foreach(merge!, x.ptv_branch, y.ptv_branch)
    foreach(merge!, x.ptv_branchperiod, y.ptv_branchperiod)
end

accumulatortype(::SequentialMCS, ::Utilization) = SMCUtilizationAccumulator

""
function accumulator(sys::SystemModel{N}, ::SequentialMCS, ::Utilization) where {N}

    nbranches = length(sys.branches)
    util_branch = [meanvariance() for _ in 1:nbranches]
    util_branchperiod = [meanvariance() for _ in 1:nbranches, _ in 1:N]
    util_branch_currentsim = zeros(Int, nbranches)
    ptv_branch = [meanvariance() for _ in 1:nbranches]
    ptv_branchperiod = [meanvariance() for _ in 1:nbranches, _ in 1:N]
    ptv_branch_currentsim = zeros(Int, nbranches)
    return SMCUtilizationAccumulator(
        util_branch, util_branchperiod, util_branch_currentsim,
        ptv_branch, ptv_branchperiod, ptv_branch_currentsim
    )
end

""
function record!(
    acc::SMCUtilizationAccumulator, pm::AbstractPowerModel, states::States, system::SystemModel, sampleid::Int, t::Int)

    for l in eachindex(topology(pm, :branches_flow_from))

        util = utilization(
            topology(pm, :branches_flow_from)[l], topology(pm, :branches_flow_to)[l], system.branches.rate_a[l])
        ptv = prob_thermal_violation(
            topology(pm, :branches_flow_from)[l], topology(pm, :branches_flow_to)[l], system.branches.rate_a[l])
        acc.util_branch_currentsim[l] += util
        acc.ptv_branch_currentsim[l] += ptv
        fit!(acc.util_branchperiod[l,t], util)
        fit!(acc.ptv_branchperiod[l,t], ptv)
    end
    return
end

""
function reset!(acc::SMCUtilizationAccumulator, sampleid::Int)

    for i in eachindex(acc.util_branch_currentsim)
        fit!(acc.util_branch[i], acc.util_branch_currentsim[i])
        acc.util_branch_currentsim[i] = 0
        fit!(acc.ptv_branch[i], acc.ptv_branch_currentsim[i])
        acc.ptv_branch_currentsim[i] = 0
    end
end

""
function finalize(acc::SMCUtilizationAccumulator, system::SystemModel{N,L,T}) where {N,L,T}

    nsamples = length(system.branches) > 0 ? first(acc.util_branch[1].stats).n : nothing

    util_mean, util_branchperiod_std = mean_std(acc.util_branchperiod)
    util_branch_std = last(mean_std(acc.util_branch)) / N

    ptv_mean, ptv_branchperiod_std = mean_std(acc.ptv_branchperiod)
    ptv_branch_std = last(mean_std(acc.ptv_branch)) / N

    return UtilizationResult{N,L,T}(
        nsamples,  
        Pair.(system.branches.f_bus, system.branches.t_bus),
        system.timestamps,
        util_mean,
        util_branch_std,
        util_branchperiod_std,
        ptv_mean,
        ptv_branch_std,
        ptv_branchperiod_std
    )

end

# UtilizationSamples

struct SMCUtilizationSamplesAccumulator <: ResultAccumulator{SequentialMCS,UtilizationSamples}
    utilization::Array{Float64,3}
end

function merge!(x::SMCUtilizationSamplesAccumulator, y::SMCUtilizationSamplesAccumulator)
    x.utilization .+= y.utilization
    return
end

accumulatortype(::SequentialMCS, ::UtilizationSamples) = SMCUtilizationSamplesAccumulator

""
function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::UtilizationSamples) where {N}

    nbranches = length(sys.branches)
    utilization = zeros(Float64, nbranches, N, simspec.nsamples)
    return SMCUtilizationSamplesAccumulator(utilization)
end

""
function record!(
    acc::SMCUtilizationSamplesAccumulator, pm::AbstractPowerModel, states::States, system::SystemModel, sampleid::Int, t::Int)

    for l in eachindex(topology(pm, :branches_flow_from))
        acc.utilization[l, t, sampleid] = utilization(
            topology(pm, :branches_flow_from)[l], topology(pm, :branches_flow_to)[l], system.branches.rate_a[l])
    end
    return
end

reset!(acc::SMCUtilizationSamplesAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCUtilizationSamplesAccumulator, system::SystemModel{N,L,T}) where {N,L,T}
    return UtilizationSamplesResult{N,L,T}(
        Pair.(system.branches.f_bus, system.branches.t_bus), 
        system.timestamps, 
        acc.utilization
    )
end

""
function utilization(flow_from::Float64, flow_to::Float64, rate_a::Float32)

    util = if flow_from > 0
        flow_from/rate_a
    elseif flow_to > 0
        flow_to/rate_a
    elseif iszero(rate_a)
        1.0
    else
        0.0
    end
    return util
end

""
function prob_thermal_violation(flow_from::Float64, flow_to::Float64, rate_a::Float32)

    if isapprox(flow_from, rate_a; atol = 1e-3) || isapprox(flow_to, rate_a; atol = 1e-3)
        prob_thermal = 1
    else
        prob_thermal = 0
    end
    return prob_thermal
end
# Flow

struct NCFlowAccumulator <: ResultAccumulator{NoContingencies,Flow}

    flow_branch::Vector{MeanVariance}
    flow_branchperiod::Matrix{MeanVariance}
    flow_branch_currentsim::Vector{Float16}

end

function merge!(
    x::NCFlowAccumulator, y::NCFlowAccumulator
)

    foreach(merge!, x.flow_branch, y.flow_branch)
    foreach(merge!, x.flow_branchperiod, y.flow_branchperiod)

end

accumulatortype(::NoContingencies, ::Flow) = NCFlowAccumulator

function accumulator(
    system::SystemModel{N}, ::NoContingencies, ::Flow
) where {N}

    n_branches = length(system.branches)
    flow_branch = [meanvariance() for _ in 1:n_branches]
    flow_branchperiod = [meanvariance() for _ in 1:n_branches, _ in 1:N]

    flow_branch_currentsim = zeros(Int, n_branches)

    return NCFlowAccumulator(
        flow_branch, flow_branchperiod,  flow_branch_currentsim)

end

function record!(
    acc::NCFlowAccumulator,
    system::SystemModel{N,L,T,U},
    #state::SystemState,
    sampleid::Int, t::Int
) where {N,L,T,U}

for i in eachindex(system.branches.keys)
    acc.flow_branch_currentsim[i] += abs.(system.branches.pf[i,t])
    fit!(acc.flow_branchperiod[i,t],  abs.(system.branches.pf[i,t]))
end

end

function reset!(acc::NCFlowAccumulator, sampleid::Int)

    for i in eachindex(acc.flow_branch_currentsim)
        fit!(acc.flow_branch[i], acc.flow_branch_currentsim[i])
        acc.flow_branch_currentsim[i] = 0
    end

end

function finalize(
    acc::NCFlowAccumulator,
    system::SystemModel{N,L,T,U},
) where {N,L,T,U}

    nsamples = length(system.branches.keys) > 0 ?
        first(acc.flow_branch[1].stats).n : nothing

    nsamples = 1
    flow_mean, flow_branchperiod_std = mean_std(acc.flow_branchperiod)
    flow_branch_std = last(mean_std(acc.flow_branch)) / N

    return FlowResult{N,L,T,U}(
        nsamples,  system.branches.keys, system.timestamps,
        flow_mean, flow_branch_std, flow_branchperiod_std)

end

# --------------------------------------------------------------------------------------------------------------------
# FlowTotal

 struct NCFlowTotalAccumulator <: ResultAccumulator{NoContingencies,FlowTotal}

    total::Array{Float16,3}

 end

 function merge!(x::NCFlowTotalAccumulator, y::NCFlowTotalAccumulator)

     x.total .+= y.total
     return

 end

 accumulatortype(::NoContingencies, ::FlowTotal) = NCFlowTotalAccumulator

 function accumulator(system::SystemModel{N}, simspec::NoContingencies, ::FlowTotal) where {N}

     nbranches = length(system.branches)
     #flow = zeros(Float16, nbranches, N)
     flow = zeros(Float16, nbranches, N, 1)#simspec.nsamples)

     return NCFlowTotalAccumulator(flow)
 end

 function record!(
     acc::NCFlowTotalAccumulator,
     system::SystemModel{N,L,T,U}, sampleid::Int, t::Int
 ) where {N,L,T,U}

     acc.total[:,t,sampleid] = abs.(system.branches.pf[:,t])
     return

 end

 reset!(acc::NCFlowTotalAccumulator, sampleid::Int) = nothing

 function finalize(
     acc::NCFlowTotalAccumulator,
     system::SystemModel{N,L,T,U},
 ) where {N,L,T,U}

     #allzeros = zeros(size(acc.flow_branches))
     return FlowTotalResult{N,L,T,U}(nothing, system.branches.keys, system.timestamps, acc.total)
 end
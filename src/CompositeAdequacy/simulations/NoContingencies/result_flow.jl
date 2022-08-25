# Flow

struct NoContingenciesFlowAccumulator <: ResultAccumulator{NoContingencies,Flow}

    pf::Matrix{Float16}
end

function merge!(
    x::NoContingenciesFlowAccumulator, y::NoContingenciesFlowAccumulator
)

    x.pf .+= y.pf
    return

end

accumulatortype(::NoContingencies, ::Flow) = NoContingenciesFlowAccumulator

accumulator(::SystemModel{N}, ::NoContingencies, nbranches::Int, ::Flow) where {N} = NoContingenciesFlowAccumulator(zeros(Float16, nbranches, N))

function record!(
    acc::NoContingenciesFlowAccumulator,
    system::SystemModel{N,L,T,U}, t::Int
) where {N,L,T,U}

    acc.pf[:,t] = system.branches.pf[:,t]
    return

end

function finalize(
    acc::NoContingenciesFlowAccumulator,
    system::SystemModel{N,L,T,U},
) where {N,L,T,U}

    #allzeros = zeros(size(acc.flow_branches))

    return FlowResult{N,L,T,U}(
        nothing, system.branches.keys, system.timestamps,
        acc.pf
    )
end
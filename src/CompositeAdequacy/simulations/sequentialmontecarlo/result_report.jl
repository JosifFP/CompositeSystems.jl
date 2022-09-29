# Report

mutable struct SMCReportAccumulator <: ResultAccumulator{SequentialMonteCarlo,Report}
    
    status::Vector{Int}

end

function merge!(
    x::SMCReportAccumulator, y::SMCReportAccumulator
)
    return
end

accumulatortype(::SequentialMonteCarlo, ::Report) = SMCReportAccumulator

function accumulator(
    sys::SystemModel{N}, ::SequentialMonteCarlo, ::Report
) where {N}

    status = zeros(Int, N*10)
    return SMCReportAccumulator(status)

end

function record!(
    acc::SMCReportAccumulator,
    pm::AbstractPowerModel,
    sampleid::Int, t::Int
) where {N,L,T}

    status = sol(pm, :termination_status)
    if status != 1
        acc.status = status
    end
    return

end

reset!(acc::SMCReportAccumulator, sampleid::Int) = nothing

function finalize(
    acc::SMCReportAccumulator,
    system::SystemModel{N,L,T,U},
) where {N,L,T,U}

    return ReportResult{N,L,T}(acc.status, system.timestamps)

end
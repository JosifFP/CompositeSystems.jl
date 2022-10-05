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

    status = zeros(Int, N)
    return SMCReportAccumulator(status)

end

function record!(
    acc::SMCReportAccumulator,
    sys::SystemModel{N},
    sampleid::Int, t::Int
) where {N,L,T}

    status = 1
    if status != 1
        acc.status = status
    end
    return

end

function reset!(acc::SMCReportAccumulator, sampleid::Int)

    fill!(acc.status, 0)
    return

end

function finalize(
    acc::SMCReportAccumulator,
    system::SystemModel{N,L,T,U},
) where {N,L,T,U}

    return ReportResult{N,L,T}(zeros(Int, N), system.timestamps)

end
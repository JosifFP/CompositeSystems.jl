abstract type CapacityValuationMethod{M<:ReliabilityMetric} end

struct CapacityCreditResult{S <: CapacityValuationMethod, M <: ReliabilityMetric, P <: PowerUnit}

    target_metric::M
    si_metric::SI
    eens_metric::EENS
    edlc_metric::EDLC
    lowerbound::Float64
    upperbound::Float64
    bound_capacities::Vector{Float64}
    si_metrics::Vector{SI}
    eens_metrics::Vector{EENS}
    edlc_metrics::Vector{EDLC}

    function CapacityCreditResult{S,M,P}(
        target_metric::M, si_metric::SI, eens_metric::EENS, edlc_metric::EDLC,
        lowerbound::Float64, upperbound::Float64,
        bound_capacities::Vector{Float64}, si_metrics::Vector{SI}, eens_metrics::Vector{EENS}, edlc_metrics::Vector{EDLC}) where {S,M,P}

        length(bound_capacities) == length(eens_metrics) ||
            throw(ArgumentError("Lengths of bound_capacities and metrics must match"))

         new{S,M,P}(
            target_metric, si_metric, eens_metric, edlc_metric, 
            lowerbound, upperbound, bound_capacities, si_metrics, 
            eens_metrics, edlc_metrics)
    end
end

minimum(x::CapacityCreditResult) = x.lowerbound
maximum(x::CapacityCreditResult) = x.upperbound
extrema(x::CapacityCreditResult) = (x.lowerbound, x.upperbound)

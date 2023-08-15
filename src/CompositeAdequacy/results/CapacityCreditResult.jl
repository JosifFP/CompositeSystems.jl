abstract type CapacityValuationMethod{M<:ReliabilityMetric} end

struct CapacityCreditResult{S <: CapacityValuationMethod, M <: ReliabilityMetric, P <: PowerUnit}

    target_metric::M
    si_metric::SI
    eens_metric::EENS
    edlc_metric::EDLC
    capacity_value::Int
    tolerance_error::Float64
    bound_capacities::Vector{Int}
    si_metrics::Vector{SI}
    eens_metrics::Vector{EENS}
    edlc_metrics::Vector{EDLC}

    function CapacityCreditResult{S,M,P}(
        target_metric::M, 
        si_metric::SI, 
        eens_metric::EENS, 
        edlc_metric::EDLC,
        capacity_value::Int, 
        tolerance_error::Float64,
        bound_capacities::Vector{Int}, 
        si_metrics::Vector{SI}, 
        eens_metrics::Vector{EENS}, 
        edlc_metrics::Vector{EDLC}) where {S,M,P}

        length(bound_capacities) == length(eens_metrics) ||
            throw(ArgumentError("Lengths of bound_capacities and metrics must match"))

         new{S,M,P}(
            target_metric, 
            si_metric, 
            eens_metric, 
            edlc_metric, 
            capacity_value, 
            tolerance_error, 
            bound_capacities, 
            si_metrics, 
            eens_metrics, 
            edlc_metrics)
    end
end
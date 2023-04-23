abstract type CapacityValuationMethod{M<:ReliabilityMetric} end

struct CapacityCreditResult{S <: CapacityValuationMethod, M <: ReliabilityMetric, P <: PowerUnit}

    target_metric::M
    lowerbound::Float64
    upperbound::Float64
    bound_capacities::Vector{Float64}
    bound_metrics::Vector{M}

    function CapacityCreditResult{S,M,P}(
        target_metric::M, lowerbound::Float64, upperbound::Float64,
        bound_capacities::Vector{Float64}, bound_metrics::Vector{M}) where {S,M,P}

        length(bound_capacities) == length(bound_metrics) ||
            throw(ArgumentError("Lengths of bound_capacities and bound_metrics must match"))

         new{S,M,P}(target_metric, lowerbound, upperbound, bound_capacities, bound_metrics)
    end
end

minimum(x::CapacityCreditResult) = x.lowerbound
maximum(x::CapacityCreditResult) = x.upperbound
extrema(x::CapacityCreditResult) = (x.lowerbound, x.upperbound)

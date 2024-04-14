struct Utilization <: ResultSpec end
abstract type AbstractUtilizationResult{N,L,T} <: Result{N,L,T} end

# Colon indexing

getindex(x::AbstractUtilizationResult, ::Colon) = getindex.(x, x.branches)
getindex(x::AbstractUtilizationResult, ::Colon, t::ZonedDateTime) = getindex.(x, x.branches, t)
getindex(x::AbstractUtilizationResult, i::Pair{<:Int,<:Int}, ::Colon) = getindex.(x, i, x.timestamps)
getindex(x::AbstractUtilizationResult, ::Colon, ::Colon) = getindex.(x, x.branches, permutedims(x.timestamps))

PTV(x::AbstractUtilizationResult, ::Colon) = PTV.(x, x.branches)
PTV(x::AbstractUtilizationResult, ::Colon, t::ZonedDateTime) = PTV.(x, x.branches, t)
PTV(x::AbstractUtilizationResult, i::Pair{<:Int,<:Int}, ::Colon) = PTV.(x, i, x.timestamps)
PTV(x::AbstractUtilizationResult, ::Colon, ::Colon) = PTV.(x, x.branches, permutedims(x.timestamps))

# Sample-averaged utilization data
struct UtilizationResult{N,L,T<:Period} <: AbstractUtilizationResult{N,L,T}

    nsamples::Union{Int,Nothing}
    branches::Vector{Pair{Int,Int}}
    timestamps::StepRange{ZonedDateTime,T}
    utilization_mean::Matrix{Float64}
    utilization_branch_std::Vector{Float64}
    utilization_branchperiod_std::Matrix{Float64}
    ptv_mean::Matrix{Float64}
    ptv_branch_std::Vector{Float64}
    ptv_branchperiod_std::Matrix{Float64}
end

function getindex(x::UtilizationResult, i::Pair{<:Int,<:Int})
    i_i, _ = findfirstunique_directional(x.branches, i)
    return mean(view(x.utilization_mean, i_i, :)), x.utilization_branch_std[i_i]
end

function getindex(x::UtilizationResult, i::Pair{<:Int,<:Int}, t::ZonedDateTime)
    i_i, _ = findfirstunique_directional(x.branches, i)
    i_t = findfirstunique(x.timestamps, t)
    return x.utilization_mean[i_i, i_t], x.utilization_branchperiod_std[i_i, i_t]
end

function PTV(x::UtilizationResult, i::Pair{<:Int,<:Int})
    i_i, _ = findfirstunique_directional(x.branches, i)
    return mean(view(x.ptv_mean, i_i, :)), x.ptv_branch_std[i_i]
end

function PTV(x::UtilizationResult, i::Pair{<:Int,<:Int}, t::ZonedDateTime)
    i_i, _ = findfirstunique_directional(x.branches, i)
    i_t = findfirstunique(x.timestamps, t)
    return x.ptv_mean[i_i, i_t], x.ptv_branchperiod_std[i_i, i_t]
end

# Full utilization data

struct UtilizationSamples <: ResultSpec end

struct UtilizationSamplesResult{N,L,T<:Period} <: AbstractUtilizationResult{N,L,T}
    branches::Vector{Pair{Int,Int}}
    timestamps::StepRange{ZonedDateTime,T}
    utilization::Array{Float64,3}
end

function getindex(x::UtilizationSamplesResult, i::Pair{<:Int,<:Int})
    i_i, _ = findfirstunique_directional(x.branches, i)
    return vec(mean(view(x.utilization, i_i, :, :), dims=1))
end

function getindex(x::UtilizationSamplesResult, i::Pair{<:Int,<:Int}, t::ZonedDateTime)
    i_i, _ = findfirstunique_directional(x.branches, i)
    i_t = findfirstunique(x.timestamps, t)
    return vec(x.utilization[i_i, i_t, :])
end

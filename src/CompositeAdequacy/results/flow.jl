struct Flow <: ResultSpec end
abstract type AbstractFlowResult{N,L,T} <: Result{N,L,T} end

# Colon indexing

getindex(x::AbstractFlowResult, ::Colon) =
    getindex.(x, x.branches)

getindex(x::AbstractFlowResult, ::Colon, t::ZonedDateTime) =
    getindex.(x, x.branches, t)

getindex(x::AbstractFlowResult, i::Pair{<:AbstractString,<:AbstractString}, ::Colon) =
    getindex.(x, i, x.timestamps)

getindex(x::AbstractFlowResult, ::Colon, ::Colon) =
    getindex.(x, x.branches, permutedims(x.timestamps))


# Sample-averaged flow data
struct FlowResult{N,L,T<:Period,U<:PerUnit} <: AbstractFlowResult{N,L,T}

    nsamples::Union{Int,Nothing}
    branches::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    flow_mean::Matrix{Float16}
    flow_branch_std::Vector{Float16}
    flow_branchperiod_std::Matrix{Float16}
    
end


# Full flow data
struct FlowTotal <: ResultSpec end
struct FlowTotalResult{N,L,T<:Period,U<:PerUnit} <: AbstractFlowResult{N,L,T}

    nsamples::Union{Int,Nothing}
    branches::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    total::Array{Float16,3}

end


struct FlowSamples <: ResultSpec end
struct FlowSamplesResult{N,L,T<:Period,U<:PerUnit} <: AbstractFlowResult{N,L,T}

    branches::Vector{Pair{String,String}}
    timestamps::StepRange{ZonedDateTime,T}
    flow::Array{Float16,3}

end

function getindex(x::FlowSamplesResult, i::Pair{<:AbstractString,<:AbstractString})
    i_i, reverse = findfirstunique_directional(x.branches, i)
    flow = vec(mean(view(x.flow, i_i, :, :), dims=1))
    return reverse ? -flow : flow
end


function getindex(x::FlowSamplesResult, i::Pair{<:AbstractString,<:AbstractString}, t::ZonedDateTime)
    i_i, reverse = findfirstunique_directional(x.branches, i)
    i_t = findfirstunique(x.timestamps, t)
    flow = vec(x.flow[i_i, i_t, :])
    return reverse ? -flow : flow
end
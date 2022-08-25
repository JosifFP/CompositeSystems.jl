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

struct FlowResult{N,L,T<:Period,U<:PerUnit} <: AbstractFlowResult{N,L,T}

    nsamples::Union{Int,Nothing}
    branches::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    pf::Matrix{Float16}

end
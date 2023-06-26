""
abstract type AbstractAvailabilityResult{N,L,T} <: Result{N,L,T} end

# Colon indexing
getindex(x::AbstractAvailabilityResult, ::Colon, t::ZonedDateTime) = getindex.(x, keys(x), t)
getindex(x::AbstractAvailabilityResult, key::Int, ::Colon) = getindex.(x, key, x.timestamps)
getindex(x::AbstractAvailabilityResult, ::Colon, ::Colon) = getindex.(x, keys(x), permutedims(x.timestamps))

"Full Generator availability data"
struct GeneratorAvailability <: ResultSpec end

""
struct GeneratorAvailabilityResult{N,L,T<:Period} <: AbstractAvailabilityResult{N,L,T}
    generators::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    available::Array{Bool,3}
end

keys(x::GeneratorAvailabilityResult) = x.generators

""
function getindex(x::GeneratorAvailabilityResult, g::Int, t::ZonedDateTime)
    i_g = findfirstunique(x.generators, g)
    i_t = findfirstunique(x.timestamps, t)
    return vec(x.available[i_g, i_t, :])
end

"Full Storage availability data"
struct StorageAvailability <: ResultSpec end

""
struct StorageAvailabilityResult{N,L,T<:Period} <: AbstractAvailabilityResult{N,L,T}
    storages::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    available::Array{Bool,3}
end

keys(x::StorageAvailabilityResult) = x.storages

""
function getindex(x::StorageAvailabilityResult, s::Int, t::ZonedDateTime)
    i_s = findfirstunique(x.storages, s)
    i_t = findfirstunique(x.timestamps, t)
    return vec(x.available[i_s, i_t, :])
end

"Full Branch availability data"
struct BranchAvailability <: ResultSpec end

""
struct BranchAvailabilityResult{N,L,T<:Period} <: AbstractAvailabilityResult{N,L,T}
    branches::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    available::Array{Bool,3}
end

keys(x::BranchAvailabilityResult) = x.branches

""
function getindex(x::BranchAvailabilityResult, l::Int, t::ZonedDateTime)
    i_l = findfirstunique(x.branches, l)
    i_t = findfirstunique(x.timestamps, t)
    return vec(x.available[i_l, i_t, :])
end

"Full Shunt availability data"
struct ShuntAvailability <: ResultSpec end

""
struct ShuntAvailabilityResult{N,L,T<:Period} <: AbstractAvailabilityResult{N,L,T}
    shunts::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    available::Array{Bool,3}
end

keys(x::ShuntAvailabilityResult) = x.shunts

""
function getindex(x::ShuntAvailabilityResult, l::Int, t::ZonedDateTime)
    i_l = findfirstunique(x.shunts, l)
    i_t = findfirstunique(x.timestamps, t)
    return vec(x.available[i_l, i_t, :])
end

#"Full Bus availability data"
# struct BusAvailability <: ResultSpec end

# ""
# struct BusAvailabilityResult{N,L,T<:Period} <: AbstractAvailabilityResult{N,L,T}
#     buses::Vector{Int}
#     timestamps::StepRange{ZonedDateTime,T}
#     available::Array{Bool,3}
# end

# keys(x::BusAvailabilityResult) = x.buses

# ""
# function getindex(x::BusAvailabilityResult, l::Int, t::ZonedDateTime)
#     i_l = findfirstunique(x.buses, l)
#     i_t = findfirstunique(x.timestamps, t)
#     return vec(x.available[i_l, i_t, :])
# end
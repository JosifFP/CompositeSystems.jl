struct Shortfall <: ResultSpec end
abstract type AbstractShortfallResult{N,L,T} <: Result{N,L,T} end

# Colon indexing

getindex(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) =
    getindex.(x, x.loads, t)

getindex(x::AbstractShortfallResult, r::Int, ::Colon) =
    getindex.(x, r, x.timestamps)

getindex(x::AbstractShortfallResult, ::Colon, ::Colon) =
    getindex.(x, x.loads, permutedims(x.timestamps))


LOLE(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) =
    LOLE.(x, x.loads, t)

LOLE(x::AbstractShortfallResult, r::Int, ::Colon) =
    LOLE.(x, r, x.timestamps)

LOLE(x::AbstractShortfallResult, ::Colon, ::Colon) =
    LOLE.(x, x.loads, permutedims(x.timestamps))


EENS(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) =
    EENS.(x, x.loads, t)

EENS(x::AbstractShortfallResult, r::Int, ::Colon) =
    EENS.(x, r, x.timestamps)

EENS(x::AbstractShortfallResult, ::Colon, ::Colon) =
    EENS.(x, x.loads, permutedims(x.timestamps))

# Sample-averaged shortfall data

struct ShortfallResult{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit} <: AbstractShortfallResult{N,L,T}

    nsamples::Union{Int,Nothing}
    loads::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}

    eventperiod_mean::Float64
    eventperiod_std::Float64

    eventperiod_bus_mean::Vector{Float64}
    eventperiod_bus_std::Vector{Float64}

    eventperiod_period_mean::Vector{Float64}
    eventperiod_period_std::Vector{Float64}

    eventperiod_busperiod_mean::Matrix{Float64}
    eventperiod_busperiod_std::Matrix{Float64}

    e_shortfall_mean::Matrix{Float64} # r x t
    e_shortfall_std::Float64
    e_shortfall_bus_std::Vector{Float64}
    e_shortfall_period_std::Vector{Float64}
    e_shortfall_busperiod_std::Matrix{Float64}

    function ShortfallResult{N,L,T,P,E}(
        nsamples::Union{Int,Nothing},
        loads::Vector{Int},
        timestamps::StepRange{ZonedDateTime,T},
        eventperiod_mean::Float64,
        eventperiod_std::Float64,
        eventperiod_bus_mean::Vector{Float64},
        eventperiod_bus_std::Vector{Float64},
        eventperiod_period_mean::Vector{Float64},
        eventperiod_period_std::Vector{Float64},
        eventperiod_busperiod_mean::Matrix{Float64},
        eventperiod_busperiod_std::Matrix{Float64},

        e_shortfall_mean::Matrix{Float64},
        e_shortfall_std::Float64,
        e_shortfall_bus_std::Vector{Float64},
        e_shortfall_period_std::Vector{Float64},
        e_shortfall_busperiod_std::Matrix{Float64},

    ) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit}

        isnothing(nsamples) || nsamples > 0 ||
            throw(DomainError("Sample count must be positive or `nothing`."))


        length(timestamps) == N ||
            error("The provided timestamp range does not match the simulation length")

        nloads = length(loads)

        length(eventperiod_bus_mean) == nloads &&
        length(eventperiod_bus_std) == nloads &&
        length(eventperiod_period_mean) == N &&
        length(eventperiod_period_std) == N &&
        size(eventperiod_busperiod_mean) == (nloads, N) &&
        size(eventperiod_busperiod_std) == (nloads, N) &&

        length(e_shortfall_bus_std) == nloads &&
        length(e_shortfall_period_std) == N &&
        size(e_shortfall_busperiod_std) == (nloads, N) ||
            error("Inconsistent input data sizes")

        new{N,L,T,P,E}(nsamples, loads, timestamps,
            eventperiod_mean, eventperiod_std,
            eventperiod_bus_mean, eventperiod_bus_std,
            eventperiod_period_mean, eventperiod_period_std,
            eventperiod_busperiod_mean, eventperiod_busperiod_std,
            e_shortfall_mean, e_shortfall_std,
            e_shortfall_bus_std, e_shortfall_period_std,
            e_shortfall_busperiod_std)

    end

end

LOLE(x::ShortfallResult{N,L,T}) where {N,L,T} =
    LOLE{N,L,T}(MeanEstimate(x.eventperiod_mean,
                             x.eventperiod_std,
                             x.nsamples))

function LOLE(x::ShortfallResult{N,L,T}, r::Int) where {N,L,T}
    i_r = getindex(x.loads, r)
    return LOLE{N,L,T}(MeanEstimate(x.eventperiod_bus_mean[i_r],
                                    x.eventperiod_bus_std[i_r],
                                    x.nsamples))
end

function LOLE(x::ShortfallResult{N,L,T}, t::ZonedDateTime) where {N,L,T}
    i_t = findfirstunique(x.timestamps, t)
    return LOLE{1,L,T}(MeanEstimate(x.eventperiod_period_mean[i_t],
                                    x.eventperiod_period_std[i_t],
                                    x.nsamples))
end

function LOLE(x::ShortfallResult{N,L,T}, r::Int, t::ZonedDateTime) where {N,L,T}
    i_r = getindex(x.loads, r)
    i_t = findfirstunique(x.timestamps, t)
    return LOLE{1,L,T}(MeanEstimate(x.eventperiod_busperiod_mean[i_r, i_t],
                                    x.eventperiod_busperiod_std[i_r, i_t],
                                    x.nsamples))
end


EENS(x::ShortfallResult{N,L,T,P,E}) where {N,L,T,P,E} =
    EENS{N,L,T,E}(MeanEstimate(sum(x.e_shortfall_mean), 
                                x.e_shortfall_std, 
                                x.nsamples))


function EENS(x::ShortfallResult{N,L,T,P,E}, r::Int) where {N,L,T,P,E}
    i_r = getindex(x.loads, r)
    return EENS{N,L,T,E}(MeanEstimate(sum(view(x.e_shortfall_mean, i_r, :)), 
                                        x.e_shortfall_bus_std[i_r], 
                                        x.nsamples))
end

function  EENS(x::ShortfallResult{N,L,T,P,E}, t::ZonedDateTime) where {N,L,T,P,E}
    i_t = findfirstunique(x.timestamps, t)
    return EENS{1,L,T,E}(MeanEstimate(sum(view(x.e_shortfall_mean, :, i_t)), 
                                        x.e_shortfall_period_std[i_t],
                                        x.nsamples))
end

function EENS(x::ShortfallResult{N,L,T,P,E}, r::Int, t::ZonedDateTime) where {N,L,T,P,E}
    i_r = getindex(x.loads, r)
    i_t = findfirstunique(x.timestamps, t)
    return EENS{1,L,T,E}(MeanEstimate(x.e_shortfall_mean[i_r, i_t], 
                                        x.e_shortfall_busperiod_std[i_r, i_t], 
                                        x.nsamples))
end

#TO BE FIXED
function EDNS(x::ShortfallResult{N,L,T,P,E}, r::Int) where {N,L,T,P,E}
    i_r = getindex(x.loads, r)
    return EDNS{N,L,T,P}(MeanEstimate(sum(view(x.e_shortfall_mean, i_r, :)), 
                                        x.e_shortfall_bus_std[i_r], 
                                        x.nsamples))
end



# Full shortfall data
struct ShortfallSamples <: ResultSpec end

struct ShortfallSamplesResult{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit} <: AbstractShortfallResult{N,L,T}

    loads::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    p_shortfall::Array{Float32,3} # r x t x s
    e_shortfall::Array{Float32,3} # r x t x s

end

function LOLE(x::ShortfallSamplesResult{N,L,T}) where {N,L,T}
    eventperiods = sum(sum(x.e_shortfall, dims=1) .> 0, dims=2)
    return LOLE{N,L,T}(MeanEstimate(eventperiods))
end

function LOLE(x::ShortfallSamplesResult{N,L,T}, r::Int) where {N,L,T}
    i_r = getindex(x.loads, r)
    eventperiods = sum(view(x.e_shortfall, i_r, :, :) .> 0, dims=1)
    return LOLE{N,L,T}(MeanEstimate(eventperiods))
end

function LOLE(x::ShortfallSamplesResult{N,L,T}, t::ZonedDateTime) where {N,L,T}
    i_t = findfirstunique(x.timestamps, t)
    eventperiods = sum(view(x.e_shortfall, :, i_t, :), dims=1) .> 0
    return LOLE{1,L,T}(MeanEstimate(eventperiods))
end

function LOLE(x::ShortfallSamplesResult{N,L,T}, r::Int, t::ZonedDateTime) where {N,L,T}
    i_r = getindex(x.loads, r)
    i_t = findfirstunique(x.timestamps, t)
    eventperiods = view(x.e_shortfall, i_r, i_t, :) .> 0
    return LOLE{1,L,T}(MeanEstimate(eventperiods))
end

EENS(x::ShortfallSamplesResult{N,L,T,P,E}) where {N,L,T,P,E} =
    EENS{N,L,T,E}(MeanEstimate(vec(sum(x.e_shortfall, dims=1:2))))

function EENS(x::ShortfallSamplesResult{N,L,T,P,E}, r::Int) where {N,L,T,P,E}
    i_r = getindex(x.loads, r)
    return EENS{N,L,T,E}(vec(sum(view(x.e_shortfall, i_r, :, :), dims=1)))
end

function  EENS(x::ShortfallSamplesResult{N,L,T,P,E}, t::ZonedDateTime) where {N,L,T,P,E}
    i_t = findfirstunique(x.timestamps, t)
    return EENS{1,L,T,E}(vec(sum(view(x.e_shortfall, :, i_t, :), dims=1)))
end

function EENS(x::ShortfallSamplesResult{N,L,T,P,E}, r::Int, t::ZonedDateTime) where {N,L,T,P,E}
    i_r = getindex(x.loads, r)
    i_t = findfirstunique(x.timestamps, t)
    return EENS{1,L,T,E}(vec(x.e_shortfall[i_r, i_t, :]))
end
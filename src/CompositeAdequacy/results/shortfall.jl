struct Shortfall <: ResultSpec end
abstract type AbstractShortfallResult{N,L,T} <: Result{N,L,T} end

# Colon indexing

getindex(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) = getindex.(x, x.buses, t)
getindex(x::AbstractShortfallResult, r::Int, ::Colon) = getindex.(x, r, x.timestamps)
getindex(x::AbstractShortfallResult, ::Colon, ::Colon) = getindex.(x, x.buses, permutedims(x.timestamps))

EDLC(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) = EDLC.(x, x.buses, t)
EDLC(x::AbstractShortfallResult, r::Int, ::Colon) = EDLC.(x, r, x.timestamps)
EDLC(x::AbstractShortfallResult, ::Colon, ::Colon) = EDLC.(x, x.buses, permutedims(x.timestamps))

EENS(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) = EENS.(x, x.buses, t)
EENS(x::AbstractShortfallResult, r::Int, ::Colon) = EENS.(x, r, x.timestamps)
EENS(x::AbstractShortfallResult, ::Colon, ::Colon) = EENS.(x, x.buses, permutedims(x.timestamps))

SI(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) = SI.(x, x.buses, t)
SI(x::AbstractShortfallResult, r::Int, ::Colon) = SI.(x, r, x.timestamps)
SI(x::AbstractShortfallResult, ::Colon, ::Colon) = SI.(x, x.buses, permutedims(x.timestamps))

# Sample-averaged shortfall data
struct ShortfallResult{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit} <: AbstractShortfallResult{N,L,T}

    nsamples::Union{Int,Nothing}
    buses::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}

    eventperiod_mean::Float64
    eventperiod_std::Float64
    eventperiod_bus_mean::Vector{Float64}
    eventperiod_bus_std::Vector{Float64}

    eventperiod_period_mean::Vector{Float64}
    eventperiod_period_std::Vector{Float64}
    eventperiod_busperiod_mean::Matrix{Float64}
    eventperiod_busperiod_std::Matrix{Float64}

    system_peakload::Float64
    bus_peakload::Vector{Float64}

    shortfall_mean::Matrix{Float64} # r x t
    shortfall_std::Float64
    shortfall_bus_std::Vector{Float64}
    shortfall_period_std::Vector{Float64}
    shortfall_busperiod_std::Matrix{Float64}

    function ShortfallResult{N,L,T,P,E}(
        nsamples::Union{Int,Nothing},
        buses::Vector{Int},
        timestamps::StepRange{ZonedDateTime,T},
        eventperiod_mean::Float64,
        eventperiod_std::Float64,
        eventperiod_bus_mean::Vector{Float64},
        eventperiod_bus_std::Vector{Float64},
        eventperiod_period_mean::Vector{Float64},
        eventperiod_period_std::Vector{Float64},
        eventperiod_busperiod_mean::Matrix{Float64},
        eventperiod_busperiod_std::Matrix{Float64},
        system_peakload::Float64,
        bus_peakload::Vector{Float64},
        shortfall_mean::Matrix{Float64},
        shortfall_std::Float64,
        shortfall_bus_std::Vector{Float64},
        shortfall_period_std::Vector{Float64},
        shortfall_busperiod_std::Matrix{Float64},

    ) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit}

        isnothing(nsamples) || nsamples > 0 || throw(DomainError("Sample count must be positive or `nothing`."))
        length(timestamps) == N || error("The provided timestamp range does not match the simulation length")

        nbuses = length(buses)
        length(eventperiod_bus_mean) == nbuses &&
        length(eventperiod_bus_std) == nbuses &&
        length(eventperiod_period_mean) == N &&
        length(eventperiod_period_std) == N &&
        size(eventperiod_busperiod_mean) == (nbuses, N) &&
        size(eventperiod_busperiod_std) == (nbuses, N) &&
        length(bus_peakload) == nbuses &&
        length(shortfall_bus_std) == nbuses &&
        length(shortfall_period_std) == N &&
        size(shortfall_busperiod_std) == (nbuses, N) || error("Inconsistent input data sizes")

        new{N,L,T,P,E}(nsamples, buses, timestamps,
            eventperiod_mean, eventperiod_std,
            eventperiod_bus_mean, eventperiod_bus_std,
            eventperiod_period_mean, eventperiod_period_std,
            eventperiod_busperiod_mean, eventperiod_busperiod_std,
            system_peakload, bus_peakload,
            shortfall_mean, shortfall_std,
            shortfall_bus_std, shortfall_period_std,
            shortfall_busperiod_std)
    end

end

""
function getindex(x::ShortfallResult)
    return sum(x.shortfall_mean), x.shortfall_std
end

""
function getindex(x::ShortfallResult, r::Int)
    i_r = findfirstunique(x.buses, r)
    return sum(view(x.shortfall_mean, i_r, :)), x.shortfall_bus_std[i_r]
end

""
function getindex(x::ShortfallResult, t::ZonedDateTime)
    i_t = findfirstunique(x.timestamps, t)
    return sum(view(x.shortfall_mean, :, i_t)), x.shortfall_period_std[i_t]
end

""
function getindex(x::ShortfallResult, r::Int, t::ZonedDateTime)
    i_r = findfirstunique(x.buses, r)
    i_t = findfirstunique(x.timestamps, t)
    return x.shortfall_mean[i_r, i_t], x.shortfall_busperiod_std[i_r, i_t]
end

""
EDLC(x::ShortfallResult{N,L,T}) where {N,L,T} = 
    EDLC{N,L,T}(MeanEstimate(x.eventperiod_mean, x.eventperiod_std, x.nsamples))

""
function EDLC(x::ShortfallResult{N,L,T}, r::Int) where {N,L,T<:Period}
    i_r = getindex(x.buses, r)
    return EDLC{N,L,T}(MeanEstimate(x.eventperiod_bus_mean[i_r],
                                    x.eventperiod_bus_std[i_r],
                                    x.nsamples))
end

""
function EDLC(x::ShortfallResult{N,L,T}, t::ZonedDateTime) where {N,L,T<:Period}
    i_t = findfirstunique(x.timestamps, t)
    return EDLC{1,L,T}(MeanEstimate(x.eventperiod_period_mean[i_t],
                                    x.eventperiod_period_std[i_t],
                                    x.nsamples))
end

""
function EDLC(x::ShortfallResult{N,L,T}, r::Int, t::ZonedDateTime) where {N,L,T<:Period}
    i_r = getindex(x.buses, r)
    i_t = findfirstunique(x.timestamps, t)
    return EDLC{1,L,T}(MeanEstimate(x.eventperiod_busperiod_mean[i_r, i_t],
                                    x.eventperiod_busperiod_std[i_r, i_t],
                                    x.nsamples))
end


EENS(x::ShortfallResult{N,L,T,P,E}) where {N,L,T,P,E} = EENS{N,L,T,E}(MeanEstimate(x[]..., x.nsamples))
EENS(x::ShortfallResult{N,L,T,P,E}, r::Int) where {N,L,T,P,E} = EENS{N,L,T,E}(MeanEstimate(x[r]..., x.nsamples))
EENS(x::ShortfallResult{N,L,T,P,E}, t::ZonedDateTime) where {N,L,T,P,E} = EENS{1,L,T,E}(MeanEstimate(x[t]..., x.nsamples))
EENS(x::ShortfallResult{N,L,T,P,E}, r::Int, t::ZonedDateTime) where {N,L,T,P,E} = EENS{1,L,T,E}(MeanEstimate(x[r, t]..., x.nsamples))

""
SI(x::ShortfallResult{N,L,T}) where {N,L,T<:Period} = 
    SI{N,L,T}(MeanEstimate(sum(x.shortfall_mean)*(60/x.system_peakload), 
                            x.shortfall_std*(60/x.system_peakload), 
                            x.nsamples))

""
function SI(x::ShortfallResult{N,L,T}, r::Int) where {N,L,T<:Period}
    i_r = findfirstunique(x.buses, r)
    return SI{N,L,T}(MeanEstimate(sum(view(x.shortfall_mean, i_r, :)).*(60/x.system_peakload),
                                    x.shortfall_bus_std[i_r].*(60/x.system_peakload),
                                    x.nsamples))
end

""
function SI(x::ShortfallResult{N,L,T}, t::ZonedDateTime) where {N,L,T<:Period}
    i_t = findfirstunique(x.timestamps, t)
    return SI{1,L,T}(MeanEstimate(sum(view(x.shortfall_mean, :, i_t)).*(60/x.system_peakload),
                                    x.shortfall_period_std[i_t].*(60/x.system_peakload),
                                    x.nsamples))
end

""
function SI(x::ShortfallResult{N,L,T}, r::Int, t::ZonedDateTime) where {N,L,T<:Period}
    i_r = findfirstunique(x.buses, r)
    i_t = findfirstunique(x.timestamps, t)
    return SI{1,L,T}(MeanEstimate(x.shortfall_mean[i_r, i_t].*(60/x.system_peakload),
                                    x.shortfall_busperiod_std[i_r, i_t].*(60/x.system_peakload),
                                    x.nsamples))
end


# Full shortfall data
struct ShortfallSamples <: ResultSpec end

struct ShortfallSamplesResult{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit} <: AbstractShortfallResult{N,L,T}
    buses::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    p_shortfall::Array{Float32,3} # r x t x s
    shortfall::Array{Float32,3} # r x t x s
end

function EDLC(x::ShortfallSamplesResult{N,L,T}) where {N,L,T}
    eventperiods = sum(sum(x.shortfall, dims=1) .> 0, dims=2)
    return EDLC{N,L,T}(MeanEstimate(eventperiods))
end

function EDLC(x::ShortfallSamplesResult{N,L,T}, r::Int) where {N,L,T}
    i_r = getindex(x.buses, r)
    eventperiods = sum(view(x.shortfall, i_r, :, :) .> 0, dims=1)
    return EDLC{N,L,T}(MeanEstimate(eventperiods))
end

function EDLC(x::ShortfallSamplesResult{N,L,T}, t::ZonedDateTime) where {N,L,T}
    i_t = findfirstunique(x.timestamps, t)
    eventperiods = sum(view(x.shortfall, :, i_t, :), dims=1) .> 0
    return EDLC{1,L,T}(MeanEstimate(eventperiods))
end

function EDLC(x::ShortfallSamplesResult{N,L,T}, r::Int, t::ZonedDateTime) where {N,L,T}
    i_r = getindex(x.buses, r)
    i_t = findfirstunique(x.timestamps, t)
    eventperiods = view(x.shortfall, i_r, i_t, :) .> 0
    return EDLC{1,L,T}(MeanEstimate(eventperiods))
end

EENS(x::ShortfallSamplesResult{N,L,T,P,E}) where {N,L,T,P,E} = EENS{N,L,T,E}(MeanEstimate(vec(sum(x.shortfall, dims=1:2))))

function EENS(x::ShortfallSamplesResult{N,L,T,P,E}, r::Int) where {N,L,T,P,E}
    i_r = getindex(x.buses, r)
    return EENS{N,L,T,E}(vec(sum(view(x.shortfall, i_r, :, :), dims=1)))
end

function  EENS(x::ShortfallSamplesResult{N,L,T,P,E}, t::ZonedDateTime) where {N,L,T,P,E}
    i_t = findfirstunique(x.timestamps, t)
    return EENS{1,L,T,E}(vec(sum(view(x.shortfall, :, i_t, :), dims=1)))
end

function EENS(x::ShortfallSamplesResult{N,L,T,P,E}, r::Int, t::ZonedDateTime) where {N,L,T,P,E}
    i_r = getindex(x.buses, r)
    i_t = findfirstunique(x.timestamps, t)
    return EENS{1,L,T,E}(vec(x.shortfall[i_r, i_t, :]))
end
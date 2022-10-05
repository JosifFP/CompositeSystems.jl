struct Shortfall <: ResultSpec end
abstract type AbstractShortfallResult{N,L,T} <: Result{N,L,T} end

# Colon indexing

getindex(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) =
    getindex.(x, x.load_buses, t)

getindex(x::AbstractShortfallResult, r::Int, ::Colon) =
    getindex.(x, r, x.timestamps)

getindex(x::AbstractShortfallResult, ::Colon, ::Colon) =
    getindex.(x, x.load_buses, permutedims(x.timestamps))


LOLE(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) =
    LOLE.(x, x.load_buses, t)

LOLE(x::AbstractShortfallResult, r::Int, ::Colon) =
    LOLE.(x, r, x.timestamps)

LOLE(x::AbstractShortfallResult, ::Colon, ::Colon) =
    LOLE.(x, x.load_buses, permutedims(x.timestamps))


EUE(x::AbstractShortfallResult, ::Colon, t::ZonedDateTime) =
    EUE.(x, x.load_buses, t)

EUE(x::AbstractShortfallResult, r::Int, ::Colon) =
    EUE.(x, r, x.timestamps)

EUE(x::AbstractShortfallResult, ::Colon, ::Colon) =
    EUE.(x, x.load_buses, permutedims(x.timestamps))

# Sample-averaged shortfall data

struct ShortfallResult{N,L,T<:Period,U<:PerUnit} <: AbstractShortfallResult{N,L,T}

    nsamples::Union{Int,Nothing}
    load_buses::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}

    eventperiod_mean::Float64
    eventperiod_std::Float64

    eventperiod_bus_mean::Vector{Float64}
    eventperiod_bus_std::Vector{Float64}

    eventperiod_period_mean::Vector{Float64}
    eventperiod_period_std::Vector{Float64}

    eventperiod_busperiod_mean::Matrix{Float64}
    eventperiod_busperiod_std::Matrix{Float64}


    shortfall_mean::Matrix{Float64} # r x t

    shortfall_std::Float64
    shortfall_bus_std::Vector{Float64}
    shortfall_period_std::Vector{Float64}
    shortfall_busperiod_std::Matrix{Float64}

    flow_mean::Matrix{Float64}

    function ShortfallResult{N,L,T,U}(
        nsamples::Union{Int,Nothing},
        load_buses::Vector{Int},
        timestamps::StepRange{ZonedDateTime,T},
        eventperiod_mean::Float64,
        eventperiod_std::Float64,
        eventperiod_bus_mean::Vector{Float64},
        eventperiod_bus_std::Vector{Float64},
        eventperiod_period_mean::Vector{Float64},
        eventperiod_period_std::Vector{Float64},
        eventperiod_busperiod_mean::Matrix{Float64},
        eventperiod_busperiod_std::Matrix{Float64},
        shortfall_mean::Matrix{Float64},
        shortfall_std::Float64,
        shortfall_bus_std::Vector{Float64},
        shortfall_period_std::Vector{Float64},
        shortfall_busperiod_std::Matrix{Float64},

        flow_mean::Matrix{Float64}

    ) where {N,L,T<:Period,U<:PerUnit}

        isnothing(nsamples) || nsamples > 0 ||
            throw(DomainError("Sample count must be positive or `nothing`."))


        length(timestamps) == N ||
            error("The provided timestamp range does not match the simulation length")

        nloadbuses = length(load_buses)

        length(eventperiod_bus_mean) == nloadbuses &&
        length(eventperiod_bus_std) == nloadbuses &&
        length(eventperiod_period_mean) == N &&
        length(eventperiod_period_std) == N &&
        size(eventperiod_busperiod_mean) == (nloadbuses, N) &&
        size(eventperiod_busperiod_std) == (nloadbuses, N) &&
        length(shortfall_bus_std) == nloadbuses &&
        length(shortfall_period_std) == N &&
        size(shortfall_busperiod_std) == (nloadbuses, N) ||
            error("Inconsistent input data sizes")

        new{N,L,T,U}(nsamples, load_buses, timestamps,
            eventperiod_mean, eventperiod_std,
            eventperiod_bus_mean, eventperiod_bus_std,
            eventperiod_period_mean, eventperiod_period_std,
            eventperiod_busperiod_mean, eventperiod_busperiod_std,
            shortfall_mean, shortfall_std,
            shortfall_bus_std, shortfall_period_std,
            shortfall_busperiod_std, flow_mean)

    end

end

function getindex(x::ShortfallResult)
    return sum(x.shortfall_mean), x.shortfall_std
end

function getindex(x::ShortfallResult, r::Int)
    i_r = getindex(x.load_buses, r)
    return sum(view(x.shortfall_mean, i_r, :)), x.shortfall_bus_std[i_r]
end

function getindex(x::ShortfallResult, t::ZonedDateTime)
    i_t = findfirstunique(x.timestamps, t)
    return sum(view(x.shortfall_mean, :, i_t)), x.shortfall_period_std[i_t]
end

function getindex(x::ShortfallResult, r::Int, t::ZonedDateTime)
    i_r = getindex(x.load_buses, r)
    i_t = findfirstunique(x.timestamps, t)
    return x.shortfall_mean[i_r, i_t], x.shortfall_busperiod_std[i_r, i_t]
end


LOLE(x::ShortfallResult{N,L,T}) where {N,L,T} =
    LOLE{N,L,T}(MeanEstimate(x.eventperiod_mean,
                             x.eventperiod_std,
                             x.nsamples))

function LOLE(x::ShortfallResult{N,L,T}, r::Int) where {N,L,T}
    i_r = getindex(x.load_buses, r)
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
    i_r = getindex(x.load_buses, r)
    i_t = findfirstunique(x.timestamps, t)
    return LOLE{1,L,T}(MeanEstimate(x.eventperiod_busperiod_mean[i_r, i_t],
                                    x.eventperiod_busperiod_std[i_r, i_t],
                                    x.nsamples))
end


EUE(x::ShortfallResult{N,L,T,U}) where {N,L,T,U} =
    EUE{N,L,T,U}(MeanEstimate(x[]..., x.nsamples))

EUE(x::ShortfallResult{N,L,T,U}, r::Int) where {N,L,T,U} =
    EUE{N,L,T,U}(MeanEstimate(x[r]..., x.nsamples))

EUE(x::ShortfallResult{N,L,T,U}, t::ZonedDateTime) where {N,L,T,U} =
    EUE{1,L,T,U}(MeanEstimate(x[t]..., x.nsamples))

EUE(x::ShortfallResult{N,L,T,U}, r::Int, t::ZonedDateTime) where {N,L,T,U} =
    EUE{1,L,T,U}(MeanEstimate(x[r, t]..., x.nsamples))

# Full shortfall data 

struct ShortfallSamples <: ResultSpec end

struct ShortfallSamplesResult{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit} <: AbstractShortfallResult{N,L,T}

    load_buses::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}

    shortfall::Array{Float16,3} # r x t x s

end

function getindex(
    x::ShortfallSamplesResult{N,L,T,U}
) where {N,L,T,U}
    return vec(sum(x.shortfall, dims=1:2))
end

function getindex(
    x::ShortfallSamplesResult{N,L,T,U}, r::Int
) where {N,L,T,U}
    i_r = getindex(x.load_buses, r)
    return vec(sum(view(x.shortfall, i_r, :, :), dims=1))
end

function getindex(
    x::ShortfallSamplesResult{N,L,T,U}, t::ZonedDateTime
) where {N,L,T,U}
    i_t = findfirstunique(x.timestamps, t)
    return vec(sum(view(x.shortfall, :, i_t, :), dims=1))
end

function getindex(
    x::ShortfallSamplesResult{N,L,T,U}, r::Int, t::ZonedDateTime
) where {N,L,T,U}
    i_r = getindex(x.load_buses, r)
    i_t = findfirstunique(x.timestamps, t)
    return vec(x.shortfall[i_r, i_t, :])
end


function LOLE(x::ShortfallSamplesResult{N,L,T}) where {N,L,T}
    eventperiods = sum(sum(x.shortfall, dims=1) .> 0, dims=2)
    return LOLE{N,L,T}(MeanEstimate(eventperiods))
end

function LOLE(x::ShortfallSamplesResult{N,L,T}, r::Int) where {N,L,T}
    i_r = getindex(x.load_buses, r)
    eventperiods = sum(view(x.shortfall, i_r, :, :) .> 0, dims=1)
    return LOLE{N,L,T}(MeanEstimate(eventperiods))
end

function LOLE(x::ShortfallSamplesResult{N,L,T}, t::ZonedDateTime) where {N,L,T}
    i_t = findfirstunique(x.timestamps, t)
    eventperiods = sum(view(x.shortfall, :, i_t, :), dims=1) .> 0
    return LOLE{1,L,T}(MeanEstimate(eventperiods))
end

function LOLE(x::ShortfallSamplesResult{N,L,T}, r::Int, t::ZonedDateTime) where {N,L,T}
    i_r = getindex(x.load_buses, r)
    i_t = findfirstunique(x.timestamps, t)
    eventperiods = view(x.shortfall, i_r, i_t, :) .> 0
    return LOLE{1,L,T}(MeanEstimate(eventperiods))
end


EUE(x::ShortfallSamplesResult{N,L,T,U}) where {N,L,T,U} =
    EUE{N,L,T,U}(MeanEstimate(x[]))

EUE(x::ShortfallSamplesResult{N,L,T,U}, r::Int) where {N,L,T,U} =
    EUE{N,L,T,U}(MeanEstimate(x[r]))

EUE(x::ShortfallSamplesResult{N,L,T,U}, t::ZonedDateTime) where {N,L,T,U} =
    EUE{1,L,T,U}(MeanEstimate(x[t]))

EUE(x::ShortfallSamplesResult{N,L,T,U}, r::Int, t::ZonedDateTime) where {N,L,T,U} =
    EUE{1,L,T,U}(MeanEstimate(x[r, t]))

struct Report <: ResultSpec end
abstract type AbstractReportResult{N,L,T} <: Result{N,L,T} end

# Colon indexing

getindex(x::AbstractReportResult, ::Colon, t::ZonedDateTime) =
    getindex.(x, t)

getindex(x::AbstractReportResult, i::Pair{<:AbstractString,<:AbstractString}, ::Colon) =
    getindex.(x, i, x.timestamps)

getindex(x::AbstractReportResult, ::Colon, ::Colon) =
    getindex.(x, permutedims(x.timestamps))


# Sample-averaged flow data
struct ReportResult{N,L,T<:Period} <: AbstractReportResult{N,L,T}

    status::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}
    
end


# Full Report data
struct ReportTotal <: ResultSpec end
struct ReportTotalResult{N,L,T<:Period} <: AbstractReportResult{N,L,T}

    status::Vector{Int}
    timestamps::StepRange{ZonedDateTime,T}

end
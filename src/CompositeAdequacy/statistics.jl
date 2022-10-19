abstract type ReliabilityMetric end

MeanVariance = Series{ Number, Tuple{Mean{Float64, EqualWeight}, Variance{Float64, Float64, EqualWeight}}}
meanvariance() = Series(Mean(), Variance())

"It generates a sequence of seeds from a given number of samples"
function makeseeds(sampleseeds::Channel{Int}, nsamples::Int)
    for s in 1:nsamples
        put!(sampleseeds, s)
    end
    close(sampleseeds)
end

function mean_std(x::MeanVariance)
    m, v = value(x)
    return m, sqrt(v)
end

""
function mean_std(x::AbstractArray{<:MeanVariance})

    means = similar(x, Float64)
    vars = similar(means)

    for i in eachindex(x)
        m, v = mean_std(x[i])
        means[i] = m
        vars[i] = v
    end

    return means, vars

end

struct MeanEstimate

    estimate::Float64
    standarderror::Float64

    function MeanEstimate(est::Real, stderr::Real)

        stderr >= 0 || throw(DomainError(stderr,
            "Standard error of the estimate should be non-negative"))

        new(convert(Float64, est), convert(Float64, stderr))

    end

end

MeanEstimate(x::Real) = MeanEstimate(x, 0)
MeanEstimate(x::Real, ::Real, ::Nothing) = MeanEstimate(x, 0)
MeanEstimate(mu::Real, sigma::Real, n::Int) = MeanEstimate(mu, sigma / sqrt(n))

function MeanEstimate(xs::AbstractArray{<:Real})
    est = mean(xs)
    return MeanEstimate(est, std(xs, mean=est), length(xs))
end

val(est::MeanEstimate) = est.estimate
stderror(est::MeanEstimate) = est.standarderror

Base.isapprox(x::MeanEstimate, y::MeanEstimate) =
        isapprox(x.estimate, y.estimate) &&
        isapprox(x.standarderror, y.standarderror)

function Base.show(io::IO, x::MeanEstimate)
    v, s = stringprecision(x)
    print(io, v, x.standarderror > 0 ? "±"*s : "")
end

function stringprecision(x::MeanEstimate)

    if iszero(x.standarderror)

        v_rounded = @sprintf "%0.5f" x.estimate
        s_rounded = "0"

    else

        stderr_round = round(x.standarderror, sigdigits=1)

        digits = floor(Int, log(10, stderr_round))

        rounded = round(x.estimate, digits=-digits)
        reduced = round(Int, rounded / 10. ^ digits)
        v_rounded = string(Decimal(Int(x.estimate < 0), abs(reduced), digits))

        s_rounded = string(decimal(stderr_round))

    end

    return v_rounded, s_rounded

end

Base.isapprox(x::ReliabilityMetric, y::ReliabilityMetric) =
        isapprox(val(x), val(y)) && isapprox(stderror(x), stderror(y))

# Loss-of-Load Expectation

struct LOLE{N,L,T<:Period} <: ReliabilityMetric

    lole::MeanEstimate

    function LOLE{N,L,T}(lole::MeanEstimate) where {N,L,T<:Period}
        val(lole) >= 0 || throw(DomainError(val,
            "$val is not a valid expected count of event-periods"))
        new{N,L,T}(lole)
    end

end

val(x::LOLE) = val(x.lole)
stderror(x::LOLE) = stderror(x.lole)

function Base.show(io::IO, x::LOLE{N,L,T}) where {N,L,T}

    t_symbol = unitsymbol(T)
    print(io, "LOLE = ", x.lole, " event-",
          L == 1 ? t_symbol : "(" * string(L) * t_symbol * ")", "/",
          N*L == 1 ? "" : N*L, t_symbol)

end

# Expected Unserved Energy
struct EUE{N,L,T<:Period,E<:EnergyUnit} <: ReliabilityMetric

    eue::MeanEstimate

    function EUE{N,L,T,E}(eue::MeanEstimate) where {N,L,T<:Period,E<:EnergyUnit}
        val(eue) >= 0 || throw(DomainError(
            "$val is not a valid unserved energy expectation"))
        new{N,L,T,E}(eue)
    end

end

val(x::EUE) = val(x.eue)
stderror(x::EUE) = stderror(x.eue)

function Base.show(io::IO, x::EUE{N,L,T,E}) where {N,L,T,E}

    print(io, "EUE = ", x.eue, " ",
        unitsymbol(E), "/", N*L == 1 ? "" : N*L, unitsymbol(T))

end
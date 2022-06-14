using PRATS
using Test
using TimeZones
import BenchmarkTools: @btime
include("test/testsystems.jl")
using PRATS.CompositeAdequacy

timestamps_a = TestSystems.singlenode_a.timestamps
timestamprow_a = permutedims(timestamps_a)
nstderr_tol = 3
simspec = SequentialMonteCarlo(samples=100_000, seed=1)

resultspecs = (Shortfall(),GeneratorAvailability())

shortfalls, flows = assess(TestSystems.singlenode_a, simspec, Shortfall(), GeneratorAvailability())
lole, eue = LOLE(shortfalls), EUE(shortfalls)
# LOLE = 0.353±0.002 event-h/4h
# EUE = 1.57±0.01 MWh/4h

#@btime shortfalls, flows = assess(TestSystems.singlenode_a, simspec, Shortfall(), Flow())
# 175.905 ms (1500152 allocations: 424.21 MiB)
#1 THREAD, samples=100_000: 254.419 ms (1553663 allocations: 425.84 MiB)
#8 THREADS, samples=100_000: 827.547 ms (2383445 allocations: 451.19 MiB)

#-------------------------------------------------------------------------------------------

using Plots,Random,Distributions,StatsBase
lambda = 1/2940
n = 1_000
X = rand(Exponential(1/lambda),n)
X1 = trunc.(X)
histogram(X, label = false)


using Plots, BenchmarkTools
λ = Float64(1/2940);
μ = Float64(1/60);
N= Int32(8760);
@inbounds vector = ones(Bool, N)::Vector{Bool}
Array{Bool,N}(true, N)

T(λ::Float64, μ::Float64) = ((x->trunc(Int32, x)).(rand(Distributions.Exponential(1/λ))),
                                (y->trunc(Int32, y)).(rand(Distributions.Exponential(1/μ)))
)::Tuple{Int32,Int32}

function cycles!(λ::Float64, μ::Float64, N::Int32)
    @inbounds vector = ones(Bool, N)::Vector{Bool}
    (ttf,ttr) = T(λ,μ)
    i=Int(1);
    @inbounds while i + ttf + ttr  < N
        @inbounds vector[i+ttf : i+ttf+ttr] = [false for _ in i+ttf : i+ttf+ttr]
        #@inbounds vector[i+ttf : i+ttf+ttr] = zeros(Bool, ttr)
        i = i + ttf + ttr
        (ttf,ttr) = T(λ,μ)
    end
    return vector
end

function cycles!(λ::Float64, μ::Float64, vector::Vector{Bool})
    (ttf,ttr) = T(λ,μ)
    N = length(vector)
    i=Int(1);
    @inbounds while i + ttf + ttr  < N
        @inbounds vector[i+ttf : i+ttf+ttr] = [false for _ in i+ttf : i+ttf+ttr]
        #@inbounds vector[i+ttf : i+ttf+ttr] = zeros(Bool, ttr)
        i = i + ttf + ttr
        (ttf,ttr) = T(λ,μ)
    end
    return vector
end

@inbounds vector = ones(Bool, N)::Vector{Bool}
@time cycles!(λ, μ, N)
@time cycles!(λ, μ, vector)
plot(cycles!(λ, μ, vector))


@btime cycles!(λ, μ, vector)
#582.781 ns (3 allocations: 8.83 KiB)
#557.778 ns (3 allocations: 8.84 KiB)
#611.921 ns (3 allocations: 8.95 KiB)

dist = LogNormal(1.5,2)
rand(dist,5)


import Random123: Philox4x
simspec = SequentialMonteCarlo(samples=100_000, seed=1)
#rng = Philox4x((0, 0), 10)
rng = Random.GLOBAL_RNG
#Random.seed!(rng, (simspec.seed, 1))

Random.seed!(simspec.seed)
@inbounds vector = ones(Bool, N)::Vector{Bool}
plot(cycles!(λ, μ, vector))
@inbounds vector = ones(Bool, N)::Vector{Bool}
plot!(cycles!(λ, μ, vector))
Random.seed!(simspec.seed)
@inbounds vector = ones(Bool, N)::Vector{Bool}
plot!(cycles!(λ, μ, vector))
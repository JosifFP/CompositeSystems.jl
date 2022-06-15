using PRATS
using Test
import BenchmarkTools: @btime
include("testsystems/testsystems.jl")
include("testsystems/testsystems_pras.jl")
using PRATS.CompositeAdequacy



timestamps_a = TestSystems.singlenode_a.timestamps
timestamprow_a = permutedims(timestamps_a)
nstderr_tol = 3
simspec = PRATS.SequentialMonteCarlo(samples=10_000, seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())
shortfalls, flows = assess(TestSystems.singlenode_a, simspec, Shortfall(), GeneratorAvailability())
lole, eue = LOLE(shortfalls), EUE(shortfalls)
#PRATS: (LOLE = 0.243±0.005 event-h/4h, EUE = 0.83±0.02 MWh/4h)
#PRATS: (LOLE = 0.340±0.005 event-h/4h, EUE = 1.42±0.04 MWh/4h)




using PRAS
timestamps_a2 = TestSystems_pras.singlenode_a2.timestamps
timestamprow_a2 = permutedims(timestamps_a2)
nstderr_tol = 3
simspec = PRAS.SequentialMonteCarlo(samples=10_000, seed=1)
resultspecs = (PRAS.Shortfall(),PRAS.GeneratorAvailability())
shortfalls2, flows2 = PRAS.assess(TestSystems_pras.singlenode_a2, simspec, PRAS.Shortfall(), PRAS.GeneratorAvailability())
lole2, eue2 = PRAS.LOLE(shortfalls2), PRAS.EUE(shortfalls2)
#(LOLE = 0.343±0.005 event-h/4h, EUE = 1.50±0.03 MWh/4h)


# LOLE = 0.353±0.002 event-h/4h
# EUE = 1.57±0.01 MWh/4h

#@btime shortfalls, flows = assess(TestSystems.singlenode_a, simspec, Shortfall(), Flow())
# 175.905 ms (1500152 allocations: 424.21 MiB)
#1 THREAD, samples=100_000: 254.419 ms (1553663 allocations: 425.84 MiB)
#8 THREADS, samples=100_000: 827.547 ms (2383445 allocations: 451.19 MiB)

#-------------------------------------------------------------------------------------------


# using Plots,Random,Distributions,StatsBase
# using BenchmarkTools
# λ = Float64(1/2940);
# μ = Float64(1/60);
# N= Int32(8760);
# ndevices = length(devices)
# @inbounds availability = ones(Bool, ndevices, N)::Matrix{Bool}
# Random.seed!(1)
# for k in 1:ndevices
#     λ = Float64(1/2940);
#     μ = Float64(1/60);
#     if λ != 0.0
#         availability[k,:] = cycles!(λ, μ, availability[k,:])
#     end
# end

# plot(1:8760,availability[1,:])
# plot!(1:8760,availability[2,:])
# plot!(1:8760,availability[3,:])
# plot!(1:8760,availability[4,:])
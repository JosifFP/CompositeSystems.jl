using PRATS
using Test
import BenchmarkTools: @btime
include("testsystems/testsystems.jl")
using PRATS.CompositeAdequacy

simspec = PRATS.SequentialMonteCarlo(samples=100_000)#, seed=1)
resultspecs = (Shortfall(),GeneratorAvailability(), ShortfallSamples())
shortfalls, availability, shortfallsSamples =  PRATS.assess(TestSystems.singlenode_a, simspec, resultspecs...)
lole, eue =  PRATS.LOLE(shortfalls),  PRATS.EUE(shortfalls)
#(LOLE = 0.352±0.002 event-h/4h, EUE = 1.56±0.01 MWh/4h)  samples=100_000
lole2, eue2 = LOLE(shortfallsSamples), EUE(shortfallsSamples)
#(LOLE = 0.340±0.002 event-h/4h, EUE = 1.41±0.01 MWh/4h)   samples=100_000
lole2, eue2 = LOLE(shortfallsSamples), EUE(shortfallsSamples)
timestamps_a = TestSystems.singlenode_a.timestamps
EUE.(shortfalls, timestamps_a)

shortfalls, availability, shortfallsSamples =  PRATS.assess(TestSystems.singlenode_a_2, simspec, resultspecs...)
lole, eue =  PRATS.LOLE(shortfalls),  PRATS.EUE(shortfalls)


@testset "Shortfall Results" begin
    timestamps_a = TestSystems.singlenode_a.timestamps
    @test LOLE(shortfalls) ≈ LOLE(shortfallsSamples)
    @test EUE(shortfalls) ≈ EUE(shortfallsSamples)
    @test LOLE(shortfalls, "Region") ≈ LOLE(shortfallsSamples, "Region")
    @test all(LOLE.(shortfalls, timestamps_a) .≈LOLE.(shortfallsSamples, timestamps_a))
    @test all(EUE.(shortfalls, timestamps_a) .≈EUE.(shortfallsSamples, timestamps_a))
end


singlenode_a_lole = 0.355
singlenode_a_lolps = [0.028, 0.271, 0.028, 0.028]
singlenode_a_eues = [0.29, 0.832, 0.29, 0.178]

using PRAS
using Test
include("testsystems/testsystems_pras.jl")
simspec = PRAS.SequentialMonteCarlo(samples=100_000, seed=1)
resultspecs = (PRAS.Shortfall(), PRAS.GeneratorAvailability(), PRAS.ShortfallSamples())
shortfalls, availability, shortfallsSamples = PRAS.assess(TestSystems_pras.singlenode_a11, simspec, resultspecs...)
lole, eue = LOLE(shortfalls), EUE(shortfalls)
#(LOLE = 0.353±0.002 event-h/4h, EUE = 1.57±0.01 MWh/4h)   samples=100_000
lole2, eue2 = LOLE(shortfallsSamples), EUE(shortfallsSamples)
#(LOLE = 0.353±0.002 event-h/4h, EUE = 1.57±0.01 MWh/4h)   samples=100_000
timestamps_a = TestSystems_pras.singlenode_a11.timestamps
EUE.(shortfalls, timestamps_a)


@testset "Shortfall Results" begin
    @test LOLE(shortfalls) ≈ LOLE(shortfallsSamples)
    @test EUE(shortfalls) ≈ EUE(shortfallsSamples)
    @test LOLE(shortfalls, "Region") ≈ LOLE(shortfallsSamples, "Region")
    nstderr_tol = 3
    timestamps_a = TestSystems_pras.singlenode_a11.timestamps
    import PRAS.ResourceAdequacy: MeanEstimate
    withinrange(x::ReliabilityMetric, y::Real, n::Real) =isapprox(val(x), y, atol=n*stderror(x))
    withinrange(x::Tuple{<:Real, <:Real}, y::Real, nsamples::Int, n::Real) =isapprox(first(x), y, atol=n*last(x)/sqrt(nsamples))
    @test withinrange(LOLE(shortfalls),TestSystems_pras.singlenode_a11_lole, nstderr_tol)
    @test all(LOLE.(shortfalls, timestamps_a) .≈LOLE.(shortfallsSamples, timestamps_a))
    @test all(EUE.(shortfalls, timestamps_a) .≈EUE.(shortfallsSamples, timestamps_a))
end

#-------------------------------------------------------------------------------------------


using PRATS
using PRATS.CompositeAdequacy
include("testsystems/testsystems.jl")
simspec = PRATS.SequentialMonteCarlo(samples=100_000, seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())
shortfalls, availability = PRATS.assess(TestSystems.singlenode_stor, simspec, Shortfall(), GeneratorAvailability())
lole, eue = LOLE(shortfalls), EUE(shortfalls)
# (LOLE = 0.672±0.003 event-h/6h, EUE = 6.74±0.03 MWh/6h)

shortfalls, availability = PRATS.assess(TestSystems.singlenode_b, simspec, Shortfall(), GeneratorAvailability())
lole, eue = LOLE(shortfalls), EUE(shortfalls)
#(LOLE = 0.948±0.003 event-h/6h, EUE = 7.54±0.04 MWh/6h)

using PRAS
include("testsystems/testsystems_pras.jl")
simspec = PRAS.SequentialMonteCarlo(samples=100_000, seed=1)
resultspecs = (PRAS.Shortfall(),PRAS.GeneratorAvailability())
shortfalls2, availability2 = PRAS.assess(TestSystems_pras.singlenode_stor, simspec, PRAS.Shortfall(), PRAS.GeneratorAvailability())
lole2, eue2 = PRAS.LOLE(shortfalls2), PRAS.EUE(shortfalls2)
# (LOLE = 0.725±0.003 event-h/6h, EUE = 6.42±0.03 MWh/6h) samples=100_000

shortfalls, availability = PRAS.assess(TestSystems_pras.singlenode_bb, simspec, Shortfall(), GeneratorAvailability())
lole, eue = LOLE(shortfalls), EUE(shortfalls)
# (LOLE = 0.955±0.003 event-h/6h, EUE = 7.09±0.03 MWh/6h) samples=100_000
#-------------------------------------------------------------------------------------------

using PRAS
import BenchmarkTools: @btime
sys = PRAS.SystemModel("test/temporal/testsystems/toymodel.hdf5")
simspec = SequentialMonteCarlo(samples=1_000,seed=1, threaded=false)
resultspecs = (Shortfall(), GeneratorAvailability())
@btime shortfalls, availability = PRAS.assess(sys, simspec, resultspecs...)
#59.283 ms (869416 allocations: 291.05 MiB)
lole2, eue2 = PRAS.LOLE(shortfalls), PRAS.EUE(shortfalls)
#(LOLE = 0.00000 event-(5min)/1440min, EUE = 0.00000 MWh/1440min)


using PRATS
import BenchmarkTools: @btime
file = "test/temporal/testsystems/toymodel.hdf5"
sys = PRATS.SystemModel(file)
simspec = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
resultspecs = (PRATS.Shortfall(), PRATS.GeneratorAvailability())
shortfalls, availability = PRATS.assess(sys, simspec, resultspecs...)
#201.537 ms (4116411 allocations: 429.08 MiB)
lole, eue = PRATS.LOLE(shortfalls), PRATS.EUE(shortfalls)
#(LOLE = 0.00000 event-(5min)/1440min, EUE = 0.00000 MWh/1440min)
#-------------------------------------------------------------------------------------------

using PRATS
import BenchmarkTools: @btime
file = "test/temporal/testsystems/rts.hdf5"
sys = PRATS.SystemModel(file)
simspec = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
resultspecs = (PRATS.Shortfall(), PRATS.GeneratorAvailability())
shortfalls, availability = PRATS.assess(sys, simspec, resultspecs...)
lole, eue = PRATS.LOLE(shortfalls), PRATS.EUE(shortfalls)
#(LOLE = 0.00000 event-h/8784h, EUE = 0.00000 MWh/8784h)

using PRAS
import BenchmarkTools: @btime
file = "test/temporal/testsystems/rts.hdf5"
sys = PRAS.SystemModel(file)
simspec = PRAS.SequentialMonteCarlo(samples=1_000,seed=1)
resultspecs = (PRAS.Shortfall(), PRAS.GeneratorAvailability())
shortfalls, availability = PRAS.assess(sys, simspec, resultspecs...)
lole, eue = PRAS.LOLE(shortfalls), PRAS.EUE(shortfalls)
#(LOLE = 0.00000 event-h/8784h, EUE = 0.00000 MWh

#-------------------------------------------------------------------------------------------
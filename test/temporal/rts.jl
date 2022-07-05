using PRATS
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime

loadfile = "test/data/rts_Load.xlsx"

sys = PRATS.SystemModel(loadfile)
simspec = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
#resultspecs = (PRATS.Shortfall(), PRATS.GeneratorAvailability())
#resultspecs = (PRATS.Shortfall(), PRATS.ShortfallSamples())
resultspecs = (Shortfall(),GeneratorAvailability())

shortfalls, availability = PRATS.assess(sys, simspec, resultspecs...)
lole, eue = PRATS.LOLE(shortfalls), PRATS.EUE(shortfalls)
#lole2, eue2 = LOLE(shortfallsSamples), EUE(shortfallsSamples)
timestamps = sys.timestamps
LOLPS = LOLE.(shortfalls, timestamps_a)
println(LOLPS)




#-------------------------------------------------------------------------------------------
using PRATS
using Test
import BenchmarkTools: @btime
include("testsystems/testsystems.jl")
using PRATS.CompositeAdequacy

simspec = PRATS.SequentialMonteCarlo(samples=100_000)#, seed=1)
resultspecs = (Shortfall(),GeneratorAvailability(), ShortfallSamples())
shortfalls, availability, shortfallsSamples =  PRATS.assess(TestSystems.singlenode_a, simspec, resultspecs...)
lole, eue =  PRATS.LOLE(shortfalls),  PRATS.EUE(shortfalls)
lole2, eue2 = LOLE(shortfallsSamples), EUE(shortfallsSamples)


#-------------------------------------------------------------------------------------------
using PRATS
using PRATS.CompositeAdequacy
include("testsystems/testsystems.jl")
simspec = PRATS.SequentialMonteCarlo(samples=100_000, seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())
shortfalls, availability = PRATS.assess(TestSystems.singlenode_stor, simspec, Shortfall(), GeneratorAvailability())
lole, eue = LOLE(shortfalls), EUE(shortfalls)

shortfalls, availability = PRATS.assess(TestSystems.singlenode_b, simspec, Shortfall(), GeneratorAvailability())
lole, eue = LOLE(shortfalls), EUE(shortfalls)
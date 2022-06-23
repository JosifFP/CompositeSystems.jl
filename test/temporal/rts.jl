using PRATS
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime

loadfile = "test/data/rts_Load.xlsx"

sys = PRATS.SystemModel(loadfile)
simspec = PRATS.SequentialMonteCarlo(samples=20_500,seed=1)
#resultspecs = (PRATS.Shortfall(), PRATS.GeneratorAvailability())
resultspecs = (PRATS.Shortfall(), PRATS.ShortfallSamples())
shortfalls, availability = PRATS.assess(sys, simspec, resultspecs...)
lole, eue = PRATS.LOLE(shortfalls), PRATS.EUE(shortfalls)
#lole2, eue2 = LOLE(shortfallsSamples), EUE(shortfallsSamples)
timestamps = sys.timestamps
LOLPS = LOLE.(shortfalls, timestamps_a)
println(LOLPS)
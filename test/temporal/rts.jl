using PRATS
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime

loadfile = "test/data/rts_Load.xlsx"

sys = PRATS.SystemModel(loadfile)
sys.Regions


simspec = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
#resultspecs = (PRATS.Shortfall(), PRATS.GeneratorAvailability())
#resultspecs = (PRATS.Shortfall(), PRATS.ShortfallSamples())
resultspecs = (PRATS.Shortfall())

shortfalls, availability = PRATS.assess(sys, simspec, resultspecs...)
lole, eue = PRATS.LOLE(shortfalls), PRATS.EUE(shortfalls)
#lole2, eue2 = LOLE(shortfallsSamples), EUE(shortfallsSamples)
timestamps = sys.timestamps
LOLPS = LOLE.(shortfalls, timestamps_a)
println(LOLPS)


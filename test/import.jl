
using PRATS, Reexport, XLSX
#using PRAS
#using ContingencySolver

networkfile = "test/data/RTS.raw"
loadfile = "test/data/rts_Load.xlsx"
studycase = [networkfile, loadfile]
#data = ContingencySolver.build_data(studycase[1])

@time sys = PRATS.SystemModel(loadfile)
#@time shortfalls = PRATS.assess(sys, SequentialMonteCarlo(samples=2_500), Shortfall())

simspec = SequentialMonteCarlo(samples=500,seed=1, threaded=false)

resultspecs = (Shortfall(), Surplus(), Flow(), Utilization(),
               ShortfallSamples(), SurplusSamples(),
               FlowSamples(), UtilizationSamples(),
               GeneratorAvailability())

               @time shortfall, surplus, flow, utilization, shortfallsamples, surplussamples, flowsamples,
               utilizationsamples, generatoravailability = assess(sys, simspec, resultspecs...)





LOLE(shortfall)
EUE(shortfall)


Threads.nthreads()
Threads.threadid()
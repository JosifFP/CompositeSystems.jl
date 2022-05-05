using Profile
using BenchmarkTools
using ProfileView
using PRATS

Profile.init(delay=0.01)
loadfile = "test/data/rts_Load.xlsx"
sys = PRATS.SystemModel(loadfile)
simspec = SequentialMonteCarlo(samples=100,seed=1, threaded=false)

resultspecs = (Shortfall(), Surplus(), Flow(), Utilization(),
               ShortfallSamples(), SurplusSamples(),
               FlowSamples(), UtilizationSamples(),
               GeneratorAvailability())

               shortfall, surplus, flow, utilization, shortfallsamples, surplussamples, flowsamples,
               utilizationsamples, generatoravailability = assess(sys, simspec, resultspecs...)


Profile.clear()
@profile (for i=1:10;
shortfall, surplus, flow, utilization, shortfallsamples, surplussamples, flowsamples,
               utilizationsamples, generatoravailability = assess(sys, simspec, resultspecs...); end)
Profile.print()
ProfileView.view()


#@time @allocated result = ContingencySolver.min_load(file, optimizer, load_curt_info, t_contingency_info, ContingencySolver.dc_opf_lc)
#cd C:\Users\jfiguero\AppData\Local\Programs\Julia-1.7.2\bin
#julia --track-allocation=user

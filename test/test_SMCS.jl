include("solvers.jl")

using PRATS
import PRATS.PRATSBase
import PRATS.CompositeAdequacy: CompositeAdequacy, field, var,
assetgrouplist, update_asset_idxs!, S, Status, findfirstunique, SUCCESSFUL, FAILED, build_sol_values
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
using Test
using ProfileView, Profile
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
PRATSBase.silence()

system = PRATSBase.SystemModel(RawFile; ReliabilityDataDir=ReliabilityDataDir, N=8736)
resultspecs = (Shortfall(), Shortfall())

settings = PRATS.Settings(
    ipopt_optimizer_3, 
    modelmode = JuMP.AUTOMATIC,
    powermodel = AbstractDCMPPModel
)

method = PRATS.SequentialMCS(samples=1, seed=1, threaded=true)
pm = CompositeAdequacy.PowerFlowProblem(system, method, settings)

@time shortfall,report = PRATS.assess(system, pm, method, resultspecs...)

PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)






Profile.clear()
@profile shortfall,report = PRATS.assess(system, method, resultspecs...)
@pprof shortfall,report = PRATS.assess(system, method, resultspecs...)
Profile.print()
ProfileView.view()



PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)
shortfall.shortfall_bus_std

shortfall.nsamples
shortfall.loads
shortfall.timestamps
shortfall.eventperiod_mean
shortfall.eventperiod_std
shortfall.eventperiod_bus_mean
shortfall.eventperiod_bus_std
shortfall.eventperiod_period_mean
shortfall.eventperiod_period_std
shortfall.eventperiod_busperiod_mean
shortfall.eventperiod_busperiod_std
@show shortfall.shortfall_mean
shortfall.shortfall_std
shortfall.shortfall_bus_std
@show shortfall.shortfall_period_std
@show shortfall.shortfall_busperiod_std
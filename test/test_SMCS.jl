include("solvers.jl")
using PRATS
import PRATS.PRATSBase
import PRATS.CompositeAdequacy: CompositeAdequacy, field, var, topology, makeidxlist, sol,
    assetgrouplist, Status, findfirstunique, SUCCESSFUL, FAILED, build_sol_values
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
using Test
using ProfileView, Profile
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RBTS.m"
PRATSBase.silence()

system = PRATSBase.SystemModel(RawFile; ReliabilityDataDir=ReliabilityDataDir, N=8736)
resultspecs = (Shortfall(), Shortfall())

ipopt_optimizer_3 = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer, 
    "tol"=>1e-3, 
    #"acceptable_tol"=>1e-2, 
    "max_cpu_time"=>5.0,
    "print_level"=>0
)

settings = PRATS.Settings(

    juniper_optimizer_2, 
    modelmode = JuMP.AUTOMATIC,
    powermodel = AbstractDCMPPModel
)

method = PRATS.SequentialMCS(samples=4, seed=99, threaded=true)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)


PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)



filter(i->asset_states[i,t]==1, field(branches, :pmax)













Profile.clear()
@profile shortfall,report = PRATS.assess(system, method, resultspecs...)
@pprof shortfall,report = PRATS.assess(system, method, resultspecs...)
Profile.print()
ProfileView.view()



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
using PRATS, PRATS.OPF, PRATS.BaseModule
using PRATS.OPF
using PRATS.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile


include("solvers.jl")
TimeSeriesFile = "test/data/RBTS/Loads.xlsx"

Base_RawFile = "test/data/RBTS/Base/RBTS.m"
Base_ReliabilityFile = "test/data/RBTS/Base/R_RBTS.m"

Storage_RawFile = "test/data/RBTS/Storage/RBTS.m"
Storage_ReliabilityFile = "test/data/RBTS/Storage/R_RBTS.m"

Case1_RawFile = "test/data/RBTS/Case1/RBTS.m"
Case1_ReliabilityFile = "test/data/RBTS/Case1/R_RBTS.m"


resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    gurobi_optimizer_1,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC
)

timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)
system = BaseModule.SystemModel(Case1_RawFile, Case1_ReliabilityFile, timeseries_load, SParametrics)
#system = BaseModule.SystemModel(Storage_RawFile, Storage_ReliabilityFile, timeseries_load, SParametrics)
#system = BaseModule.SystemModel(Base_RawFile, Base_ReliabilityFile, timeseries_load, SParametrics)

method = SequentialMCS(samples=200, seed=100, threaded=true)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)

PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)




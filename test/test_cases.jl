using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile


include("solvers.jl")
TimeSeriesFile = "test/data/RBTS/Loads.xlsx"
TimeSeriesFile2 = "test/data/RTS/Loads.xlsx"

Base_RawFile = "test/data/RBTS/Base/RBTS2.m"
Base_ReliabilityFile = "test/data/RBTS/Base/R_RBTS.m"

Base_RawFile2 = "test/data/RTS/Base/RTS.m"
Base_ReliabilityFile2 = "test/data/RTS/Base/R_RTS.m"
Base_ReliabilityFile3 = "test/data/RTS/Base/R_RTS2.m"

Storage_RawFile = "test/data/RBTS/Storage/RBTS.m"
Storage_ReliabilityFile = "test/data/RBTS/Storage/R_RBTS.m"

Case1_RawFile = "test/data/RBTS/Case1/RBTS.m"
Case1_ReliabilityFile = "test/data/RBTS/Case1/R_RBTS.m"


resultspecs = (Shortfall(), Shortfall())
settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC,
    powermodel = OPF.DCMPPowerModel
    #powermodel = OPF.DCPLLPowerModel
)

timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile2)
#system = BaseModule.SystemModel(Case1_RawFile, Case1_ReliabilityFile, timeseries_load, SParametrics)
system = BaseModule.SystemModel(Base_RawFile2, Base_ReliabilityFile3, timeseries_load, SParametrics)
#system = BaseModule.SystemModel(Base_RawFile, Base_ReliabilityFile, timeseries_load, SParametrics)

method = SequentialMCS(samples=20, seed=100, threaded=true)
@time shortfall,report = CompositeSystems.assess(system, method, settings, resultspecs...)


CompositeSystems.LOLE.(shortfall, system.loads.keys)
CompositeSystems.EUE.(shortfall, system.loads.keys)
CompositeSystems.LOLE.(shortfall)
CompositeSystems.EUE.(shortfall)
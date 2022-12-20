using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")
TimeSeriesFile = "test/data/RBTS/Loads_buses.xlsx"

Base_RawFile = "test/data/RBTS/Base/RBTS.m"
Base_ReliabilityFile = "test/data/RBTS/Base/R_RBTS.m"
#Base_RawFile = "test/data/RTS/Base/RTS.m"
#Base_ReliabilityFile = "test/data/RTS/Base/R_RTS.m"
#Storage_RawFile = "test/data/RBTS/Storage/RBTS.m"
#Storage_ReliabilityFile = "test/data/RBTS/Storage/R_RBTS.m"
#Case1_RawFile = "test/data/RBTS/Case1/RBTS.m"
#Case1_ReliabilityFile = "test/data/RBTS/Case1/R_RBTS.m"

resultspecs = (Shortfall(), Shortfall())
settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC,
    #powermodel = OPF.NFAPowerModel
    #powermodel = OPF.DCPPowerModel
    #powermodel = OPF.DCMPPowerModel
    #powermodel = OPF.DCPLLPowerModel
    powermodel = OPF.LPACCPowerModel
)

timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)
#system = BaseModule.SystemModel(Case1_RawFile, Case1_ReliabilityFile, timeseries_load, SParametrics)
system = BaseModule.SystemModel(Base_RawFile, Base_ReliabilityFile, timeseries_load, SParametrics)

method = SequentialMCS(samples=250, seed=100, threaded=true)
#method = SequentialMCS(samples=1, seed=100, threaded=false)
@time shortfall,report = CompositeSystems.assess(system, method, settings, resultspecs...)

CompositeSystems.LOLE.(shortfall, system.loads.keys)
CompositeSystems.EENS.(shortfall, system.loads.keys)
CompositeSystems.LOLE.(shortfall)
CompositeSystems.EENS.(shortfall)


(system.branches.keys[]...)

model = jump_model(settings.modelmode, deepcopy(settings.optimizer))
pm = abstract_model(settings.powermodel, Topology(system), model)
systemstates = SystemStates(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.seed!(rng, (method.seed, 1))
CompositeAdequacy.initialize_states!(rng, systemstates, system)

y = systemstates.branches[10,:]
using Plots
plot(1:8736, y)
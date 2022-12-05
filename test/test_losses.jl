using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime

include("solvers.jl")
TimeSeriesFile = "test/data/RBTS/Loads.xlsx"

resultspecs = (Shortfall(), Shortfall())
settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC,
    powermodel = OPF.DCPLLPowerModel
)

RawFile = "test/data/RBTS/Base/RBTS.m"
ReliabilityFile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(RawFile, ReliabilityFile)

CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
model = OPF.JumpModel(settings.modelmode, deepcopy(settings.optimizer))
pm = OPF.PowerModel(settings.powermodel, OPF.Topology(system), model)
OPF.initialize_pm_containers!(pm, system; timeseries=false)
t=1

systemstates = OPF.SystemStates(system, available=true)
CompositeAdequacy.solve!(pm, system, systemstates, t)

sum(systemstates.plc)
pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))












CompositeSystems.field(systemstates, :generators)[3,t] = 0
CompositeSystems.field(systemstates, :generators)[7,t] = 0
CompositeSystems.field(systemstates, :generators)[8,t] = 0
CompositeSystems.field(systemstates, :generators)[9,t] = 0
systemstates.system[t] = 0
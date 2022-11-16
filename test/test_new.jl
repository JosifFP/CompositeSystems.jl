using PRATS, PRATS.OPF, PRATS.BaseModule
using PRATS.OPF
using PRATS.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS, SCS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")
TimeSeriesFile = "test/data/RTS/Loads.xlsx"
RawFile = "test/data/RTS/RTS.m"
ReliabilityFile = "test/data/RTS/R_RTS.m"
#TimeSeriesFile = "test/data/RBTS/Loads.xlsx"
#RawFile = "test/data/RBTS/RBTS.m"
#ReliabilityFile = "test/data/RBTS/R_RBTS.m"

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    #ipopt_optimizer_3,
    gurobi_optimizer_1,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC
)

timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)
system = BaseModule.SystemModel(RawFile, ReliabilityFile, timeseries_load, SParametrics)
method = SequentialMCS(samples=1, seed=100, threaded=false)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)


#Profile.clear()
#@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)
#ProfileView.view()

PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)

#using TimerOutputs
#const to = TimerOutput()
#@timeit to "" foo()
#show(to)









@code_warntype CompositeAdequacy.initialize_powermodel!(pm, system)
@code_warntype PowerModel(system, topology, settings)
@code_warntype pm.model

t=2
system.loads.pd[:,t] =  [0.2; 0.85; 0.4; 0.2; 0.2]
PRATS.field(systemstates, :generators)[3,t] = 0
PRATS.field(systemstates, :generators)[7,t] = 0
PRATS.field(systemstates, :generators)[8,t] = 0
PRATS.field(systemstates, :generators)[9,t] = 0
systemstates.system[t] = 0
states = systemstates
CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)
@code_warntype CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)

@code_warntype update_method!(pm, system, states, t)

OPF.con(pm, :power_balance, 1).data

@code_warntype PRATS.Settings(
    ipopt_optimizer_3,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)

@code_warntype settings.powermodel
settings.powermodel
t=3
system.loads.pd[:,t] =  [0.2; 0.85; 0.4; 0.2; 0.2]
PRATS.field(systemstates, :branches)[3,t] = 0
PRATS.field(systemstates, :branches)[4,t] = 0
PRATS.field(systemstates, :branches)[8,t] = 0
systemstates.system[t] = 0
states = systemstates
CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)

@show JuMP.solution_summary(pm.model, verbose=true)
OPF.sol(pm, :plc)

OPF.con(pm, :ohms_yt_from)
OPF.con(pm, :voltage_angle_diff_upper)
OPF.con(pm, :voltage_angle_diff_lower)


t=4
system.loads.pd[:,t] =  [0.2; 0.85; 0.4; 0.2; 0.2]
states = systemstates
CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)

t=5
system.loads.pd[:,t] =  [0.2; 0.85; 0.4; 0.2; 0.2]
PRATS.field(systemstates, :branches)[3,t] = 0
PRATS.field(systemstates, :branches)[4,t] = 0
PRATS.field(systemstates, :branches)[8,t] = 0
systemstates.system[t] = 0
states = systemstates
CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)

@show JuMP.solution_summary(pm.model, verbose=true)
OPF.sol(pm, :plc)[:,5]

t=6
system.loads.pd[:,t] =  [0.2; 0.85; 0.4; 0.2; 0.2]
PRATS.field(systemstates, :generators)[3,t] = 0
PRATS.field(systemstates, :generators)[7,t] = 0
PRATS.field(systemstates, :generators)[8,t] = 0
PRATS.field(systemstates, :generators)[9,t] = 0
systemstates.system[t] = 0
states = systemstates
CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)
OPF.sol(pm, :plc)[:,t]

t=7
system.loads.pd[:,t] =  [0.2; 0.85; 0.4; 0.2; 0.2]
PRATS.field(systemstates, :branches)[3,t] = 0
PRATS.field(systemstates, :branches)[4,t] = 0
systemstates.system[t] = 0
states = systemstates
CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)



states.branches[:,6]

all(view(states.branches,:,t))

JuMP.all_constraints(pm.model; include_variable_in_set_constraints = true)




CompositeAdequacy.build_method!(pm, system, systemstates, t)
CompositeAdequacy.optimize_method!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
@show JuMP.solution_summary(pm.model, verbose=true)

JuMP.all_variables(pm.model)

pg1 = var(pm, :pg,1)[1]

JuMP.has_upper_bound(pg1)
cstr = JuMP.LowerBoundRef(pg1)
JuMP.set_lower_bound(pg1, 1.0)
JuMP.LowerBoundRef(pg1)



JuMP.fix(var(pm, :va), 135.0; force=true);

t=2





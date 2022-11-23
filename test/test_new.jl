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
RawFile = "test/data/RBTS/RBTS.m"
ReliabilityFile = "test/data/RBTS/R_RBTS.m"
#TimeSeriesFile = "test/data/RTS/Loads.xlsx"
#RawFile = "test/data/RTS/RTS.m"
#ReliabilityFile = "test/data/RTS/R_RTS.m"

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
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


recorders = accumulator.(system, method, resultspecs)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
topology = Topology(system)
model = OPF.JumpModel(settings.modelmode, deepcopy(settings.optimizer))
pm = PowerModel(settings.powermodel, topology, model)
systemstates = SystemStates(system)
CompositeAdequacy.initialize_powermodel!(pm, system)
CompositeAdequacy.initialize_states!(rng, systemstates, system)


#@code_warntype

@code_warntype CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)
@code_warntype update_method!(pm, system, states, t)
OPF.con(pm, :power_balance, 1).data

@code_warntype PRATS.Settings(
    ipopt_optimizer_3,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)


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


include("solvers.jl")
import PowerModels
PowerModels.silence()
data = PowerModels.parse_file("test/data/RTS/RTS.m")
@time for i in 1:10
    result = PowerModels.solve_dc_opf(data, gurobi_optimizer_1)
end

result = PowerModels.solve_dc_opf(data, gurobi_optimizer_1)
result = PowerModels.solve_dc_opf(data, ipopt_optimizer_3)


JuMP.optimize!(pm.model) 
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)




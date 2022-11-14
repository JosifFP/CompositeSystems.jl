using PRATS, PRATS.OPF, PRATS.BaseModule
using PRATS.OPF
using PRATS.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
include("solvers.jl")
TimeSeriesFile = "test/data/RBTS/Loads.xlsx"
RawFile = "test/data/RBTS/RBTS.m"
ReliabilityFile = "test/data/RBTS/R_RBTS.m"

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    ipopt_optimizer_3,
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)

method = SequentialMCS(samples=1, seed=1, threaded=false)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)






timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)
system = BaseModule.SystemModel(RawFile, ReliabilityFile, timeseries_load, SParametrics)
topology = OPF.Topology(system)
systemstates = BaseModule.SystemStates(system)
pm = OPF.PowerModel(system, topology, settings)
rng = CompositeAdequacy.Philox4x((0, 0), 10) 
s=1
CompositeAdequacy.seed!(rng, (method.seed, s))  #using the same seed for entire period.
CompositeAdequacy.initialize_states!(rng, systemstates, system) #creates the up/down sequence for each device.
CompositeAdequacy.initialize_powermodel!(pm, system)
t=2
CompositeAdequacy.update_powermodel!(pm, system, systemstates, t)
sol(pm, :plc)


JuMP.all_constraints(pm.model; include_variable_in_set_constraints = true)

states = systemstates
t=1
OPF.var_gen_power(pm, system, states, nw=t)
OPF.var_branch_power(pm, system, states, nw=t)
OPF.var_load_curtailment(pm, system, states, nw=t)

for i in field(system, :buses, :keys)
    OPF.constraint_power_balance(pm, system, i, states, nw=t)
end











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

sol(pm,:plc)

var(pm, :va)


JuMP.fix(var(pm, :va), 135.0; force=true);

t=2





using PRATS
import PRATS.BaseModule: BaseModule, BuildNetwork, SystemModel, extract_timeseriesload
import PRATS.CompositeAdequacy: CompositeAdequacy, field, var, topology, makeidxlist, sol,
    assetgrouplist, findfirstunique, build_sol_values, SolContainer, initialize!, Initialize_model, Topology,
    initialize!, seed!, update!
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
include("solvers.jl")
TimeSeriesFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/Loads.xlsx"
RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/RBTS.m"
ReliabilityFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/R_RBTS.m"

timeseries_load, SParametrics = extract_timeseriesload(TimeSeriesFile)
system = SystemModel(RawFile, ReliabilityFile, timeseries_load, SParametrics)

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    ipopt_optimizer_3,
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)
method = PRATS.SequentialMCS(samples=100, seed=654, threaded=false)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)





topo = Topology(system)
@time pm = CompositeAdequacy.Initialize_model(system, topo, settings)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
seed!(rng, (666, 1))
systemstates = SystemStates(system, method)
initialize!(rng, systemstates, system)


pm.var.object[:p][1]
pm.var.object[:plc]
pm.sol.object[:plc]

t=1
field(systemstates, :generators)[3,t] = 0
field(systemstates, :generators)[7,t] = 0
field(systemstates, :generators)[8,t] = 0
field(systemstates, :generators)[9,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm.topology, systemstates, system, t)
CompositeAdequacy.build_method!(pm, system, t)
CompositeAdequacy.optimize!(pm.model; ignore_optimize_hook = true)

build_sol_values(var(pm, :plc, 1))
sol(pm, :plc, t)

pm.var.object
a = pm.var.object[:va]
values(a)

fill!(pm.sol.object[:plc], 0.0)

var(pm, :p)[1]
typeof(var(pm, :p))

CompositeAdequacy.reset_object_container!(var(pm, :p), field(system, :arcs, :arcs), timesteps=1:8736)
add_object_container!(var, :p, field(system, :arcs, :arcs), timesteps = 1:N)

JuMP.optimize!(pm.model)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)


pm.sol.object[:plc]

empty!(pm.model)

CompositeAdequacy.solve!(pm, system, t)

pm.var.object[:plc]
a = CompositeAdequacy.var(pm,:plc)
a[1]
typeof(a)

@code_warntype CompositeAdequacy.solve!(pm, system, t)

@code_warntype CompositeAdequacy.build_method!(pm, system, t)
@code_warntype CompositeAdequacy.optimize!(pm.model; ignore_optimize_hook = true)
@code_warntype CompositeAdequacy.build_result!(pm, system, t)

nw=0
@code_warntype CompositeAdequacy.var_bus_voltage(pm, system, t)
@code_warntype CompositeAdequacy.var_gen_power(pm, system, t)
@code_warntype CompositeAdequacy.var_branch_power(pm, system, t)
@code_warntype CompositeAdequacy.var_load_curtailment(pm, system, t)

sol(pm, :plc)

for i in field(system, :ref_buses)
    @code_warntype CompositeAdequacy.constraint_theta_ref(pm, i, t)
end

@code_warntype for i in assetgrouplist(topology(pm, :buses_idxs))
    constraint_power_balance(pm, system, i, t)
end

@code_warntype for i in assetgrouplist(topology(pm, :branches_idxs))
    constraint_ohms_yt(pm, system, i, t)
    constraint_voltage_angle_diff(pm, system, i, t)
    #constraint_thermal_limits(pm, system, i, t)
end

vm = CompositeAdequacy.var(pm, :vm)[0]
values(vm)

empty!(values(vm))

fieldnames( CompositeAdequacy.var(pm))


import PowerModels

PowerModels.silence()
data = PowerModels.parse_file(RawFile)
@time for i in 1:8736
    result = PowerModels.solve_dc_opf(data, ipopt_optimizer_3)
end



assetgrouplist(pm.topology.buses_idxs)
assetgrouplist(pm.topology.loads_idxs)
assetgrouplist(pm.topology.branches_idxs)
assetgrouplist(pm.topology.shunts_idxs)
assetgrouplist(pm.topology.generators_idxs)
assetgrouplist(pm.topology.storages_idxs)
assetgrouplist(pm.topology.generatorstorages_idxs)
pm.topology.loads_nodes
pm.topology.shunts_nodes
pm.topology.generators_nodes
pm.topology.storages_nodes
pm.topology.generatorstorages_nodes
@show pm.topology.arcs.buspairs
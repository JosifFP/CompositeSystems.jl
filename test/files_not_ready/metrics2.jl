using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using XLSX, Dates
include("solvers.jl")

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = false,
    count_samples = true
)

timeseriesfile_before = "test/data/RBTS/Loads_system.xlsx"
rawfile_before = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile_before = "test/data/RBTS/Base/R_RBTS.m"

timeseriesfile_after = "test/data/RBTS/Loads_system.xlsx"
rawfile_after = "test/data/others/Storage/RBTS_strg.m"
Base_reliabilityfile_after = "test/data/others/Storage/R_RBTS_strg.m"

sys_before = BaseModule.SystemModel(rawfile_before, Base_reliabilityfile_before, timeseriesfile_before)
sys_after = BaseModule.SystemModel(rawfile_after, Base_reliabilityfile_after, timeseriesfile_after)
sys_after.storages.buses[1] = 6
sys_after.storages.charge_rating[1] = 0.50
sys_after.storages.discharge_rating[1] = 0.50
sys_after.storages.thermal_rating[1] = 0.50
sys_after.storages.energy_rating[1] = 2.00

loads = [
    1 => 0.1081,
    2 => 0.4595,
    3 => 0.2162,
    4 => 0.1081,
    5 => 0.1081,
]

smc = SequentialMCS(samples=300, seed=100, threaded=true)
#simulationspec = SequentialMCS(samples=500, seed=100, threaded=true)
cc = assess(sys_before, sys_after, ELCC{EENS}(50.0, loads; capacity_gap=10.0), settings, smc)

minimum(cc)
maximum(cc)
extrema(cc)

sys_after.baseMVA
params.capacity_gap

cc.target_metric
cc.lowerbound
cc.upperbound
(cc.lowerbound, cc.upperbound)

cc.bound_capacities
cc.bound_metrics










params = ELCC{EENS}(50.0, loads)
sys_baseline = sys_before
sys_augmented = sys_after
P = BaseModule.powerunits["MW"]

loadskeys = sys_baseline.loads.keys
loadskeys != sys_augmented.loads.keys && error("Systems provided do not have matching loads")

target_metric = EENS(first(assess(sys_baseline, simulationspec, settings, Shortfall())))

capacities = Int[]
metrics = typeof(target_metric)[]

elcc_loads, base_load, sys_variable = CompositeSystems.copy_load(sys_augmented, params.loads)

elcc_loads
base_load
sys_variable.loads.pd[:,100] == base_load[:,100]


lower_bound = 0
lower_bound_metric = EENS(first(assess(sys_variable, simulationspec, settings, Shortfall())))
push!(capacities, lower_bound)
push!(metrics, lower_bound_metric)

upper_bound = params.capacity_max
CompositeSystems.update_load!(sys_variable, elcc_loads, base_load, upper_bound, sys_baseline.baseMVA)



sys_variable.loads.pd[:,100] == base_load[:,100]
upper_bound_metric = EENS(first(assess(sys_variable, simulationspec, settings, Shortfall())))
push!(capacities, upper_bound)
push!(metrics, upper_bound_metric)






cc = assess(sys_before, sys_after, ELCC{EENS}(50.0, loads), settings, smc)

#params = ELCC{EENS}(500.0, loads)
#load_shares = params.loads
#load_allocations = CompositeSystems.allocate_loads(sys_before.loads.keys, load_shares)


minimum(cc)
maximum(cc)
extrema(cc)

sys_after.baseMVA
params.capacity_gap

cc.target_metric
cc.lowerbound
cc.upperbound
(cc.lowerbound, cc.upperbound)

cc.bound_capacities
cc.bound_metrics


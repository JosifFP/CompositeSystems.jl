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
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = false,
    count_samples = true
)

timeseriesfile_before = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile_before = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
Base_reliabilityfile_before = "test/data/SMCS/RTS_79_A/R_RTS.m"

timeseriesfile_after = "test/data/RTS/Loads_system.xlsx"
rawfile_after = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile_after = "test/data/others/Storage/R_RTS_strg.m"


sys_before = BaseModule.SystemModel(rawfile_before, Base_reliabilityfile_before, timeseriesfile_before)
sys_after = BaseModule.SystemModel(rawfile_after, Base_reliabilityfile_after, timeseriesfile_after)
sys_after.storages.buses[1] = 8
sys_after.storages.charge_rating[1] = 1.00
sys_after.storages.discharge_rating[1] = 1.00
sys_after.storages.thermal_rating[1] = 1.00
sys_after.storages.energy_rating[1] = 2.00

loads = [
    1 => 0.038,
    2 => 0.034,
    3 => 0.063,
    4 => 0.026,
    5 => 0.025,
    6 => 0.048,
    7 => 0.044,
    8 => 0.06,
    9 => 0.061,
    10 => 0.068,
    11 => 0.093,
    12 => 0.068,
    13 => 0.111,
    14 => 0.035,
    15 => 0.117,
    16 => 0.064,
    17 => 0.045
]

smc = SequentialMCS(samples=2000, seed=100, threaded=true)
#simulationspec = SequentialMCS(samples=500, seed=100, threaded=true)
@time cc = assess(sys_before, sys_after, ELCC{EENS}(100.0, loads; capacity_gap=10.0), settings, smc)

minimum(cc)
maximum(cc)
extrema(cc)

cc.target_metric
cc.lowerbound
cc.upperbound
(cc.lowerbound, cc.upperbound)

cc.bound_capacities
cc.bound_metrics

sys_after.baseMVA
params = ELCC{EENS}(500.0, loads)
params.capacity_gap
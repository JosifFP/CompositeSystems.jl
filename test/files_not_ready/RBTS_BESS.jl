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
    count_samples = false
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

smc = SequentialMCS(samples=10, seed=100, threaded=true)
cc = assess(sys_before, sys_after, ELCC{SI}(50.0, loads; capacity_gap=5.0, p_value=0.5), settings, smc)
CompositeAdequacy.print_results(sys_after, cc)

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
shortfall, _ = CompositeSystems.assess(sys_before, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_before, shortfall)
using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, Gurobi, MathOptInterface
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using XLSX, Dates

# Set up the Gurobi environment
#const GRB_ENV = Gurobi.Env()

gurobi_optimizer = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer,
    #"gurobi_env" => GRB_ENV, 
    "Presolve"=>1, 
    "PreCrush"=>1, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "NumericFocus"=>3, 
    "Threads"=>5
)

settings = CompositeSystems.Settings(
    gurobi_optimizer,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = false,
    count_samples = true
)

timeseriesfile_before = "test/data/RBTS/SYSTEM_LOADS.xlsx"
rawfile_before = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile_before = "test/data/RBTS/Base/R_RBTS.m"

timeseriesfile_after = "test/data/RBTS/SYSTEM_LOADS.xlsx"
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

smc = SequentialMCS(samples=200, seed=100, threaded=true)
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
shortfall, _ = CompositeSystems.assess(sys_after, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_after, shortfall)











@time cc = assess(sys_before, sys_after, ELCC{SI}(50.0, loads; capacity_gap=5.0, p_value=0.5), settings, smc)
CompositeAdequacy.print_results(sys_after, cc)

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
shortfall, _ = CompositeSystems.assess(sys_before, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_before, shortfall)
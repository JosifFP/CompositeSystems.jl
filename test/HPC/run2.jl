#module load gurobi
#gurobi_cl 1> /dev/null && echo Success || echo 
using Pkg
import Gurobi, JuMP, Dates
Pkg.activate(".")
#Pkg.precompile()
Pkg.instantiate()
using CompositeSystems

gurobi_optimizer_3 = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer, 
    "Presolve"=>1, 
    "PreCrush"=>1, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "NumericFocus"=>3, 
    "Threads"=>64
)

resultspecs = (Shortfall(), Utilization())

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = false
)

timeseriesfile_before = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile_before = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
Base_reliabilityfile_before = "test/data/SMCS/RTS_79_A/R_RTS.m"

timeseriesfile_after_100 = "test/data/RTS/Loads_system.xlsx"
rawfile_after_100 = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile_after_100 = "test/data/others/Storage/R_RTS_strg.m"

timeseriesfile_after_96 = "test/data/RTS/Loads_system.xlsx"
rawfile_after_96 = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile_after_96 = "test/data/others/Storage/R_RTS_strg_2.m"

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
resultspecs = (Shortfall(), Utilization())

sys_before = BaseModule.SystemModel(rawfile_before, Base_reliabilityfile_before, timeseriesfile_before)
sys_after_100 = BaseModule.SystemModel(rawfile_after_100, Base_reliabilityfile_after_100, timeseriesfile_after_100)
sys_after_96 = BaseModule.SystemModel(rawfile_after_96, Base_reliabilityfile_after_96, timeseriesfile_after_96)

sys_before.branches.rate_a[11] = sys_before.branches.rate_a[11]*0.75
sys_before.branches.rate_a[12] = sys_before.branches.rate_a[12]*0.75
sys_before.branches.rate_a[13] = sys_before.branches.rate_a[13]*0.75

sys_after_100.branches.rate_a[11] = sys_after_100.branches.rate_a[11]*0.75
sys_after_100.branches.rate_a[12] = sys_after_100.branches.rate_a[12]*0.75
sys_after_100.branches.rate_a[13] = sys_after_100.branches.rate_a[13]*0.75

sys_after_96.branches.rate_a[11] = sys_after_96.branches.rate_a[11]*0.75
sys_after_96.branches.rate_a[12] = sys_after_96.branches.rate_a[12]*0.75
sys_after_96.branches.rate_a[13] = sys_after_96.branches.rate_a[13]*0.75

hour = Dates.format(Dates.now(),"HH_MM")
current_dir = pwd()
new_dir = mkdir(string("job2_bus9_time_",hour))

shortfall_before, util_before = CompositeSystems.assess(sys_before, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_before, shortfall_before)
CompositeAdequacy.print_results(sys_before, util_before)

sys_after_100.storages.buses[1] = 9
sys_after_100.storages.charge_rating[1] = 1.0
sys_after_100.storages.discharge_rating[1] = 1.0
sys_after_100.storages.thermal_rating[1] = 1.0
sys_after_100.storages.energy_rating[1] = 2.0

shortfall_after_100, _ = CompositeSystems.assess(sys_after_100, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_after_100, shortfall_after_100)

sys_after_96.storages.buses[1] = 9
sys_after_96.storages.charge_rating[1] = 1.0
sys_after_96.storages.discharge_rating[1] = 1.0
sys_after_96.storages.thermal_rating[1] = 1.0
sys_after_96.storages.energy_rating[1] = 2.0

shortfall_after_96, _ = CompositeSystems.assess(sys_after_96, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_after_96, shortfall_after_96)


sys_before_2 = BaseModule.SystemModel(rawfile_before, Base_reliabilityfile_before, timeseriesfile_before)
sys_before_2.branches.rate_a[7] = sys_before_2.branches.rate_a[7]*0.50
sys_before_2.branches.rate_a[14] = sys_before_2.branches.rate_a[14]*0.50
sys_before_2.branches.rate_a[15] = sys_before_2.branches.rate_a[15]*0.50
sys_before_2.branches.rate_a[16] = sys_before_2.branches.rate_a[16]*0.50
sys_before_2.branches.rate_a[17] = sys_before_2.branches.rate_a[17]*0.50
shortfall_before_2, util_before_2 = CompositeSystems.assess(sys_before_2, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_before_2, shortfall_before_2)
CompositeAdequacy.print_results(sys_before_2, util_before_2)

# function run_mcs(system, method, settings, resultspecs, bus::Int)
#     hour = Dates.format(Dates.now(),"HH_MM")
#     current_dir = pwd()
#     new_dir = mkdir(string("ELCC_before_bus_",bus,"_time_",hour))
#     cd(new_dir)
#     for j in 0.25:0.25:2.00
#         system.storages.buses[1] = bus
#         system.storages.charge_rating[1] = j
#         system.storages.discharge_rating[1] = j
#         system.storages.thermal_rating[1] = j
#         for i in 0.25:0.25:3.00
#             system.storages.energy_rating[1] = i
#             shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
#             CompositeAdequacy.print_results(system, shortfall)
#             println("Bus: $(bus) power_rating: $(j), energy_rating: $(i)")
#         end
#     end
# end
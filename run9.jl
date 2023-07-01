#module load gurobi
#gurobi_cl 1> /dev/null && echo Success || echo
#gurobi_cl --tokens
using Pkg
import Gurobi, JuMP, Dates
Pkg.activate(".")
#Pkg.precompile()
Pkg.instantiate()
using CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy

# Set up the Gurobi environment
#const GRB_ENV = Gurobi.Env()()

gurobi_optimizer = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer,
    #"gurobi_env" => GRB_ENV,
    "Presolve"=>1, 
    "PreCrush"=>1, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "NumericFocus"=>3, 
    "Threads"=>64
)

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(;
    gurobi_optimizer,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = false
)

timeseriesfile_before = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
rawfile_before = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
Base_reliabilityfile_before = "test/data/RTS_79_A/R_RTS.m"

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

smc = CompositeAdequacy.SequentialMCS(samples=2000, seed=100, threaded=true)

sys_before = BaseModule.SystemModel(rawfile_before, Base_reliabilityfile_before, timeseriesfile_before)

sys_before.branches.rate_a[11] = sys_before.branches.rate_a[11]*0.75
sys_before.branches.rate_a[12] = sys_before.branches.rate_a[12]*0.75
sys_before.branches.rate_a[13] = sys_before.branches.rate_a[13]*0.75

hour = Dates.format(Dates.now(),"HH_MM")
current_dir = pwd()
new_dir = mkdir(string("job9_bus8_time_",hour))
cd(new_dir)

shortfall_before, util_before = CompositeSystems.assess(sys_before, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_before, shortfall_before)

for max_load in 10:10:200
    params = CompositeAdequacy.ELCC{CompositeAdequacy.SI}(max_load, loads; capacity_gap=3.0, p_value=0.5)
    elcc_loads, base_load, sys_variable = CompositeAdequacy.copy_load(system, params.loads)
    upper_bound = params.capacity_max
    CompositeAdequacy.update_load!(sys_variable, elcc_loads, base_load, upper_bound, system.baseMVA)
    shortfall,availability = CompositeSystems.assess(sys_variable, smc, settings, resultspecs...)
    CompositeAdequacy.print_results(system, shortfall)
end



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
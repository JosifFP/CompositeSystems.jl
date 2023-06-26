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

settings = CompositeSystems.Settings(
    gurobi_optimizer,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = false
)

timeseriesfile_before = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
rawfile_before = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
Base_reliabilityfile_before = "test/data/RTS_79_A/R_RTS.m"

timeseriesfile_after_96 = "test/data/RTS/SYSTEM_LOADS.xlsx"
rawfile_after_96 = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile_after_96 = "test/data/others/Storage/R_RTS_strg_2.m"

sys_before = BaseModule.SystemModel(rawfile_before, Base_reliabilityfile_before, timeseriesfile_before)
sys_after_96 = BaseModule.SystemModel(rawfile_after_96, Base_reliabilityfile_after_96, timeseriesfile_after_96)

sys_before.branches.rate_a[11] = sys_before.branches.rate_a[11]*0.75
sys_before.branches.rate_a[12] = sys_before.branches.rate_a[12]*0.75
sys_before.branches.rate_a[13] = sys_before.branches.rate_a[13]*0.75

sys_after_96.branches.rate_a[11] = sys_after_96.branches.rate_a[11]*0.75
sys_after_96.branches.rate_a[12] = sys_after_96.branches.rate_a[12]*0.75
sys_after_96.branches.rate_a[13] = sys_after_96.branches.rate_a[13]*0.75

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

function run_elcc(sys_before, sys_after, loads, method, settings, resultspecs, bus::Int)
    hour = Dates.format(Dates.now(),"HH_MM")
    current_dir = pwd()
    new_dir = mkdir(string("Job3a_ELCC_after96_bus_",bus,"PR_1_25"))
    cd(new_dir)
    j = 1.25
    sys_after.storages.buses[1] = bus
    sys_after.storages.charge_rating[1] = j
    sys_after.storages.discharge_rating[1] = j
    sys_after.storages.thermal_rating[1] = j
    for i in 0.25:0.25:3.00
        sys_after.storages.energy_rating[1] = i
        max_load = j*100
        capacity_gap = 3.0
        cc = assess(sys_before, sys_after, CompositeAdequacy.CompositeAdequacy.ELCC{CompositeAdequacy.SI}(max_load, loads; capacity_gap=capacity_gap, p_value=0.5), settings, method)
        CompositeAdequacy.print_results(sys_after, cc)
        println("Bus: $(bus) power_rating: $(j), energy_rating: $(i)")
    end
end

println("bus = 8")
run_elcc(sys_before, sys_after_96, loads, smc, settings, resultspecs, 8)
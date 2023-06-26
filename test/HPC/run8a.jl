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

timeseriesfile_after_96 = "test/data/RTS/SYSTEM_LOADS.xlsx"
rawfile_after_96 = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile_after_96 = "test/data/others/Storage/R_RTS_strg_2.m"

method = SequentialMCS(samples=2000, seed=100, threaded=true)
system = BaseModule.SystemModel(rawfile_after_96, Base_reliabilityfile_after_96, timeseriesfile_after_96)

system.branches.rate_a[11] = system.branches.rate_a[11]*0.75
system.branches.rate_a[12] = system.branches.rate_a[12]*0.75
system.branches.rate_a[13] = system.branches.rate_a[13]*0.75

function run_mcs(system, method, settings, resultspecs, bus::Int)
    hour = Dates.format(Dates.now(),"HH_MM")
    current_dir = pwd()
    new_dir = mkdir(string("Job8_shortfall_after96_bus_",bus))
    cd(new_dir)
    for j in 0.25:0.25:2.0
        system.storages.buses[1] = bus
        system.storages.charge_rating[1] = j
        system.storages.discharge_rating[1] = j
        system.storages.thermal_rating[1] = j
        for i in 0.25:0.25:3.0
            system.storages.energy_rating[1] = i
            shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
            CompositeAdequacy.print_results(system, shortfall)
            println("Bus: $(bus) power_rating: $(j), energy_rating: $(i)")
        end
    end
end

println("bus = 8")
run_mcs(system, method, settings, resultspecs, 8)
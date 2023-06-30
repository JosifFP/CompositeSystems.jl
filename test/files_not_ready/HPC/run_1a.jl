#module load gurobi
#gurobi_cl 1> /dev/null && echo Success || echo
#gurobi_cl --tokens
using Pkg
import Gurobi, JuMP, Dates
Pkg.activate(".")
Pkg.instantiate()
using CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy

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

settings_dc = CompositeSystems.Settings(
    gurobi_optimizer,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = false
)

settings_ac = CompositeSystems.Settings(
    gurobi_optimizer,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.LPACCPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = false
)

timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
rawfile = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"


smc_1 = CompositeAdequacy.SequentialMCS(samples=7500, seed=100, threaded=true)
smc_2 = CompositeAdequacy.SequentialMCS(samples=15000, seed=100, threaded=true)

sys = BaseModule.SystemModel(rawfile_before, Base_reliabilityfile_before, timeseriesfile_before)

hour = Dates.format(Dates.now(),"HH_MM")
current_dir = pwd()
new_dir = mkdir(string("hour"))
cd(new_dir)

function run_smc(sys, method, settings, resultspecs)
    shortfall_nonthreaded, util = CompositeSystems.assess(sys, method, settings, resultspecs...)
    CompositeAdequacy.print_results(sys, shortfall_nonthreaded)
    CompositeAdequacy.print_results(sys, util)
    println("$(method.powermodel_formulation)")
end

run_smc(sys, smc_1, settings_dc, resultspecs)
run_smc(sys, smc_2, settings_dc, resultspecs)
#run_smc(sys, smc_1, settings_ac, resultspecs)
#run_smc(sys, smc_2, settings_ac, resultspecs)
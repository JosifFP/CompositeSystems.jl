using Pkg
import Gurobi
Pkg.instantiate()
#Pkg.resolve()
using CompositeSystems

gurobi_optimizer_3 = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer, 
    "Presolve"=>1, 
    "PreCrush"=>1, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "NumericFocus"=>3, 
    "Threads"=>16
)

#timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
#rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
#Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"

timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
rawfile = "test/data/RBTS/Base/RBTS_AC.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"

resultspecs = (Shortfall(), GeneratorAvailability())

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    #powermodel_formulation = OPF.LPACCPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    min_generators_off = 1,
    set_string_names_on_creation = false,
    count_samples = true
)

system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = SequentialMCS(samples=16, seed=100, threaded=false)

shortfall,availability = CompositeSystems.assess(system, method, settings, resultspecs...)
println("END")

# CompositeSystems.LOLE.(shortfall, system.buses.keys)
# CompositeSystems.EENS.(shortfall, system.buses.keys)
# CompositeSystems.LOLE.(shortfall)
# CompositeSystems.EENS.(shortfall)
# val.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
# val.(CompositeSystems.EENS.(shortfall, system.buses.keys))

# CompositeSystems.print_results(system, shortfall)

#addprocs(SlurmManager(1), t="00:05:00", A="def-kbubbar", qos="short")
#julia --project="." --startup-file=no "test/run.jl"
#SBATCH --mem-per-cpu=8000M
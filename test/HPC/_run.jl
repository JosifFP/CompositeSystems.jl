using Pkg
import Gurobi, JuMP
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
    "Threads"=>48
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

timeseriesfile = "test/data/RTS/Loads_system.xlsx"
rawfile = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile = "test/data/others/Storage/R_RTS_strg.m"
method = SequentialMCS(samples=2000, seed=100, threaded=true)
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

system.branches.rate_a[11] = system.branches.rate_a[11]*0.75
system.branches.rate_a[12] = system.branches.rate_a[12]*0.75
system.branches.rate_a[13] = system.branches.rate_a[13]*0.75

function run_mcs(system, method, settings, resultspecs, bus::Int)
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
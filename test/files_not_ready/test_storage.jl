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
    #powermodel_formulation = OPF.NFAPowerModel,
    #powermodel_formulation = OPF.DCPPowerModel,
    powermodel_formulation = OPF.DCMPPowerModel,
    #powermodel_formulation = OPF.LPACCPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = false,
    count_samples=true,
)

timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
rawfile = "test/data/others/Storage/RBTS_strg.m"
reliabilityfile_1 = "test/data/others/Storage/R_RBTS_strg.m"
system_1 = BaseModule.SystemModel(rawfile, reliabilityfile_1, timeseriesfile)
system_1.storages.buses[1] = 6
system_1.storages.charge_rating[1] = 0.25
system_1.storages.discharge_rating[1] = 0.25
system_1.storages.thermal_rating[1] = 0.25
system_1.storages.energy_rating[1] = 2

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
method = SequentialMCS(samples=1000, seed=100, threaded=true)
shortfall,availability = CompositeSystems.assess(system_1, method, settings, resultspecs...)
CompositeAdequacy.print_results(system_1, shortfall)



reliabilityfile_2 = "test/data/others/Storage/R_RBTS_strg_2.m"
system_2 = BaseModule.SystemModel(rawfile, reliabilityfile_2, timeseriesfile)
system_2.storages.buses[1] = 6
system_2.storages.charge_rating[1] = 0.25
system_2.storages.discharge_rating[1] = 0.25
system_2.storages.thermal_rating[1] = 0.25
system_2.storages.energy_rating[1] = 2

method = SequentialMCS(samples=1000, seed=100, threaded=true)
shortfall,availability = CompositeSystems.assess(system_2, method, settings, resultspecs...)
CompositeAdequacy.print_results(system_2, shortfall)



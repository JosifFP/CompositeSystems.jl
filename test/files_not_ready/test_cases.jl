using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using XLSX, Dates
#using ProfileView, Profile

include("solvers.jl")
#timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
#rawfile = "test/data/RBTS/Base/RBTS.m"
#Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"

#timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
#rawfile = "test/data/others/Storage/RBTS_strg.m"
#Base_reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"

#timeseriesfile = "test/data/SMCS/MRBTS/SYSTEM_LOADS.xlsx"
#rawfile = "test/data/SMCS/MRBTS/MRBTS_AC.m"
#Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"

timeseriesfile = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
rawfile = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
Base_reliabilityfile = "test/data/RTS_79_A/R_RTS.m"

#timeseriesfile = "test/data/toysystem/SYSTEM_LOADS.xlsx"
#rawfile = "test/data/toysystem/toysystem.m"
#Base_reliabilityfile = "test/data/toysystem/R_toysystem.m"

resultspecs = (Shortfall(), GeneratorAvailability())
settings = CompositeSystems.Settings(
    gurobi_optimizer_2,
    jump_modelmode = JuMP.AUTOMATIC,
    #powermodel_formulation = OPF.NFAPowerModel,
    #powermodel_formulation = OPF.DCPPowerModel,
    powermodel_formulation = OPF.DCMPPowerModel,
    #powermodel_formulation = OPF.LPACCPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = false,
    count_samples=true,
)

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

cap = 6.0
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = SequentialMCS(samples=5, seed=100, threaded=true)
params = CompositeAdequacy.ELCC{CompositeAdequacy.SI}(cap, loads; capacity_gap=6.0)
elcc_loads, base_load, sys_variable = copy_load(system, params.loads)
upper_bound = params.capacity_max
update_load!(sys_variable, elcc_loads, base_load, upper_bound, system.baseMVA)
shortfall,availability = CompositeSystems.assess(sys_variable, method, settings, resultspecs...)
CompositeAdequacy.print_results(system, shortfall)



CompositeSystems.EDLC.(shortfall, system.buses.keys)
CompositeSystems.EENS.(shortfall, system.buses.keys)
CompositeSystems.SI.(shortfall, system.buses.keys)
CompositeSystems.EDLC.(shortfall) 
CompositeSystems.EENS.(shortfall)
CompositeSystems.SI.(shortfall)
val.(CompositeSystems.EDLC.(shortfall, system.buses.keys))
val.(CompositeSystems.EENS.(shortfall, system.buses.keys))
val.(CompositeSystems.SI.(shortfall, system.buses.keys))


system.storages.buses[1] = 2
system.storages.charge_rating[1] = 0.25
system.storages.discharge_rating[1] = 0.25
system.storages.thermal_rating[1] = 0.25
system.storages.energy_rating[1] = 0.5


timestamprow = permutedims(system.timestamps)
busescol = system.buses.keys
println("SpatioTemporal LOLPs:")
display(vcat(
    hcat("", timestamprow),
    hcat(busescol, EDLC(shortfall, :, :))
)); println()

println("SpatioTemporal EUEs:")
display(vcat(
    hcat("", timestamprow),
    hcat(busescol, EENS(shortfall, :, :))
)); println()

a=shortfall.eventperiod_period_mean*100
sum(a)
using Plots
plot(1:8736, a)

a=shortfall.shortfall_busperiod_std*100
sum(a)
using Plots
a
plot(1:8736, a[6,:])

CompositeAdequacy.seed!(rng, (method.seed, s))
CompositeAdequacy.initialize_states!(rng, states, system)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
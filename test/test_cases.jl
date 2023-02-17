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
timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
rawfile = "test/data/RBTS/Base/RBTS_AC.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"

#timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
#rawfile = "test/data/others/Storage/RBTS_strg.m"
#Base_reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"

#timeseriesfile = "test/data/SMCS/MRBTS/Loads_system.xlsx"
#rawfile = "test/data/SMCS/MRBTS/MRBTS_AC.m"
#Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"

#timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
#rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
#Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS3.m"

#timeseriesfile = "test/data/toysystem/Loads_system.xlsx"
#rawfile = "test/data/toysystem/toysystem.m"
#Base_reliabilityfile = "test/data/toysystem/R_toysystem.m"

resultspecs = (Shortfall(), GeneratorAvailability())
settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    #powermodel_formulation = OPF.NFAPowerModel,
    powermodel_formulation = OPF.DCPPowerModel,
    #powermodel_formulation = OPF.DCMPPowerModel,
    #powermodel_formulation = OPF.LPACCPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    min_generators_off = 1,
    set_string_names_on_creation = false
)

system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = SequentialMCS(samples=15000, seed=100, threaded=true)

@time shortfall,availability = CompositeSystems.assess(system, method, settings, resultspecs...)

CompositeSystems.LOLE.(shortfall, system.buses.keys)
CompositeSystems.EENS.(shortfall, system.buses.keys)
CompositeSystems.LOLE.(shortfall)
CompositeSystems.EENS.(shortfall)
val.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
val.(CompositeSystems.EENS.(shortfall, system.buses.keys))




system.storages.buses[1] = 2
system.storages.charge_rating[1] = 0.25
system.storages.discharge_rating[1] = 0.25
system.storages.thermal_rating[1] = 0.25
system.storages.energy_rating[1] = 0.5


shortfall.eventperiod_mean
shortfall.eventperiod_std
shortfall.eventperiod_bus_mean
shortfall.eventperiod_bus_std
shortfall.eventperiod_period_mean
shortfall.eventperiod_period_std
shortfall.eventperiod_busperiod_mean
shortfall.eventperiod_busperiod_std
shortfall.shortfall_mean
shortfall.shortfall_std
shortfall.shortfall_bus_std
shortfall.shortfall_period_std
shortfall.shortfall_busperiod_std

timestamprow = permutedims(system.timestamps)
busescol = system.buses.keys
println("SpatioTemporal LOLPs:")
display(vcat(
    hcat("", timestamprow),
    hcat(busescol, LOLE(shortfall, :, :))
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
using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using XLSX, Dates
include("solvers.jl")

resultspecs = (Shortfall(), GeneratorAvailability())
settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    set_string_names_on_creation = false
)

timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
rawfile = "test/data/others/Storage/RBTS_strg.m"
Base_reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
resultspecs = (Shortfall(), GeneratorAvailability())
method = SequentialMCS(samples=5000, seed=100, threaded=true)
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

for bus in 1:1:6
    run_mcs(system, method, settings, resultspecs, bus)
end

function run_mcs(system, method, settings, resultspecs, bus::Int)
    system.storages.buses[1] = bus
    system.storages.charge_rating[1] = 0.25
    system.storages.discharge_rating[1] = 0.25
    system.storages.thermal_rating[1] = 0.25
    for i in 0.5:0.5:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

    system.storages.charge_rating[1] = 0.50
    system.storages.discharge_rating[1] = 0.50
    system.storages.thermal_rating[1] = 0.50
    for i in 0.5:0.5:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

    system.storages.charge_rating[1] = 0.75
    system.storages.discharge_rating[1] = 0.75
    system.storages.thermal_rating[1] = 0.75
    for i in 0.5:0.5:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

    system.storages.charge_rating[1] = 1.0
    system.storages.discharge_rating[1] = 1.0
    system.storages.thermal_rating[1] = 1.0
    for i in 0.5:0.5:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

end

function print_results(shortfall::CompositeAdequacy.ShortfallResult)
    XLSX.openxlsx("results_shortfall"*Dates.format(Dates.now(),"HHMMSS")*".xlsx", mode="w") do xf
        XLSX.rename!(xf[1], "summary")
        xf[1]["A1"] = "eventperiod_mean"
        xf[1]["A2"] = shortfall.eventperiod_mean
        xf[1]["B1"] = "eventperiod_std"
        xf[1]["B2"] = shortfall.eventperiod_std
        xf[1]["C1"] = "eventperiod_bus_mean"
        xf[1]["C2", dim=1] = collect(shortfall.eventperiod_bus_mean)
        xf[1]["D1"] = "eventperiod_bus_std"
        xf[1]["D2", dim=1] = collect(shortfall.eventperiod_bus_std)
        xf[1]["E1"] = "eventperiod_period_mean"
        xf[1]["E2", dim=1] = collect(shortfall.eventperiod_period_mean)
        xf[1]["F1"] = "eventperiod_period_std"
        xf[1]["F2", dim=1] = collect(shortfall.eventperiod_period_std)
        xf[1]["G1"] = "shortfall_std"
        xf[1]["G2"] = shortfall.shortfall_std
        xf[1]["H1"] = "shortfall_bus_std"
        xf[1]["H2", dim=1] = collect(shortfall.shortfall_bus_std)
        xf[1]["I1"] = "shortfall_period_std"
        xf[1]["I2", dim=1] = collect(shortfall.shortfall_period_std)
        xf[1]["J1"] = "LOLE-MEAN"
        xf[1]["J2", dim=1] = collect(val.(CompositeSystems.LOLE.(shortfall, system.buses.keys)))
        xf[1]["K1"] = "EENS-MEAN"
        xf[1]["K2", dim=1] = collect(val.(CompositeSystems.EENS.(shortfall, system.buses.keys)))
        XLSX.addsheet!(xf, "eventperiod_busperiod_mean")
        xf[2]["A1"] = collect(shortfall.eventperiod_busperiod_mean')
        XLSX.addsheet!(xf, "eventperiod_busperiod_std")
        xf[3]["A1"] = collect(shortfall.eventperiod_busperiod_std')
        XLSX.addsheet!(xf, "shortfall_mean")
        xf[4]["A1"] = collect(shortfall.shortfall_mean')
        XLSX.addsheet!(xf, "shortfall_busperiod_std")
        xf[5]["A1"] = collect(shortfall.shortfall_busperiod_std')
        XLSX.addsheet!(xf, "data")
        xf[6]["A1"] =  "energy_rating"
        xf[6]["B1"] = system.storages.energy_rating[1]
        xf[6]["A2"] =  "buses"
        xf[6]["B2"] = system.storages.buses[1]
        xf[6]["A3"] =  "charge_rating"
        xf[6]["B3"] = system.storages.charge_rating[1]
        xf[6]["A4"] =  "discharge_rating"
        xf[6]["B4"] = system.storages.discharge_rating[1]
        xf[6]["A5"] =  "thermal_rating"
        xf[6]["B5"] = system.storages.thermal_rating[1]
    end
    return
end
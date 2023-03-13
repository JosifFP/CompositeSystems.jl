import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP
import JuMP: termination_status
import BenchmarkTools: @btime
import Dates, XLSX
using Test

include("solvers.jl")
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.GeneratorAvailability())

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    min_generators_off = 0,
    set_string_names_on_creation = false,
    count_samples = false
)
timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
rawfile = "test/data/RBTS/Base/RBTS_AC.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = CompositeAdequacy.SequentialMCS(samples=150, seed=100, threaded=true)
@time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)


method = CompositeAdequacy.SequentialMCS(samples=15000, seed=100, threaded=true)
run_mcs(method, resultspecs)


function run_mcs(method, resultspecs)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCMPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 0,
        set_string_names_on_creation = false,
        count_samples = false
    )
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    rawfile = "test/data/RBTS/Base/RBTS_AC.m"
    Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    _print_results(system, shortfall)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCMPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 1,
        set_string_names_on_creation = false,
        count_samples = false
    )
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    _print_results(system, shortfall)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.LPACCPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 0,
        set_string_names_on_creation = false,
        count_samples = false
    )
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    _print_results(system, shortfall)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.LPACCPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 1,
        set_string_names_on_creation = false,
        count_samples = false
    )
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    _print_results(system, shortfall)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCMPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 0,
        set_string_names_on_creation = false,
        count_samples = false
    )
    timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
    rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
    Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    _print_results(system, shortfall)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCMPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 1,
        set_string_names_on_creation = false,
        count_samples = false
    )
    timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
    rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
    Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    _print_results(system, shortfall)

end

""
function _print_results(system::BaseModule.SystemModel, shortfall::CompositeAdequacy.ShortfallResult)
    XLSX.openxlsx("results_shortfall"*Dates.format(Dates.now(),"HHMMSS")*".xlsx", mode="w") do xf
        XLSX.rename!(xf[1], "summary")

        xf[1]["A1"] = "mean system LOLE"
        xf[1]["A2"] = CompositeAdequacy.val.(CompositeAdequacy.LOLE.(shortfall))
        xf[1]["B1"] = "stderror LOLE"
        xf[1]["B2"] = CompositeAdequacy.stderror.(CompositeAdequacy.LOLE.(shortfall))
        xf[1]["C1"] = "LOLE-MEAN"
        xf[1]["C2", dim=1] = collect(CompositeAdequacy.val.(CompositeAdequacy.LOLE.(shortfall, system.buses.keys)))
        xf[1]["D1"] = "LOLE-STDERROR"
        xf[1]["D2", dim=1] = collect(CompositeAdequacy.stderror.(CompositeAdequacy.LOLE.(shortfall, system.buses.keys)))

        xf[1]["E1"] = "mean system EENS"
        xf[1]["E2"] = CompositeAdequacy.val.(CompositeAdequacy.EENS.(shortfall))
        xf[1]["F1"] = "stderror EENS"
        xf[1]["F2"] = CompositeAdequacy.stderror.(CompositeAdequacy.EENS.(shortfall))
        xf[1]["G1"] = "EENS-MEAN"
        xf[1]["G2", dim=1] = collect(CompositeAdequacy.val.(CompositeAdequacy.EENS.(shortfall, system.buses.keys)))
        xf[1]["H1"] = "EENS-STDERROR"
        xf[1]["H2", dim=1] = collect(CompositeAdequacy.stderror.(CompositeAdequacy.EENS.(shortfall, system.buses.keys)))

        xf[1]["I1"] = "eventperiod_mean"
        xf[1]["I2"] = shortfall.eventperiod_mean
        xf[1]["J1"] = "eventperiod_std"
        xf[1]["J2"] = shortfall.eventperiod_std
        xf[1]["K1"] = "eventperiod_bus_mean"
        xf[1]["K2", dim=1] = collect(shortfall.eventperiod_bus_mean)
        xf[1]["L1"] = "eventperiod_bus_std"
        xf[1]["L2", dim=1] = collect(shortfall.eventperiod_bus_std)
        xf[1]["M1"] = "eventperiod_period_mean"
        xf[1]["M2", dim=1] = collect(shortfall.eventperiod_period_mean)
        xf[1]["N1"] = "eventperiod_period_std"
        xf[1]["N2", dim=1] = collect(shortfall.eventperiod_period_std)
        xf[1]["O1"] = "shortfall_std"
        xf[1]["O2"] = shortfall.shortfall_std
        xf[1]["P1"] = "shortfall_bus_std"
        xf[1]["P2", dim=1] = collect(shortfall.shortfall_bus_std)
        xf[1]["Q1"] = "shortfall_period_std"
        xf[1]["Q2", dim=1] = collect(shortfall.shortfall_period_std)

        XLSX.addsheet!(xf, "eventperiod_busperiod_mean")
        xf[2]["A1"] = collect(shortfall.eventperiod_busperiod_mean')
        XLSX.addsheet!(xf, "eventperiod_busperiod_std")
        xf[3]["A1"] = collect(shortfall.eventperiod_busperiod_std')
        XLSX.addsheet!(xf, "shortfall_mean")
        xf[4]["A1"] = collect(shortfall.shortfall_mean')
        XLSX.addsheet!(xf, "shortfall_busperiod_std")
        xf[5]["A1"] = collect(shortfall.shortfall_busperiod_std')
    end
    return
end





settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    min_generators_off = 1,
    set_string_names_on_creation = false,
    count_samples = false
)

timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
rawfile = "test/data/RBTS/Base/RBTS_AC.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
@time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
CompositeAdequacy.val.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
CompositeAdequacy.stderror.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
CompositeAdequacy.val.(CompositeSystems.LOLE.(shortfall))
CompositeAdequacy.stderror.(CompositeSystems.LOLE.(shortfall))

CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, system.buses.keys))
CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall, system.buses.keys))
CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall))
CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall))

@testset "Sequential MCS, 1000 samples, RBTS" begin
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    rawfile = "test/data/RBTS/Base/RBTS_AC.m"
    Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    @test isapprox(CompositeAdequacy.val.(CompositeSystems.LOLE.(shortfall, system.buses.keys)), [0.0, 0.0, 1.182, 0.0, 0.002, 10.357]; atol = 1e-3)
    @test isapprox(CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, system.buses.keys)), [0.0, 0.0, 10.682, 0.0, 0.0194, 127.212]; atol = 1e-3)
end
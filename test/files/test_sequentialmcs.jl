import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP
import JuMP: termination_status
import BenchmarkTools: @btime
import Dates, XLSX
using Test, BenchmarkTools

include("solvers.jl")
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.GeneratorAvailability())

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    min_generators_off = 0,
    set_string_names_on_creation = true,
    count_samples = false
)

method = CompositeAdequacy.SequentialMCS(samples=15000, seed=100, threaded=true)

run_mcs(method, resultspecs)


function run_mcs(method, resultspecs)

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
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)

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
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)


    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
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
    CompositeSystems.print_results(system, shortfall)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 1,
        set_string_names_on_creation = false,
        count_samples = false
    )
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)

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
    CompositeSystems.print_results(system, shortfall)


    timeseriesfile = "test/data/SMCS/MRBTS/Loads_system.xlsx"
    rawfile = "test/data/SMCS/MRBTS/MRBTS_AC.m"
    Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)

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
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)

    timeseriesfile = "test/data/SMCS/MRBTS/Loads_system.xlsx"
    rawfile = "test/data/SMCS/MRBTS/MRBTS_AC.m"
    Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)

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
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)


    timeseriesfile = "test/data/SMCS/MRBTS/Loads_system.xlsx"
    rawfile = "test/data/SMCS/MRBTS/MRBTS_AC.m"
    Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 0,
        set_string_names_on_creation = false,
        count_samples = false
    )
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)


    timeseriesfile = "test/data/SMCS/MRBTS/Loads_system.xlsx"
    rawfile = "test/data/SMCS/MRBTS/MRBTS_AC.m"
    Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)

    settings = CompositeSystems.Settings(
        gurobi_optimizer_3,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        min_generators_off = 1,
        set_string_names_on_creation = false,
        count_samples = false
    )
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    CompositeSystems.print_results(system, shortfall)


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
    CompositeSystems.print_results(system, shortfall)

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
    CompositeSystems.print_results(system, shortfall)

end





CompositeAdequacy.val.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
CompositeAdequacy.stderror.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
CompositeAdequacy.val.(CompositeSystems.LOLE.(shortfall))
CompositeAdequacy.stderror.(CompositeSystems.LOLE.(shortfall))

CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, system.buses.keys))
CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall, system.buses.keys))
CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall))
CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall))













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
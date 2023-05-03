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
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = false,
    count_samples = true
)

timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH_modified.m"
Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"

@testset "Sequential MCS, 1000 samples, RBTS" begin
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=false)
    shortfall_nonthreaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

    system_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.18, 0.0, 9.90999, 0.05, 0.0, 0.0, 
        0.0, 2.47, 0.0, 0.0, 0.0, 0.0, 0.47, 0.0, 0.0, 0.0, 0.0, 0.0]
    system_EENS_mean = [0.0, 0.0,0.0, 0.0, 0.0, 0.0, 311.87604, 0.0, 860.64678, 0.7952012, 0.0, 0.0, 
        0.0, 204.64005, 0.0, 0.0, 0.0, 0.0, 26.258191, 0.0, 0.0, 0.0, 0.0, 0.0]
    system_SI_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 6.56581, 0.0, 18.11888, 0.01674,
        0.0, 0.0, 0.0, 4.30821, 0.0, 0.0, 0.0, 0.0, 0.55280, 0.0, 0.0, 0.0, 0.0, 0.0]

    system_EDLC_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.86356, 0.0, 1.50454, 0.04999, 0.0, 0.0,
            0.0, 0.57479, 0.0, 0.0, 0.0, 0.0, 0.20323, 0.0, 0.0, 0.0, 0.0, 0.0]

    system_EENS_stderror= [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 65.93037, 0.0, 154.70595, 0.7952011, 0.0, 
            0.0, 0.0, 59.059926, 0.0, 0.0, 0.0, 0.0, 14.025190, 0.0, 0.0, 0.0, 0.0, 0.0]
    system_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.38801, 0.0, 3.25697, 0.01674, 0.0, 0.0,
            0.0, 1.24337, 0.0, 0.0, 0.0, 0.0, 0.29527, 0.0, 0.0, 0.0, 0.0, 0.0]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_nonthreaded, system.buses.keys)), 
        system_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_nonthreaded, system.buses.keys)), 
        system_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_nonthreaded, system.buses.keys)), 
        system_SI_mean; atol = 1e-4)

    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall_nonthreaded, system.buses.keys)), 
        system_EDLC_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall_nonthreaded, system.buses.keys)), 
        system_EENS_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall_nonthreaded, system.buses.keys)), 
        system_SI_stderror; atol = 1e-4)


    
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true)
    shortfall_threaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_threaded, system.buses.keys)), 
        system_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_threaded, system.buses.keys)), 
        system_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_threaded, system.buses.keys)), 
        system_SI_mean; atol = 1e-4)

    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall_threaded, system.buses.keys)), 
        system_EDLC_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall_threaded, system.buses.keys)), 
        system_EENS_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall_threaded, system.buses.keys)), 
        system_SI_stderror; atol = 1e-4)

end
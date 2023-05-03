import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP
import JuMP: termination_status
import BenchmarkTools: @btime
import Dates, XLSX
using Test, BenchmarkTools
using ProfileView, Profile

include("solvers.jl")
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

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
rawfile = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
#getindex(util, :)
#CompositeAdequacy.PTV(util, :)

@testset "Sequential MCS, 1000 samples, RBTS" begin
    method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=false)
    shortfall_nonthreaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

    system_EDLC_mean = [0.0, 0.0, 1.18200, 0.0, 0.00200, 10.35400]
    system_EENS_mean = [0.0, 0.0, 10.68267, 0.0, 0.01941, 127.18585]
    system_SI_mean = [0.0, 0.0, 3.46465, 0.0, 0.00629, 41.24946]

    system_EDLC_stderror = [0.0, 0.0, 0.13081, 0.0, 0.00200, 0.45317]
    system_EENS_stderror= [0.0, 0.0, 1.66407, 0.0, 0.01941, 5.61568]
    system_SI_stderror = [0.0, 0.0, 0.53969, 0.0, 0.00629, 1.82130]

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


    
    method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=true)
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


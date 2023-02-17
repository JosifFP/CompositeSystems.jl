import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP
import JuMP: termination_status
import BenchmarkTools: @btime
using Test

include("solvers.jl")

resultspecs = (Shortfall(), GeneratorAvailability())
method = SequentialMCS(samples=1000, seed=100, threaded=true)

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    min_generators_off = 1,
    set_string_names_on_creation = false
)

@testset "Sequential MCS, 1000 samples, RBTS" begin
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    rawfile = "test/data/RBTS/Base/RBTS_AC.m"
    Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    @time shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    @test isapprox(val.(CompositeSystems.LOLE.(shortfall, system.buses.keys)), [0.0, 0.0, 1.182, 0.0, 0.002, 10.357]; atol = 1e-3)
    @test isapprox(val.(CompositeSystems.EENS.(shortfall, system.buses.keys)), [0.0, 0.0, 10.682, 0.0, 0.0194, 127.212]; atol = 1e-3)
end
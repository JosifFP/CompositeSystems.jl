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
    method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=true)
    shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    system_EDLC_ps = [0.0, 0.0, 1.18200, 0.0, 0.00200, 10.35400]
    system_EENS_ps = [0.0, 0.0, 10.68267, 0.0, 0.01941, 127.185849]
    @test isapprox(CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, system.buses.keys)), system_EDLC_ps; atol = 1e-4)
    @test isapprox(CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, system.buses.keys)), system_EENS_ps; atol = 1e-4)

    method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=false)
    shortfall,_ = CompositeSystems.assess(system, method, settings, resultspecs...)
    system_EDLC = [0.0, 0.0, 1.18200, 0.0, 0.00200, 10.35400]
    system_EENS = [0.0, 0.0, 10.68267, 0.0, 0.01941, 127.185849]
    @test isapprox(CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, system.buses.keys)), system_EDLC; atol = 1e-4)
    @test isapprox(CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, system.buses.keys)), system_EENS; atol = 1e-4)
end

# CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, system.buses.keys))
# CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall, system.buses.keys))
# CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall))
# CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall))
# CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, system.buses.keys))
# CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall, system.buses.keys))
# CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall))
# CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall))


#using Pkg
#import Gurobi, JuMP, Dates
#Pkg.activate(".")
#Pkg.instantiate()
#using CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy
#Pkg.resolve()

import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP
import JuMP: termination_status
import BenchmarkTools: @btime
using Test

include("solvers.jl")


#@testset "Testset of OPF formulations + Load Curtailment minimization" begin
    #BaseModule.silence()
    #include("test_curtailed_load.jl")
    #include("test_storage.jl")
    #include("test_smcs.jl")

    #include("test_opf_form.jl")
#end;


resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Shortfall())
#resultspecs = (CompositeAdequacy.Utilization(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    min_generators_off = 0,
    set_string_names_on_creation = false,
    count_samples = true
)

timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
rawfile = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = CompositeAdequacy.SequentialMCS(samples=200, seed=100, threaded=true)
shortfall_nonthreaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)




CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_nonthreaded, system.buses.keys))
CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_nonthreaded, system.buses.keys))

system_EDLC_mean = [0.0, 0.0, 1.18200, 0.0, 0.00200, 10.35400]
system_EENS_mean = [0.0, 0.0, 10.68267, 0.0, 0.01941, 127.18585]
system_SI_mean = [0.0, 0.0, 3.46465, 0.0, 0.00629, 41.24946]


@test isapprox(
    CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_nonthreaded, system.buses.keys)), 
    system_EDLC_mean; atol = 1e-4)
@test isapprox(
    CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_nonthreaded, system.buses.keys)), 
    system_EENS_mean; atol = 1e-4)
@test isapprox(
    CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_nonthreaded, system.buses.keys)), 
    system_SI_mean; atol = 1e-4)
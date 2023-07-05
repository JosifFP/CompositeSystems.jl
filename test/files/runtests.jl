import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP, Dates
import JuMP: termination_status
import BenchmarkTools: @btime
import Gurobi
import Distributed
using Test

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    #set_string_names_on_creation = false,
    count_samples = true
)

timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
rawfile = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true, distributed=false)
shortfall_threaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)



include("solvers.jl")

@testset "Testset of OPF formulations + Load Curtailment minimization" begin
    BaseModule.silence()
    include("test_curtailed_load.jl")
    include("test_storage.jl")
    include("test_smcs.jl")
    include("test_opf_form.jl")
end;
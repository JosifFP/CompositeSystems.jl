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

#include("solvers.jl")
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    count_samples = true
)

timeseriesfile = "test/data/RTS/SYSTEM_LOADS.xlsx"
rawfile = "test/data/RTS/Base/RTS.m"
Base_reliabilityfile = "test/data/RTS/Base/R_RTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = CompositeAdequacy.SequentialMCS(samples=500, seed=100, threaded=true)


shortfall_threaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_threaded, system.buses.keys))
CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_threaded))
CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_threaded))

@testset "Testset of OPF formulations + Load Curtailment minimization" begin
    BaseModule.silence()
    include("test_curtailed_load_dc.jl")
    include("test_curtailed_load_ac.jl")
    include("test_storage.jl")
    include("test_opf_form.jl")
    #These testsets require Gurobi license
    include("test_smcs_non_threaded.jl")
    include("test_smcs_threaded.jl")
    include("test_smcs_distributed.jl")
end;


using Distributed

# instantiate and precompile environment in all processes
@everywhere begin
  using Pkg; Pkg.activate(@__DIR__)
  Pkg.instantiate(); Pkg.precompile()
end

@everywhere begin
    # load dependencies
    using Gurobi, Dates, JuMP
    using CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy
end

@everywhere begin

    settings = CompositeSystems.Settings(;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCMPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        set_string_names_on_creation = false,
        count_samples = true
    )
  
    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RBTS/Base/RBTS.m"
    Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    library = String[rawfile; Base_reliabilityfile; timeseriesfile]
    method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true, distributed=true)
    resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
end

total_result = CompositeSystems.assess(library, method, settings, resultspecs...)
system = BaseModule.SystemModel(library[1], library[2], library[3])
shortfall_threaded, util = CompositeAdequacy.finalize.(total_result, sys)
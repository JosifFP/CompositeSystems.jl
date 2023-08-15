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

include("solvers.jl")

@testset "Testset of OPF formulations + Load Curtailment minimization" begin

    BaseModule.silence()
    include("test_curtailed_load_dc.jl")
    include("test_curtailed_load_ac.jl")
    include("test_storage.jl")
    include("test_opf_form.jl")
    #These testsets require Gurobi license.
    include("test_smcs_non_threaded.jl") #It may take more than 1 hr.
    include("test_smcs_threaded.jl") #It may take more than 1 hr.
    include("elcc.jl")
    include("eesc.jl")
    include("test_smcs_distributed.jl") #It might fail since it is not the best way to test distributed computing in 1 machine.
end;
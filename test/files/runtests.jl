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
    include("test_curtailed_load.jl")
    include("test_storage.jl")
    include("test_smcs.jl")
    include("test_opf_form.jl")
end;
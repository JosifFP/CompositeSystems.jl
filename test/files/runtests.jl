import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP
import JuMP: termination_status
import BenchmarkTools: @btime
using Test

include("solvers.jl")

@testset "Testset of OPF formulations + Load Curtailment minimization" begin
    BaseModule.silence()
    include("test_storage.jl") #has to be updated
    include("test_opf_form.jl")
    include("test_curtailed_load.jl")
    include("test_smcs_rbts.jl")
    include("test_smcs_rts.jl")
end;

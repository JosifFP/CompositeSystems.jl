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
    include("test_opf_form.jl")
    include("test_nonsequential_outages.jl")
    include("test_sequential_outages.jl")
    include("test_load_curtailment.jl")
end;

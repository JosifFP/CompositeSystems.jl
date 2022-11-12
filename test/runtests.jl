import PRATS
import PRATS.BaseModule
import PRATS.OPF
import PRATS.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using Test

@testset "Contingency Solver: split network situations" begin
    PRATS.silence()
    include("test_opf.jl")
    include("test_opf2.jl")
end;



using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test

@testset "Contingency Solver: split network situations" begin
    PRATS.silence()
    PRATSBase.silence()
    include("test_solver.jl")
end;
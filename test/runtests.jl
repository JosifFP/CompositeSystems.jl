import PRATS
import PRATS.PRATSBase
import PRATS.CompositeAdequacy: CompositeAdequacy, field, Topology, SystemStates
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test

@testset "Contingency Solver: split network situations" begin
    PRATS.silence()
    PRATSBase.silence()
    include("test_solver.jl")
end;
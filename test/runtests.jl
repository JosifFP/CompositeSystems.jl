import PRATS
import PRATS.PRATSBase
import PRATS.CompositeAdequacy: CompositeAdequacy, field, Topology, SystemStates, sol, Cache, 
    SystemStates, PowerFlowProblem, SystemModel, SequentialMCS
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test

@testset "Contingency Solver: split network situations" begin
    PRATS.silence()
    include("test_solver.jl")
    #include("test_solver2.jl")
end;



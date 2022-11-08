import PRATS: PRATS, BaseModule
import PRATS.BaseModule: BaseModule, field, SystemModel
import PRATS.OPF: OPF, Topology, Initialize_model, sol, build_sol_values, var, sol, empty!, field
import PRATS.CompositeAdequacy: CompositeAdequacy, field, SystemStates, SequentialMCS, update!, solve!, empty_model!
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test

@testset "Contingency Solver: split network situations" begin
    PRATS.silence()
    include("test_opf.jl")
end;



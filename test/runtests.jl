using CompositeSystems
using Test
import PowerModels, Ipopt, BenchmarkTools, JuMP, Dates
import JuMP: JuMP, optimizer_with_attributes, termination_status
import BenchmarkTools: @btime
import Gurobi, Juniper, Ipopt
import Distributed

include("files/solvers.jl")
include("files/common.jl")

@testset verbose=true "Testset of OPF formulations + Load Curtailment minimization, using Juniper solver" begin
    BaseModule.silence()
    include("files/SystemModel.jl")
    include("files/opf_formulations.jl")
    include("files/load_minimization_dcp.jl")
    include("files/load_minimization_dcmp.jl")
    include("files/load_minimization_lpacc.jl")
    include("files/storage_model.jl")
end;

@testset verbose=true "Test sequential Monte Carlo Simulations using Gurobi License" begin
    @info "These testsets require Gurobi license."
    BaseModule.silence()
    a = Ref{Ptr{Cvoid}}()
    ret = Gurobi.GRBloadenv(a, C_NULL)
    @test ret == 0
    #Gurobi._check_ret(a[], ret)
    if ret == 0
        #These testsets require Gurobi license.
        include("files/smcs_nonthreaded.jl")
        include("files/smcs_threaded.jl")
        include("files/smcs_additionals.jl")
        include("files/ELCC.jl")
        include("files/ETC.jl")
    end
end
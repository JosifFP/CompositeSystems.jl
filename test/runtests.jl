using CompositeSystems
using Test
import PowerModels, Ipopt, JuMP, Dates
import JuMP: JuMP, optimizer_with_attributes, termination_status
import Gurobi, Juniper, Ipopt

include("solvers.jl")
include("common.jl")

@testset verbose=true "Testset of OPF formulations + Load Curtailment minimization, using Juniper solver" begin
    BaseModule.silence()
    include("SystemModel.jl")
    include("opf_formulations.jl")
    include("load_minimization_dcp.jl")
    include("load_minimization_dcmp.jl")
    include("load_minimization_lpacc.jl")
    include("storage_model.jl")
end;

@testset verbose=true "Test sequential Monte Carlo Simulations using Gurobi License" begin
    @info "These testsets require Gurobi license."
    BaseModule.silence()
    a = Ref{Ptr{Cvoid}}()
    ret = Gurobi.GRBloadenv(a, C_NULL)
    #Gurobi._check_ret(a[], ret)
    if ret == 0
        @test ret == 0
        #These testsets require Gurobi license.
        include("smcs_nonthreaded.jl")
        include("smcs_threaded.jl")
        include("smcs_additionals.jl")
        include("ELCC.jl")
        include("ETC.jl")
    end
end;
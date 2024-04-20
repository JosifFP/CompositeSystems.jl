import Distributed
#This test should be the last one. After finished, close restart terminal.
addprocs(2)
#julia -p 2 --threads 2
@everywhere begin
    using Pkg; Pkg.activate(joinpath("..\\PRATS.jl"))
end

Pkg.instantiate()
Pkg.precompile()

@everywhere begin
    Pkg.instantiate(); Pkg.precompile()
end

# instantiate and precompile environment in all processes
@everywhere using Gurobi
@everywhere using Dates
@everywhere using JuMP
@everywhere using CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy

@testset begin
    @test isapprox(nthreads(), 2)
    @test isapprox(nworkers(), 2)
end

@testset "Test current number of workers" begin
    @test isapprox(Distributed.nprocs(), 1)
    @test isapprox(Distributed.nworkers(), 1)
    println("Number of workers is $(Distributed.nworkers()). Close current Julia REPL to return to default configuration.") 
end

settings = CompositeSystems.Settings(;
   optimizer = gurobi_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.DCMPPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = true
)

@testset "Sequential MCS, 10 samples, RBTS, distributed" begin

    sys = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
    method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true)
    resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
    Shortfall, util = CompositeSystems.assess(sys, method, settings, resultspecs...)
    sys_EENS_mean = [0.0, 0.0, 28.823827, 0.0, 0.0, 79.665336]
    sys_EDLC_mean = [0.0, 0.0, 1.7, 0.0, 0.0, 6.6]
    sys_SI_mean = [0.0, 0.0, 9.348267, 0.0, 0.0, 25.837404]
    sys_EENS_stderror = [0.0, 0.0, 28.154107, 0.0, 0.0, 44.054396]
    sys_EDLC_stderror = [0.0, 0.0, 1.491085, 0.0, 0.0, 3.818668]
    sys_SI_stderror = [0.0, 0.0, 9.131061, 0.0, 0.0, 14.287911]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(Shortfall, sys.buses.keys)), 
        sys_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(Shortfall, sys.buses.keys)), 
        sys_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(Shortfall, sys.buses.keys)), 
        sys_SI_mean; atol = 1e-4)

    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EDLC.(Shortfall, sys.buses.keys)), 
        sys_EDLC_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EENS.(Shortfall, sys.buses.keys)), 
        sys_EENS_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(Shortfall, sys.buses.keys)), 
        sys_SI_stderror; atol = 1e-4)

end

@testset "Sequential MCS, 100 samples, RTS, distributed" begin

    sys = BaseModule.SystemModel(rawfile_rts, relfile_rts, tseriesfile_rts)
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true)
    resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
    Shortfall, util = CompositeSystems.assess(sys, method, settings, resultspecs...)

    sys_EENS_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 363.005903, 0.0, 551.424678, 0.0, 0.0, 0.0, 0.0, 28.25952, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.1, 0.0, 7.7, 0.0, 0.0, 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_SI_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 7.642229, 0.0, 11.60894, 0.0, 0.0, 0.0, 0.0, 0.594937, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_EENS_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 204.927776, 0.0, 222.691654, 0.0, 0.0, 0.0, 0.0, 16.672288, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_EDLC_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.340228, 0.0, 2.932765, 0.0, 0.0, 0.0, 0.0, 0.366667, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.314269, 0.0, 4.688245, 0.0, 0.0, 0.0, 0.0, 0.350996, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]   

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(Shortfall, sys.buses.keys)), 
        sys_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(Shortfall, sys.buses.keys)), 
        sys_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(Shortfall, sys.buses.keys)), 
        sys_SI_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(Shortfall, sys.buses.keys)), 
        sys_SI_stderror; atol = 1e-4)
end
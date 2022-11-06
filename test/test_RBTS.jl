include("solvers.jl")
using PRATS
import PRATS.PRATSBase
import PRATS.CompositeAdequacy: CompositeAdequacy, field, var,
assetgrouplist, findfirstunique, topology, sol, cache, makeidxlist,
build_sol_values, optimizer_with_attributes
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
using Test
using ProfileView, Profile
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
PRATSBase.silence()

#system = PRATSBase.SystemModel(RawFile)
system = PRATSBase.SystemModel(RawFile; ReliabilityDataDir=ReliabilityDataDir, N=8736)
field(system, :loads, :cost)[:] = 
[8981.5; 7360.6; 5899; 9599.2; 9232.3; 6523.8; 7029.1; 
7774.2; 3662.3; 5194; 7281.3; 4371.7; 5974.4; 7230.5; 5614.9; 4543; 5683.6]

settings = PRATS.Settings(
    ipopt_optimizer_3, 
    modelmode = JuMP.AUTOMATIC,
    powermodel = AbstractDCMPPModel
)

method = PRATS.SequentialMCS(samples=1, seed=1, threaded=false)
pm = CompositeAdequacy.PowerFlowProblem(system, method, settings)
t=1
rng = CompositeAdequacy.Philox4x((0, 0), 10)
systemstates = SystemStates(system, method)
systemstates.branches

CompositeAdequacy.initialize!(rng, systemstates, system)
systemstates.system
sum(systemstates.system)



field(systemstates, :branches)[3,t] = 0
field(systemstates, :branches)[4,t] = 0
field(systemstates, :branches)[8,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, systemstates, system, t)
CompositeAdequacy.solve!(pm, system, t)

topology(pm, :buses_idxs)
topology(pm, :loads_idxs)
topology(pm, :branches_idxs)
topology(pm, :loads_nodes)
topology(pm, :arcs, :arcs)
topology(pm, :arcs, :arcs_from)
topology(pm, :arcs, :arcs_to)
topology(pm, :arcs, :busarcs)

topology(pm, :arcs, :busarcs)[:,9]

sol(pm, :plc)


pm.model
JuMP.termination_status(pm.model)


systemstates = SystemStates(system, method)
field(systemstates, :branches)[3,t] = 0
field(systemstates, :branches)[4,t] = 0
field(systemstates, :branches)[8,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, systemstates, system, t)
CompositeAdequacy.solve!(pm, system, t)
JuMP.termination_status(pm.model)
println(pm.topology.plc)
pg = sum(values(build_sol_values(var(pm, :pg, t))))
JuMP.empty!(pm.model)



@testset "test 5 Split situations RBTS system" begin

    RawFile = "test/data/RBTS.m"
    nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
    optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])
    
    system = PRATSBase.SystemModel(RawFile)
    field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    method = PRATS.SequentialMCS(samples=1, seed=1, threaded=false)
    topology = CompositeAdequacy.Topology(system)
    pm = CompositeAdequacy.PowerFlowProblem(system, method, settings, topology)
    t=1

    @testset "L3, L4 and L8 on outage" begin
        systemstates = SystemStates(system, method)
        field(systemstates, :branches)[3,t] = 0
        field(systemstates, :branches)[4,t] = 0
        field(systemstates, :branches)[8,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:]), 0.1503; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0.1503; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0; atol = 1e-3)
        pg = sum(values(CompositeAdequacy.build_sol_values(CompositeAdequacy.var(pm, :pg, 0))))
        @test isapprox(pg, 1.699; atol = 1e-3)
        JuMP.empty!(pm.model)
    end

    @testset "G3, G7, G8 and G9 on outage" begin
        systemstates = SystemStates(system, method)
        field(systemstates, :generators)[3,t] = 0
        field(systemstates, :generators)[7,t] = 0
        field(systemstates, :generators)[8,t] = 0
        field(systemstates, :generators)[9,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:]), 0.35; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0.35; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0; atol = 1e-3)
        #pg = sum(values(CompositeAdequacy.build_sol_values(CompositeAdequacy.var(pm, :pg, 0))))
        @test isapprox(pg, 1.5; atol = 1e-3)
        JuMP.empty!(pm.model)
    end

end

































system.branches.keys
assetgrouplist(pm.topology.buses_idxs)
assetgrouplist(pm.topology.loads_idxs)
assetgrouplist(pm.topology.branches_idxs)
assetgrouplist(pm.topology.shunts_idxs)
assetgrouplist(pm.topology.generators_idxs)
assetgrouplist(pm.topology.storages_idxs)
assetgrouplist(pm.topology.generatorstorages_idxs)

pm.topology.loads_nodes
pm.topology.shunts_nodes
pm.topology.generators_nodes
pm.topology.storages_nodes
pm.topology.generatorstorages_nodes
pm.topology.bus_arcs
pm.topology.buspairs


termination_status(pm.model)

plc = build_sol_values(var(pm, :plc, 1))


t=2
field(systemstates, :branches)[5,t] = 0
field(systemstates, :branches)[8,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, systemstates, system, t)
CompositeAdequacy.build_method!(pm, system, t)
CompositeAdequacy.optimize!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
pm.topology.plc
pm.var.va




Base.map(x -> [], values(tmp))
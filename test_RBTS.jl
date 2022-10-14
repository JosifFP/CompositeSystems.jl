using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
PRATSBase.silence()

ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RBTS.m"
system = PRATSBase.SystemModel(RawFile; ReliabilityDataDir=ReliabilityDataDir, N=8736)
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])

ref = PRATSBase.BuildNetwork(RawFile)
for (k,v) in ref[:load]
    CompositeAdequacy.field(system, Loads, :pd)[k,1] = v["pd"]
end

t=1
pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCPowerModel, JuMP.Model(optimizer; add_bridges = false), CompositeAdequacy.Topology(system))
systemstate = CompositeAdequacy.SystemState(system)
CompositeAdequacy.update!(pm.topology, systemstate, system, t)
CompositeAdequacy.solve!(pm, systemstate, system, t)

pm.topology.plc[:,1]
CompositeAdequacy.sol(pm, :plc)

for r in system.loads.keys
    pm.topology.plc[r,1] = CompositeAdequacy.sol(pm, :plc)[r]
end

@testset "L5 and L8 on outage" begin
    pm = CompositeAdequacy.PowerFlowProblem(
        CompositeAdequacy.AbstractDCPowerModel, JuMP.Model(
        optimizer; add_bridges = false), CompositeAdequacy.Topology(system))
    systemstate = CompositeAdequacy.SystemState(system)
    CompositeAdequacy.field(systemstate, :branches)[5,t] = 0
    CompositeAdequacy.field(systemstate, :branches)[8,t] = 0
    CompositeAdequacy.field(systemstate, :condition)[t] = 0
    CompositeAdequacy.update!(pm.topology, systemstate, system, t)
    CompositeAdequacy.solve!(pm, systemstate, system, t)
    @test isapprox(sum(values(pm.sol[:plc])), 0.4; atol = 1e-4)
    CompositeAdequacy.empty_model!(pm)
end

@testset "L3, L4 and L8 on outage" begin
    pm = CompositeAdequacy.PowerFlowProblem(
        CompositeAdequacy.AbstractDCPowerModel, JuMP.Model(
        optimizer; add_bridges = false), CompositeAdequacy.Topology(system))
    systemstate = CompositeAdequacy.SystemState(system)
    CompositeAdequacy.field(systemstate, :branches)[3,t] = 0
    CompositeAdequacy.field(systemstate, :branches)[4,t] = 0
    CompositeAdequacy.field(systemstate, :branches)[8,t] = 0
    CompositeAdequacy.field(systemstate, :condition)[t] = 0
    CompositeAdequacy.update!(pm.topology, systemstate, system, t)
    CompositeAdequacy.solve!(pm, systemstate, system, t)
    @test isapprox(sum(values(pm.sol[:plc])), 0.1503; atol = 1e-4)
    CompositeAdequacy.empty_model!(pm)
end

@testset "G3, 7, 8 and 11 on outage" begin
    pm = CompositeAdequacy.PowerFlowProblem(
        CompositeAdequacy.AbstractDCPowerModel, JuMP.Model(
        optimizer; add_bridges = false), CompositeAdequacy.Topology(system))
    systemstate = CompositeAdequacy.SystemState(system)
    CompositeAdequacy.field(systemstate, :generators)[3] = 0
    CompositeAdequacy.field(systemstate, :generators)[7] = 0
    CompositeAdequacy.field(systemstate, :generators)[8] = 0
    CompositeAdequacy.field(systemstate, :generators)[11] = 0
    CompositeAdequacy.field(systemstate, :condition)[t] = 0
    CompositeAdequacy.update!(pm.topology, systemstate, system, t)
    CompositeAdequacy.solve!(pm, systemstate, system, t)
    @test isapprox(sum(values(pm.sol[:plc])), 0.35; atol = 1e-4)
    CompositeAdequacy.empty_model!(pm)
end

@testset "L2 and L7 on outage, generation reduced" begin
    pm = CompositeAdequacy.PowerFlowProblem(
        CompositeAdequacy.AbstractDCPowerModel, JuMP.Model(
        optimizer; add_bridges = false), CompositeAdequacy.Topology(system)
    )
        systemstate = CompositeAdequacy.SystemState(system)
    CompositeAdequacy.field(systemstate, :branches)[2] = 0
    CompositeAdequacy.field(systemstate, :branches)[7] = 0
    CompositeAdequacy.field(systemstate, :generators)[1] = 0
    CompositeAdequacy.field(systemstate, :generators)[2] = 0
    CompositeAdequacy.field(systemstate, :generators)[3] = 0
    CompositeAdequacy.field(systemstate, :condition)[t] = 0
    CompositeAdequacy.update!(pm.topology, systemstate, system, t)
    CompositeAdequacy.solve!(pm, systemstate, system, t)
    @test isapprox(sum(values(pm.sol[:plc])), 0.7046; atol = 1e-4)
    CompositeAdequacy.empty_model!(pm)
end
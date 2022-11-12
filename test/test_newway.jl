using PRATS, PRATS.OPF, PRATS.BaseModule
using PRATS.OPF
using PRATS.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using Test
include("solvers.jl")

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    ipopt_optimizer_3,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)


@testset "L5 and L8 on outage" begin
    RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/RBTS.m"
    ReliabilityFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/R_RBTS.m"
    system = BaseModule.SystemModel(RawFile, ReliabilityFile)
    PRATS.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    topology = CompositeAdequacy.Topology(system)
    pm = CompositeAdequacy.Initialize_model(system, topology, settings)
    t=1
    systemstates = OPF.SystemStates(system, available=true)
    PRATS.field(systemstates, :branches)[5,t] = 0
    PRATS.field(systemstates, :branches)[8,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm.topology, systemstates, system, t)
    CompositeAdequacy.solve!(pm, system, systemstates, t)
    @test isapprox(sum(values(OPF.sol(pm, :plc))[:]), 0.4; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[1,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[2,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[3,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[4,t], 0.2; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[5,t], 0.2; atol = 1e-3)
    @show @test JuMP.termination_status(pm.model) != JuMP.NUMERICAL_ERROR
    CompositeAdequacy.empty_model!(system, pm, settings)
    
end

@testset "L3, L4 and L8 on outage" begin
    RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/RBTS.m"
    ReliabilityFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/R_RBTS.m"
    system = BaseModule.SystemModel(RawFile, ReliabilityFile)
    PRATS.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    topology = CompositeAdequacy.Topology(system)
    pm = CompositeAdequacy.Initialize_model(system, topology, settings)
    t=1
    systemstates = OPF.SystemStates(system, available=true)
    PRATS.field(systemstates, :branches)[3,t] = 0
    PRATS.field(systemstates, :branches)[4,t] = 0
    PRATS.field(systemstates, :branches)[8,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.solve!(pm, system, systemstates, t)
    @test isapprox(sum(values(OPF.sol(pm, :plc))[:]), 0.1503; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[1,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[2,t], 0.1503; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[3,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[4,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[5,t], 0; atol = 1e-3)
    pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
    @test isapprox(pg, 1.699; atol = 1e-3)
    @show @test JuMP.termination_status(pm.model) != JuMP.NUMERICAL_ERROR
    CompositeAdequacy.empty_model!(system, pm, settings)
end


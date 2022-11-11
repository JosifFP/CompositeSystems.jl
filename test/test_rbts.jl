using PRATS, PRATS.OPF, PRATS.BaseModule
using PRATS.OPF
using PRATS.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
include("solvers.jl")
TimeSeriesFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/Loads.xlsx"
RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/RBTS.m"
ReliabilityFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/R_RBTS.m"

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    ipopt_optimizer_3,
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)

timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)
system = SystemModel(RawFile, ReliabilityFile, timeseries_load, SParametrics)
method = SequentialMCS(samples=1, seed=1, threaded=false)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)



using JuMP
x = JuMP.all_variables(pm.model)
x_solution = JuMP.value.(x)
@show JuMP.set_start_value.(x, x_solution)


import PowerModels
PowerModels.silence()
data = PowerModels.parse_file(RawFile)
@time for i in 1:8736
    result = PowerModels.solve_dc_opf(data, ipopt_optimizer_3)
end
JuMP.optimize!(pm.model) 
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)


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
@show pm.topology.arcs.buspairs

using Ipopt
IpoptNLSolver()



using Test
@testset "G3, G7, G8 and G9 on outage" begin
    RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/RBTS.m"
    ReliabilityFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/R_RBTS.m"
    system = BaseModule.SystemModel(RawFile, ReliabilityFile)

    PRATS.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    topology = CompositeAdequacy.Topology(system)
    pm = CompositeAdequacy.Initialize_model(system, topology, settings)
    t=1
    systemstates = OPF.SystemStates(system, available=true)
    PRATS.field(systemstates, :generators)[3,t] = 0
    PRATS.field(systemstates, :generators)[7,t] = 0
    PRATS.field(systemstates, :generators)[8,t] = 0
    PRATS.field(systemstates, :generators)[9,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm.topology, systemstates, system, t)
    CompositeAdequacy.solve!(pm, system, t)
    @test isapprox(sum(values(OPF.sol(pm, :plc))[:]), 0.35; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[1,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[2,t], 0.35; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[3,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[4,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[5,t], 0; atol = 1e-3)
    pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
    @test isapprox(pg, 1.5; atol = 1e-3)
    CompositeAdequacy.empty_model!(system, pm, settings)
    

    systemstates = OPF.SystemStates(system, available=true)
    PRATS.field(systemstates, :branches)[3,t] = 0
    PRATS.field(systemstates, :branches)[4,t] = 0
    PRATS.field(systemstates, :branches)[8,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm.topology, systemstates, system, t)
    CompositeAdequacy.solve!(pm, system, t)
    @test isapprox(sum(values(OPF.sol(pm, :plc))[:]), 0.1503; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[1,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[2,t], 0.1503; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[3,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[4,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[5,t], 0; atol = 1e-3)
    pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
    @test isapprox(pg, 1.699; atol = 1e-3)
    CompositeAdequacy.empty_model!(system, pm, settings)
    

    systemstates = OPF.SystemStates(system, available=true)
    PRATS.field(systemstates, :branches)[2,t] = 0
    PRATS.field(systemstates, :branches)[7,t] = 0
    PRATS.field(systemstates, :generators)[1,t] = 0
    PRATS.field(systemstates, :generators)[2,t] = 0
    PRATS.field(systemstates, :generators)[3,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm.topology, systemstates, system, t)
    CompositeAdequacy.solve!(pm, system, t)
    @test isapprox(sum(values(OPF.sol(pm, :plc))[:]), 0.7046; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[1,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[2,t], 0.7046; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[3,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[4,t], 0; atol = 1e-3)
    @test isapprox(values(OPF.sol(pm, :plc))[5,t], 0; atol = 1e-3)
    CompositeAdequacy.empty_model!(system, pm, settings)
    
end

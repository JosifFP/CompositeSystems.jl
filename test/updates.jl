using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")

settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
#settings = CompositeSystems.Settings(ipopt_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
rawfile = "test/data/RBTS/Base/RBTS_AC.m"
reliabilityfile = "test/data/RBTS/Base/R_RBTS_FULL.m"
timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
model = OPF.jump_model(JuMP.AUTOMATIC, deepcopy(settings.optimizer), string_names = true)
pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)
systemstates = OPF.SystemStates(system, available=true)
CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
println(pm.model)
pm.model

t=2
OPF._update!(pm, system, systemstates, t)  
println(pm.model)
pm.model

@testset "No outages" begin
    @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
    @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9109; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.3841; atol = 1e-4)
    @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
end




using Plots
a = systemstates.branches[10,:]
b = systemstates.branches[12,:]
plot(1:8736, a)
plot(1:8736, b)


system.branches.t_bus[10]
system.branches.f_bus[10]

system.branches.t_bus[11]
system.branches.f_bus[11]

system.branches.λ_updn[11]
system.branches.μ_updn[11]

system.branches.λ_updn[10]
system.branches.μ_updn[10]


t=7
CompositeSystems.field(systemstates, :branches)[2,t] = 0
CompositeSystems.field(systemstates, :branches)[7,t] = 0
CompositeSystems.field(systemstates, :generators)[1,t] = 0
CompositeSystems.field(systemstates, :generators)[2,t] = 0
CompositeSystems.field(systemstates, :generators)[3,t] = 0
systemstates.system[t] = 0
OPF._update!(pm, system, systemstates, t)   

result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

systemstates.branches[:,t]
systemstates.generators[:,t]
systemstates.loads[:,t]

pm.topology.buspairs


println(pm.model)
#hello

JuMP.termination_status(pm.model)






















JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))
data = OPF.build_network(rawfile, symbol=false)
data["branch"]["1"]["br_status"] = 0
data["branch"]["8"]["br_status"] = 0
data["branch"]["10"]["br_status"] = 0
data["shunt"]["1"]["status"] = 0
PowerModels.simplify_network!(data)
result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_opf)
pm.model
pmi.model
println(pm.model)
println(pmi.model)
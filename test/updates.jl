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
timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile = "test/data/SMCS/RTS_79_A/RTS_DC.m"
Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
model = OPF.jump_model(JuMP.AUTOMATIC, deepcopy(settings.optimizer), string_names = true)
pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)
systemstates = OPF.SystemStates(system, available=true)
CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
rng = CompositeAdequacy.Philox4x((0, 0), 9)
CompositeAdequacy.initialize_states!(rng, systemstates, system)
system.branches.λ_updn
system.branches.μ_updn
systemstates.commonbranches

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
using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")

rawfile = "test/data/RTS/Base/RTS.m"
system = BaseModule.SystemModel(rawfile)
states = CompositeAdequacy.SystemStates(system, available=true)



pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)


active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
changed = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) != false]


OPF._update_opf!(pm, system, states, 1)
println(pm.model)


result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
data = OPF.build_network(rawfile, symbol=false)
data["branch"]["1"]["br_status"] = 0
result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
pmi = PowerModels.instantiate_model(data, PowerModels.DCPPowerModel, PowerModels.build_opf)
pmi.model
println(pmi.model)




println(pm.model)





JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)















JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)

systemstates.plc
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))







data = OPF.build_network(rawfile, symbol=false)
data["branch"]["5"]["br_status"] = 0
data["branch"]["8"]["br_status"] = 0
data["load"]["5"]["status"] = 0
data["load"]["4"]["status"] = 0
PowerModels.simplify_network!(data)
result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_opf)
pmi.model
println(pmi.model)
result["solution"]["gen"]

pmi.ref[:it][:pm][:nw][0][:bus]








CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
pm.model
println(pm.model)

t=2
CompositeSystems.field(systemstates, :branches)[5,t] = 0
CompositeSystems.field(systemstates, :branches)[8,t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
systemstates.plc[:]
pm.model
println(pm.model)

@test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9109; atol = 1e-4)
@test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.3841; atol = 1e-4)





data = OPF.build_network(rawfile, symbol=false)
data["branch"]["1"]["br_status"] = 0
data["branch"]["6"]["br_status"] = 0
pmi = PowerModels.instantiate_model(data, PowerModels.DCPPowerModel, PowerModels.build_opf)
pm.model
pmi.model
println(pm.model)
println(pmi.model)



using Plots
a = systemstates.branches[10,:]
b = systemstates.branches[12,:]
plot(1:8736, a)
plot(1:8736, b)

JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_opf)
pm.model
pmi.model
println(pm.model)
println(pmi.model)
using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile
using Test

include("solvers.jl")


rawfile = "test/data/RBTS/Base/RBTS_AC.m"
system = BaseModule.SystemModel(rawfile)
settings = CompositeSystems.Settings(juniper_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
states = CompositeAdequacy.SystemStates(system, available=true)

@btime length(field(states, :generators))
@btime length(view(field(states, :generators), :, 2-1))

pm = OPF.solve_opf(system, settings)
pm = OPF.abstract_model(system, settings)
OPF.build_opf!(pm, system)

OPF.var(pm, :cs, 1)


















rawfile = "test/data/RTS/Base/RTS.m"
data = OPF.build_network(rawfile, symbol=false)
result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_1)

result["solution"]
result_pg_powermodels = 0
result_qg_powermodels = 0

for i in eachindex(result["solution"]["gen"])
    result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
    result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
end
result_pg_powermodels
result_qg_powermodels

rawfile = "test/data/RTS/Base/RTS.m"
data = OPF.build_network(rawfile, symbol=false)
result = PowerModels.solve_ots(data, PowerModels.DCPPowerModel, juniper_optimizer_1)
result["solution"]
result_pg_powermodels = 0
result_qg_powermodels = 0
for i in eachindex(result["solution"]["gen"])
    result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
    result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
end
result_pg_powermodels
result_qg_powermodels




data = PowerModels.parse_file(rawfile)
off_angmin, off_angmax = PowerModels.calc_theta_delta_bounds(data)
data["off_angmin"], data["off_angmax"] = off_angmin, off_angmax
pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_ots)
pmi.model
println(pmi.model)




println(pm.model)
data = OPF.build_network(rawfile, symbol=false)
data["branch"]["1"]["br_status"] = 0
result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_opf)
pmi.model
println(pmi.model)


pm.topology.arcs
pm.topology.buspairs
pm.topology.buses_idxs
pm.topology.loads_idxs
pm.topology.branches_idxs
pm.topology.shunts_idxs
pm.topology.generators_idxs
pm.topology.storages_idxs
pm.topology.generatorstorages_idxs
pm.topology.bus_loads_init
pm.topology.bus_loads
pm.topology.bus_shunts
pm.topology.bus_generators
pm.topology.bus_storages
pm.topology.bus_generatorstorages
pm.topology.arcs_from
pm.topology.arcs_to
pm.topology.arcs
pm.topology.busarcs
pm.topology.isolated_bus_gens



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


using Plots
a = systemstates.branches[10,:]
b = systemstates.branches[12,:]
plot(1:8736, a)
plot(1:8736, b)

JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_opf)
pm.model
pmi.model
println(pm.model)
println(pmi.model)
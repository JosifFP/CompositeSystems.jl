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
settings = CompositeSystems.Settings(
    juniper_optimizer_2;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = true,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = true
)
states = CompositeAdequacy.SystemStates(system, available=true)
pm = OPF.solve_opf(system, settings)

states.branches[1] = 0
OPF._update_opf!(pm, system, states, settings, 1)
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_values(pm, system.branches)
println(pm.model)



data = OPF.build_network(rawfile, symbol=false)
data["branch"]["1"]["br_status"] = 0
result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
pmi = PowerModels.instantiate_model(data, PowerModels.DCPPowerModel, PowerModels.build_opf)
println(pmi.model)
















data = OPF.build_network(rawfile, symbol=false)
result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_opf)
println(pmi.model)




pmi.ref[:it][:pm][:nw][0]
PowerModels.ref_add_on_off_va_bounds!(pmi.ref, data)
data = OPF.build_network(rawfile, symbol=false)
pmi = PowerModels.instantiate_model(
    rawfile, PowerModels.LPACCPowerModel, PowerModels.build_ots; ref_extensions=[PowerModels.ref_add_on_off_va_bounds!]
)
pmi.ref[:it][:pm][:nw][0][:off_angmin]
pmi.ref[:it][:pm][:nw][0][:branch][5]["angmin"]
result = PowerModels.run_ots(rawfile, PowerModels.LPACCPowerModel, juniper_optimizer_2)


println(pm.model)
pm.model
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
sum(values(result_pg))
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)

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
pm.topology.select_largest_splitnetwork

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
pmi.model
println(pm.model)
println(pmi.model)
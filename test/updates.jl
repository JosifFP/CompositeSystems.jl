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
settings = CompositeSystems.Settings(
    gurobi_optimizer_2;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = true,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = true
)

settings_2 = CompositeSystems.Settings(
    gurobi_optimizer_2;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = true
)

rawfile = "test/data/RBTS/Base/RBTS_AC.m"
reliabilityfile = "test/data/RBTS/Base/R_RBTS_FULL.m"
system = BaseModule.SystemModel(rawfile, reliabilityfile)
CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
pm = OPF.abstract_model(system, settings)
systemstates = OPF.SystemStates(system, available=true)
CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)


t=1
systemstates = OPF.SystemStates(system, available=true)
CompositeSystems.field(systemstates, :branches)[3,t] = 0
CompositeSystems.field(systemstates, :branches)[4,t] = 0
CompositeSystems.field(systemstates, :branches)[8,t] = 0
OPF._update!(pm, system, systemstates, settings, t)
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
sum(values(result_pg))
println(pm.model)


t=1
systemstates = OPF.SystemStates(system, available=true)
CompositeSystems.field(systemstates, :branches)[3,t] = 0
CompositeSystems.field(systemstates, :branches)[4,t] = 0
CompositeSystems.field(systemstates, :branches)[8,t] = 0
OPF._update!(pm, system, systemstates, settings_2, t)
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
sum(values(result_pg))
println(pm.model)

sum(@view(systemstates.generators[:,t]))
length(system.generators)

sum(@view(systemstates.generators[:,t])) < length(generators)









pm.topology.arcs
pm.topology.buspairs
pm.topology.buses_idxs
pm.topology.loads_idxs
assetgrouplist(pm.topology.branches_idxs)
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





result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
sum(values(result_pg))




JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
sum(values(result_pg))
sum(system.loads.pd)







CompositeSystems.field(systemstates, :generators)[3,t] = 0
CompositeSystems.field(systemstates, :generators)[7,t] = 0
CompositeSystems.field(systemstates, :generators)[8,t] = 0
CompositeSystems.field(systemstates, :generators)[11,t] = 0
OPF._update!(pm, system, systemstates, settings, t)
@test isapprox(sum(systemstates.plc[:]), 0.35; atol = 1e-4)
@test isapprox(systemstates.plc[1], 0; atol = 1e-4)
@test isapprox(systemstates.plc[2], 0; atol = 1e-4)
@test isapprox(systemstates.plc[3], 0.35; atol = 1e-4)
@test isapprox(systemstates.plc[4], 0; atol = 1e-4)
@test isapprox(systemstates.plc[5], 0; atol = 1e-4)
@test isapprox(systemstates.plc[6], 0; atol = 1e-4)
@test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]); atol = 1e-4)
@test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
@test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE


system.generators.pmax[3] + system.generators.pmax[7] + system.generators.pmax[8] + system.generators.pmax[11]




JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)

result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
sum(values(result_pg))
sum(system.loads.pd)

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











result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))







@test isapprox(sum(systemstates.plc[:]), 0.750; atol = 1e-4)
@test isapprox(systemstates.plc[1], 0; atol = 1e-4)
@test isapprox(systemstates.plc[2], 0.2; atol = 1e-4)
@test isapprox(systemstates.plc[3], 0.150; atol = 1e-4)
@test isapprox(systemstates.plc[4], 0.4; atol = 1e-4)
@test isapprox(systemstates.plc[5], 0; atol = 1e-4)
@test isapprox(systemstates.plc[6], 0; atol = 1e-4)
@test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
@test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE















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
pm.topology.select_largest_splitnetwork



JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)

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
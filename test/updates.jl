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
    juniper_optimizer_1;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.LPACCPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    set_string_names_on_creation = true
)

timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"
resultspecs = (Shortfall(), GeneratorAvailability())
method = SequentialMCS(samples=15000, seed=100, threaded=false)
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
pm = OPF.abstract_model(system, settings)
systemstates = OPF.SystemStates(system)
recorders = accumulator.(system, method, resultspecs)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
s = 1
CompositeAdequacy.seed!(rng, (method.seed, s))  #using the same seed for entire period.

singlestates = CompositeAdequacy.NextTransition(system)
N = 8736
CompositeAdequacy.initialize_availability!(rng, singlestates.branches_available, singlestates.branches_nexttransition, system.branches, N)
CompositeAdequacy.initialize_availability!(rng, singlestates.commonbranches_available, singlestates.commonbranches_nexttransition, system.commonbranches, N)
CompositeAdequacy.initialize_availability!(rng, singlestates.generators_available, singlestates.generators_nexttransition, system.generators, N)
view(states.branches,:,1) .= singlestates.branches_available[:]
view(states.commonbranches,:,1) .= singlestates.commonbranches_available[:]
view(states.generators,:,1) .= singlestates.generators_available[:]







CompositeAdequacy.initialize_all_states!(rng, systemstates, singlestates, system)

for t in 1:N
    CompositeAdequacy.update_all_states!(rng, states, singlestates, system, t)
end
CompositeAdequacy.initialize_availability!(states.buses, field(system, :buses), N)
fill!(states.se, 0.0)
fill!(states.storages, 1.0)
fill!(states.shunts, 1.0)







CompositeAdequacy.initialize_states!(rng, systemstates, system)

topology(pm, :bus_storages)
nw = 1
t = 1

bus_loads = Dict{Int, Any}()
load_cost = Dict{Int, Any}()
se_left = Dict{Int, Any}()
for i in assetgrouplist(topology(pm, :buses_idxs))
    bus_loads[i] = sum((OPF.field(system, :loads, :cost)[k]*OPF.field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads)[i]); init=0)
    load_cost[i] = JuMP.@expression(pm.model, bus_loads[i]*(1 - var(pm, :z_demand, nw)[i]))
    se_left[i] = minimum(OPF.field(system, :loads, :cost))*sum((OPF.field(system, :storages, :energy_rating)[k] - var(pm, :se, nw)[k] for k in topology(pm, :bus_storages)[i]); init=0)
end


var(pm, :z_demand, nw)
bus_loads
load_cost
se_left
minimum(OPF.field(system, :loads, :cost))


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
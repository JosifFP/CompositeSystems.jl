using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
PRATSBase.silence()

RawFile = "test/data/RBTS.m"
system = PRATSBase.SystemModel(RawFile)
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])

CompositeAdequacy.empty_model!(pm,t)
pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCPowerModel, JuMP.Model(optimizer; add_bridges = false), CompositeAdequacy.Topology(system))
systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
t=1

CompositeAdequacy.field(systemstates, :branches)[7,t] = 0
CompositeAdequacy.field(systemstates, :branches)[23,t] = 0
CompositeAdequacy.field(systemstates, :branches)[29,t] = 0
#CompositeAdequacy.field(systemstates, :generators)[1,t] = 0
CompositeAdequacy.field(systemstates, :system)[t] = 0
CompositeAdequacy.update!(pm.topology, systemstates, system, t)




CompositeAdequacy.var_bus_voltage(pm, system, t)
CompositeAdequacy.var_gen_power(pm, system, t)
CompositeAdequacy.var_branch_power(pm, system, t)
CompositeAdequacy.var_load_curtailment(pm, system, t)
@show pm.model

for i in CompositeAdequacy.field(system, :ref_buses)
    CompositeAdequacy.constraint_theta_ref(pm, i)
end

for i in CompositeAdequacy.assetgrouplist(CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :buses_idxs))
    CompositeAdequacy.constraint_power_balance(pm, system, i, t)
end

for i in CompositeAdequacy.assetgrouplist(CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :branches_idxs))
    CompositeAdequacy.constraint_ohms_yt(pm, system, i, t)
    CompositeAdequacy.constraint_voltage_angle_diff(pm, system, i, t)
end

@show pm.model
CompositeAdequacy.objective_min_load_curtailment(pm, system)
JuMP.optimize!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
#CompositeAdequacy.solve!(pm, systemstates, system, t)
values(CompositeAdequacy.field(pm, :plc))[:,t]
sum(values(CompositeAdequacy.field(pm, :plc))[:,t])














pm.topology.loads_nodes
pm.topology.shunts_nodes
pm.topology.generators_nodes
pm.topology.storages_nodes
pm.topology.generatorstorages_nodes
pm.topology.bus_arcs


pm.topology.buses_idxs
pm.topology.branches_idxs
pm.topology.shunts_idxs
pm.topology.generators_idxs
pm.topology.storages_idxs
pm.topology.generatorstorages_idxs
CompositeAdequacy.assetgrouplist(CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :buses_idxs))
CompositeAdequacy.assetgrouplist(CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :generators_idxs))
CompositeAdequacy.assetgrouplist(CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :branches_idxs))
CompositeAdequacy.assetgrouplist(CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :loads_idxs))





active_bus = Dict(x for x in data["bus"] if x.second["bus_type"] != 4)
active_bus_ids = Set{Int}([bus["bus_i"] for (i,bus) in active_bus])

neighbors = Dict(i => Int[] for i in active_bus_ids)
for comp_type in edges
    status_key = get(pm_component_status, comp_type, "status")
    status_inactive = get(pm_component_status_inactive, comp_type, 0)
    for edge in values(get(data, comp_type, Dict()))
        if get(edge, status_key, 1) != status_inactive && edge["f_bus"] in active_bus_ids && edge["t_bus"] in active_bus_ids
            push!(neighbors[edge["f_bus"]], edge["t_bus"])
            push!(neighbors[edge["t_bus"]], edge["f_bus"])
        end
    end
end

component_lookup = Dict(i => Set{Int}([i]) for i in active_bus_ids)
touched = Set{Int}()

for i in active_bus_ids
    if !(i in touched)
        cc_dfs!(i, neighbors, component_lookup, touched)
    end
end
ccs = (Set(values(component_lookup)))



incident_active_edge = 0
for i in system.buses.keys
    if system.buses.bus_type != 4
        if length(pm.topology.bus_arcs[i]) > 0
            println(i)
            incident_branch_count = sum([0; [CompositeAdequacy.field(systemstates, :branches)[l,t] for (l,i,j) in pm.topology.bus_arcs[i]]])
            incident_active_edge = incident_branch_count
        end

        if incident_active_edge == 1 && length(pm.topology.loads_nodes[i]) == 0 && length(pm.topology.loads_nodes[i]) == 0 && 
            println("deactivating bus $(i) due to dangling bus without generation, load or storage")
        end
    end
end





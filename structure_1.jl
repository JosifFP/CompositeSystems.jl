using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test, Dates
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 365)
systemstate = CompositeAdequacy.SystemState(system)
CompositeAdequacy.update_system!(systemstate, system, 1)

nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, 
    "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])

pm = CompositeAdequacy.BuildAbstractPowerModel!(CompositeAdequacy.DCPowerModel, JuMP.direct_model(optimizer))
CompositeAdequacy.var_bus_voltage(pm, system)
CompositeAdequacy.var_gen_power(pm, system)
CompositeAdequacy.var_branch_power(pm, system)
CompositeAdequacy.var_load_curtailment(pm, system)

bus_arcs = CompositeAdequacy.field(system, Topology, :bus_arcs)[1]
bus_gens = CompositeAdequacy.field(system, Topology, :bus_gens)[1]
bus_loads = CompositeAdequacy.field(system, Topology, :bus_loads)[1]
bus_shunts = CompositeAdequacy.field(system, Topology, :bus_shunts)[1]
bus_storage = CompositeAdequacy.field(system, Topology, :bus_storage)[1]
bus_pd = Dict(k => CompositeAdequacy.field(system, Loads, :pd)[k] for k in bus_loads)
bus_qd = Dict(k => CompositeAdequacy.field(system, Loads, :qd)[k] for k in bus_loads)
bus_gs = Dict(k => CompositeAdequacy.field(system, Shunts, :gs)[k] for k in bus_shunts)
bus_bs = Dict(k => CompositeAdequacy.field(system, Shunts, :bs)[k] for k in bus_shunts)

p    = get(CompositeAdequacy.var(pm),    :p, Dict()); CompositeAdequacy._check_var_keys(p, bus_arcs, "active power", "branch")
p_lc = get(CompositeAdequacy.var(pm), :p_lc, Dict()); CompositeAdequacy._check_var_keys(p, bus_loads, "active power", "loads")
pg   = get(CompositeAdequacy.var(pm),   :pg, Dict()); CompositeAdequacy._check_var_keys(pg, bus_gens, "active power", "generator")
ps   = get(CompositeAdequacy.var(pm),   :ps, Dict()); CompositeAdequacy._check_var_keys(ps, bus_storage, "active power", "storage")

sum(p[a] for a in bus_arcs)
sum(pg[g] for g in bus_gens)
sum(ps[s] for s in bus_storage)
sum(pd for pd in values(bus_pd))
sum(gs for gs in values(bus_gs))*1.0^2
sum(p_lc[m] for m in bus_loads)
bus_loads
p_lc

    cstr = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        #+ sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        #+ sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        #+ sum(p_lc[m] for m in bus_loads)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*1.0^2
    )






for i in CompositeAdequacy.field(system, Buses, :keys)
    CompositeAdequacy.constraint_power_balance(pm, system, i)
end

pm.model
println(pm.model)
JuMP.solution_summary(pm.model, verbose=true)

[i for i in system.buses.keys if system.buses.bus_type[i] ≠ 4]
[(l,i,j) for (l,i,j) in system.topology.arcs if system.branches.status[l] ≠ 0]
[(l,i,j) in ref(pm, :arcs)]


[i for i in CompositeAdequacy.field(system, Buses, :keys) if CompositeAdequacy.field(system, Buses, :bus_type)[i] ≠ 4]

# function obtaine(system::SystemModel, buses::Type{Buses}, subfield::Symbol) 
    
#     for i in field(system, Buses, :keys)
#         if field(system, Buses, :keys)[i] ≠ 4


#     return getfield(getfield(system, :buses), subfield)
# end

pm.model
empty!(pm.model)
"hello"



"***************************************************************************************************************************"
ref = PRATSBase.BuildNetwork(RawFile)
CompositeAdequacy.ref_add!(ref)
nbus = length(buses)
buslookup = Dict(n=>i for (i, n) in enumerate(system.generators.keys)) #bus_gens = getindex.(Ref(buslookup), system.generators.buses)
bus_gens_idxs = makeidxlist(generators.buses, nbus)

loads.status[1]=false
loadlookup = Dict(n=>i for (i, n) in enumerate(loads.keys) if loads.status[i]==true)

buslookup = Dict(n=>i for (i, n) in enumerate(buses.keys))

bus_keys = [i for i in loads.keys if loads.status[i] == true]

load_buses = getindex.(Ref(buslookup), bus_keys)
bus_order = sortperm(load_buses)
bus_loads_idxs = makeidxlist(load_buses[bus_order], nbus)

bus_nodes = 1:nbus
for (r, load_idxs) in zip(bus_nodes, bus_loads_idxs)
    #println(load_idxs)
    for i in load_idxs
        println(i)
    end
end

bus_nodes = 1:nbus
for (r, gen_idxs) in zip(bus_nodes, bus_gens_idxs)
    println(gen_idxs)
end


"***************************************************************************************************************************"


branches.f_bus
branches.t_bus
branch_frombus = getindex.(Ref(buses.keys), branches.f_bus)
branch_tobus  = getindex.(Ref(buses.keys), branches.t_bus)

branch_lookup = Dict((r1, r2) => i for (i, (r1, r2)) in enumerate(tuple.(branches.f_bus, branches.t_bus)))
branches_interfaces = getindex.(Ref(interface_lookup),tuple.(branches.f_bus, branches.t_bus))
#branches_interfaces = [v for v in values(interface_lookup)]
branch_order = sortperm(branches_interfaces)
nbranches = length(branches)
interface_line_idxs = makeidxlist(branches_interfaces[branch_order], 38)

for (i, line_idxs) in enumerate(interface_line_idxs)

   #println(line_idxs)
   for i in line_idxs
    println(i)
    end

end

branches.status[4] = false
[i for i in branches.keys if branches.status[i] == true]

branch_keys = [i for i in branches.keys if branches.status[i] == true]

branch_lookup = Dict((r1, r2) => i for (i, (r1, r2)) in enumerate(tuple.(branches.f_bus, branches.t_bus)) if branches.status[i] == true)
group = [tuple.(branches.f_bus[i], branches.t_bus[i]) for i in branches.keys if branches.status[i] == true]


branches_interfaces = getindex.(Ref(branch_lookup),group)
branch_order = sortperm(branches_interfaces)
branches_interfaces[branch_order]
interface_line_idxs = makeidxlist(branches_interfaces[branch_order], 38)

for (i, line_idxs) in enumerate(interface_line_idxs)

    #println(line_idxs)
    for i in line_idxs
     println(i)
     end
 
end


[filter(t -> t[1] in starts[i] && t[2] in valid[i], my_tuple) for i in eachindex(starts, valid)]



function makeidxlist(collectionidxs::Vector{Int}, n_collections::Int)

    n_assets = length(collectionidxs)

    idxlist = Vector{UnitRange{Int}}(undef, n_collections)
    active_collection = 1
    start_idx = 1
    a = 1

    while a <= n_assets
       if collectionidxs[a] > active_collection
            idxlist[active_collection] = start_idx:(a-1)       
            active_collection += 1
            start_idx = a
       else
           a += 1
       end
    end

    idxlist[active_collection] = start_idx:n_assets       
    active_collection += 1

    while active_collection <= n_collections
        idxlist[active_collection] = (n_assets+1):n_assets
        active_collection += 1
    end

    return idxlist

end

"***************************************************************************************************************************"


@assert ref_1[:bus_arcs] == ref_2[:bus_arcs]
@assert ref_1[:branch] == ref_2[:branch]
@assert ref_1[:areas] == ref_2[:areas]
@assert ref_1[:bus] == ref_2[:bus]
@assert ref_1[:gen] == ref_2[:gen]
@assert ref_1[:storage] == ref_2[:storage]
@assert ref_1[:switch] == ref_2[:switch]
@assert ref_1[:shunt] == ref_2[:shunt]
@assert ref_1[:load] == ref_2[:load]
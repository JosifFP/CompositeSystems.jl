using PRATS
using PRATS.PRATSBase
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test, Dates
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 365)

system.topology
system.branches
system.buses
system.loads
system.generators
system.storages
system.generatorstorages
system.shunts
system.timestamps



system.topology.bus_arcs
system.branches.status[1] = 0
system.branches.status[2] = 0

tmp_arcs_from = [(i,a,b) for (i,a,b) in system.topology.arcs_from if system.branches.status[i] == true]
tmp_arcs_to   = [(i,a,b) for (i,a,b) in system.topology.arcs_to if system.branches.status[i] == true]
tmp_arcs = [(i,a,b) for (i,a,b) in system.topology.arcs if system.branches.status[i] == true]


(bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage) = PRATSBase.bus_components(tmp_arcs, system.buses, system.loads, system.shunts, system.generators, system.storages)

bus_arcs


for k in system.buses.keys
    system.topology.bus_gens[k] = bus_gens[k]
    system.topology.bus_loads[k] = bus_loads[k]
    system.topology.bus_shunts[k] = bus_shunts[k]
    system.topology.bus_storage[k] = bus_storage[k]

    if system.topology.bus_arcs[k] ≠ bus_arcs[k]
        system.topology.bus_arcs[k] = bus_arcs[k]
    end

end


system.topology.buspairs


system.branches.status[1] = 0
system.branches.status[2] = 0

tmp_buspairs = PRATSBase.calculate_buspair_parameters(system.buses, system.branches)
system.topology.buspairs

for bp in keys(system.topology.buspairs)
    if haskey(tmp_buspairs, bp) ≠ true
        println(bp)
        empty!(system.topology.buspairs[bp])
    end
end

system.topology.ref_buses




ref = PRATSBase.BuildNetwork(RawFile)
CompositeAdequacy.ref_add!(ref)
@show keys(ref)
ref[:buspairs]

buspairs = PRATSBase.calculate_buspair_parameters(ref[:bus], ref[:branch])




a.keys
a.f_bus
a.t_bus
a.rate_a
a.rate_b
a.rate_c
a.r
a.x
a.b_fr
a.b_to
a.g_fr
a.g_to
a.shift
a.angmin
a.angmax
a.transformer
a.tap
a.source_id
a.status
a.λ
a.μ



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
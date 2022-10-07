using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test, Dates
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 365)

@btime topology = CompositeAdequacy.Topology(system)
pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCPowerModel, JuMP.direct_model(optimizer), CompositeAdequacy.Topology(system))
systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.initialize!(rng, systemstate, system)

pm.topology.buses_idxs


@btime CompositeAdequacy.makeidxlist([i for i in CompositeAdequacy.assetgrouplist(pm.topology.buses_idxs) if CompositeAdequacy.field(system, Buses, :bus_type)[i] != 4], 24)

@btime [i for i in CompositeAdequacy.assetgrouplist(pm.topology.buses_idxs) if CompositeAdequacy.field(system, Buses, :bus_type)[i] != 4]
@btime [i for i in CompositeAdequacy.field(system, Buses, :keys) if CompositeAdequacy.field(system, Buses, :bus_type)[i] != 4]

buses_idxs = makeidxlist(key_buses, nbuses)

tmp = Dict((i, Tuple{Int,Int,Int}[]) for i in CompositeAdequacy.field(system.buses, :keys))
for (l,i,j) in topology.arcs
    push!(tmp[i], (l,i,j))
end
bus_arcs = tmp
line_interfaces = getindex.(Ref(interface_lookup),tuple.(f_bus_branches, t_bus_branches))




assetgrouplist(interface_branch_idxs)

collect(interface_line_idxs[35])
collect(interface_line_idxs[36])
collect(interface_line_idxs[37])
collect(interface_line_idxs[38])
collect(interface_line_idxs[5])
collect(interface_line_idxs[6])
collect(interface_line_idxs[7])


gens_idxs = makeidxlist([i for i in system.generators.keys if system.generators.status[i] == 1], length(system.generators))

@btime first(system.generators.keys):last(system.generators.keys)
first(system.generators.keys):last(system.generators.keys)
indices_after(1:33, 22)

a = [i for i in 1:17 if CompositeAdequacy.field(system, Loads, :status)[i] == 1]
bus_loads = [CompositeAdequacy.field(system, Loads, :buses)[i] for i in key_loads if CompositeAdequacy.field(system, Loads, :status)[i] == 1]


key_buses = [i for i in CompositeAdequacy.field(system, Buses, :keys) if CompositeAdequacy.field(system, Buses, :bus_type)[i] != 4]
buses_idxs = makeidxlist(key_buses, length(system.buses))
assetgrouplist(buses_idxs)


loads_idxs = makeidxlist(a, 17)
assetgrouplist(loads_idxs)



idxlist = Vector{UnitRange{Int}}(undef, n_collections)



UnitRange{Int}[]
indices_after(lastset::UnitRange{Int}, setsize::Int) =
    last(lastset) .+ (1:setsize)

system.generators.keys
system.generators.status[1] = 0
bus_gens_keys = [i for i in system.generators.buses if system.generators.status[i] == true]
bus_gens_idxs = makeidxlist([system.generators.buses[i] for i in system.generators.keys if system.generators.status[i] == 1], 24)
assetgrouplist(bus_gens_idxs)

[i for i in system.generators.keys if i in assetgrouplist(bus_gens_idxs)]

collect(bus_gens_idxs[1])
collect(bus_gens_idxs[2])
collect(bus_gens_idxs[3])

bus_nodes = 1:24
for (r, gens_idxs) in zip(2:33, bus_gens_idxs)
    println(r)
    # for i in gens_idxs
    #     println(gens_idxs)
    # end
end


@btime tmp_arcs = [(l,i,j) for (l,i,j) in [topology.arcs_from;topology.arcs_to] if CompositeAdequacy.field(system, Branches, :status)[l] ≠ 0]
@btime tmp_arcs = [(l,i,j) for (l,i,j) in topology.arcs if CompositeAdequacy.field(system, Branches, :status)[l] ≠ 0]

@btime tmp_arcs_from = [(l,i,j) for (l,i,j) in topology.arcs_from if  CompositeAdequacy.field(system, Branches, :status)[l] ≠ 0]

assetgrouplist(bus_gens_idxs)
bus_gens = CompositeAdequacy.field(topology, :bus_gens)

for (r, gen_idxs) in zip(1:24, bus_gens_idxs)
    println(r)
end
assetgrouplist(bus_gens_idxs)
@btime collect(bus_gens_idxs[1])
collect(bus_gens_idxs[2])
collect(bus_gens_idxs[3])
collect(bus_gens_idxs[4])
collect(bus_gens_idxs[5])
collect(bus_gens_idxs[6])
collect(bus_gens_idxs[7])







tmp = Dict((i, Tuple{Int,Int,Int}[]) for i in field(buses, :keys))
for (l,i,j) in arcs
    push!(tmp[i], (l,i,j))
end
bus_arcs = tmp




resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMonteCarlo(samples=4, seed=123, verbose=false, threaded=true)
@time shortfall,report = PRATS.assess(system, method, resultspecs...)

model = JuMP.direct_model(optimizer)


@time shortfall,report = PRATS.assess(system, method, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)


shortfall.nsamples
shortfall.loads
shortfall.timestamps
shortfall.eventperiod_mean
shortfall.eventperiod_std
shortfall.eventperiod_bus_mean
shortfall.eventperiod_bus_std
shortfall.eventperiod_period_mean
shortfall.eventperiod_period_std
shortfall.eventperiod_busperiod_mean
shortfall.eventperiod_busperiod_std
shortfall.shortfall_mean
shortfall.shortfall_std
shortfall.shortfall_bus_std
shortfall.shortfall_period_std
shortfall.shortfall_busperiod_std



ref = PRATSBase.BuildNetwork(RawFile)
for (k,v) in ref[:load]
    CompositeAdequacy.field(system, Loads, :pd)[k,1] = v["pd"]
end
t=2
CompositeAdequacy.field(system, Branches, :status)[25] = 0
CompositeAdequacy.field(system, Branches, :status)[26] = 0
CompositeAdequacy.field(system, Branches, :status)[28] = 0
CompositeAdequacy.update!(system)

@show CompositeAdequacy.field(system, Branches, :status)

CompositeAdequacy.build_method!(pm, system, t, CompositeAdequacy.DCOPF)
JuMP.optimize!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
CompositeAdequacy.RestartAbstractPowerModel!(pm)
CompositeAdequacy.field(system, Branches, :status)[25] = 1
CompositeAdequacy.field(system, Branches, :status)[26] = 1
CompositeAdequacy.field(system, Branches, :status)[28] = 1

#JuMP.solution_summary(pm.model, verbose=true)


CompositeAdequacy.field(system, Generators, :pg)
CompositeAdequacy.field(system, Generators, :qg)



"***************************************************************************************************************************"
ref = PRATSBase.BuildNetwork(RawFile)
CompositeAdequacy.ref_add!(ref)


loads.status[1]=false
loadlookup = Dict(n=>i for (i, n) in enumerate(loads.keys) if loads.status[i]==true)



"***************************************************************************************************************************"







[filter(t -> t[1] in starts[i] && t[2] in valid[i], my_tuple) for i in eachindex(starts, valid)]



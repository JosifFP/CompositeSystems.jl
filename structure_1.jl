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

CompositeAdequacy.Topology(system)
pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCPowerModel, JuMP.direct_model(optimizer), CompositeAdequacy.Topology(system))
systemstate = CompositeAdequacy.SystemState(system)

systemstate.generators

@btime CompositeAdequacy.Available(system)
@btime CompositeAdequacy.Available(systemstate,1)




CompositeAdequacy.Available(system) = CompositeAdequacy.Available(state,1)




resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMonteCarlo(samples=4, seed=123, verbose=false, threaded=true)
@time shortfall,report = PRATS.assess(system, method, resultspecs...)

model = JuMP.direct_model(optimizer)

keyss = [i for i in CompositeAdequacy.field(system, Generators, :keys) if CompositeAdequacy.field(system, Generators, :status)[i] ≠ 0]

JuMP.@variable(model, pg[i in CompositeAdequacy.field(system, Generators, :keys); CompositeAdequacy.field(system, Generators, :status)[i] ≠ 0])

for i in eachindex(model[:pg])
    println(i[1])
end

@btime for i in CompositeAdequacy.field(system, Generators, :keys)
    #println(i[1])
end



CompositeAdequacy.field(system, Generators, :pmax)[11]
ref = PRATSBase.BuildNetwork(RawFile)
typeof(ref[:gen][11]["pmax"])


t=1
state = CompositeAdequacy.SystemState(system)
pm = CompositeAdequacy.BuildAbstractPowerModel!(CompositeAdequacy.DCPowerModel, JuMP.direct_model(optimizer))
rng = CompositeAdequacy.Philox4x((0, 0), 10)
iter = CompositeAdequacy.initialize!(rng, state, system) #creates the up/down sequence for each device.
CompositeAdequacy.update_system!(state, system, t)
system.loads.status
@show system.branches.status
@show system.generators.status
type = CompositeAdequacy.DCOPF
pm.model
CompositeAdequacy.build_method!(pm, system, t, type)
JuMP.optimize!(pm.model)
JuMP.solution_summary(pm.model, verbose=true)
CompositeAdequacy.build_result!(pm, system, t)
CompositeAdequacy.build_sol_values(CompositeAdequacy.sol(pm, :load_curtailment))





























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

systemstate = CompositeAdequacy.SystemState(system)



start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))
timestamps = range(start_timestamp, length=N, step=PRATSBase.T(1))#::StepRange{DateTime, Hour}






pm = CompositeAdequacy.BuildAbstractPowerModel!(CompositeAdequacy.DCPowerModel, JuMP.direct_model(optimizer))
type = CompositeAdequacy.DCOPF

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
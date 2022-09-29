using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 365)

systemstate = CompositeAdequacy.SystemState(system)
ref_1 = CompositeAdequacy.initialize_ref(system.network)
ref_2 = deepcopy(CompositeAdequacy.initialize_ref(system.network))

ref_1[:branch][25]["br_status"] = 0
ref_1[:branch][26]["br_status"] = 0
ref_1[:branch][28]["br_status"] = 0
CompositeAdequacy.ref_add!(ref_1)
CompositeAdequacy.ref_add!(ref_2)

@assert ref_1[:arcs] == ref_2[:arcs]

@show ref_1[:arcs]
ref_2[:arcs]
ref_1[:arcs_from]
ref_2[:arcs_from]
ref_1[:arcs_to]
ref_2[:arcs_to]
ref_1[:bus_loads]
ref_1[:bus_arcs][15]
ref_2[:bus_arcs][15]

@assert ref_1[:bus_arcs] == ref_2[:bus_arcs]
@assert ref_1[:branch] == ref_2[:branch]
@assert ref_1[:areas] == ref_2[:areas]
@assert ref_1[:bus] == ref_2[:bus]
@assert ref_1[:gen] == ref_2[:gen]
@assert ref_1[:storage] == ref_2[:storage]
@assert ref_1[:switch] == ref_2[:switch]
@assert ref_1[:shunt] == ref_2[:shunt]
@assert ref_1[:load] == ref_2[:load]

[i for i in keys(ref_1[:bus])]

container_1 = [i for i in keys(ref_1[:branch])]
container_2 = [i for i in keys(ref_2[:branch])]
key_order_1 = sortperm(container_1)
key_order_2 = sortperm(container_2)
@show container_1[key_order_1]
@show container_2[key_order_2]


bus = convert(system.network.bus)
dcline = convert(system.network.dcline)
gen = convert(system.network.gen)
branch = convert(system.network.branch)
storage = convert(system.network.storage)
switch = convert(system.network.switch)
shunt = convert(system.network.shunt)
load = convert(system.network.load)


[(i,v) for (i,v) in system.network.load]
container_keys = [(i,v) for (i,v) in system.network.load if (v["status"] ≠ 0 && v["load_bus"] in keys(system.network.bus))]
key_order = sortperm(container_keys)
container_keys[key_order]



key_order = sortperm(container_keys)

hmm = (; (Symbol(k) => v for (k,v) in container_keys[key_order])...)
hmm2 = (; (Symbol(k) => v for (k,v) in container_keys[key_order] if (v["status"] ≠ 0 && v["load_bus"] in keys(container_keys[key_order])))...)


container_keys = [i for i in keys(system.network.load)]
container_values = [i for i in values(system.network.load)]
key_order = sortperm(container_keys)
container_keys[key_order]


for v in load[2]
    if v["status"] ≠ 0 && v["load_bus"] in load[1] 
        filter!(e->e∉v,load)
    end
end

typeof(load)

hmm = NamedTuple{Tuple(Symbol.(keys(container_keys[key_order])))}(values(container_values[key_order]))

# [filter(t -> t[1] in ) for i in eachindex(hmm)]

    # var = NamedTuple{Tuple(Symbol.([:p, :ps, :pg, :p_dc, :p_lc, :psw, :va, :w, :wr, :wi]))}
    #     ([Float64[], Float64[], Float64[], Float64[], Float64[], Float64[], Float64[], Float64[], Float64[], Float64[]]
    # )
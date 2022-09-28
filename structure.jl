using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 2160)

systemstate = CompositeAdequacy.SystemState(system)



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
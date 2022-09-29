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
CompositeAdequacy.ref_add!(ref_1)

ref_1[:arcs_from_dc]
ref_1[:arcs]
ref_1[:bus_gens]
ref_1[:bus_loads]
ref_1[:bus_shunts]
ref_1[:bus_arcs]
ref_1[:buspairs][(1,2)]
ref_1[:buspairs]



sys = deepcopy(system.network)
nbus = length(sys.bus)
nbranch = length(sys.branch)
nstorage = length(sys.storage)
ngen = length(sys.gen)
ndcline = length(sys.dcline)
nswitch = length(sys.switch)
nshunt = length(sys.shunt)
nload = length(sys.load)

system.generators.keys
system.generators.buses

regionlookup = Dict(n=>i for (i, n) in enumerate(system.generators.keys))
bus_gens = getindex.(Ref(regionlookup), system.generators.buses)

bus_gens_idxs = makeidxlist(bus_gens, nbus)














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
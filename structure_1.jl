using PRATS
using PRATS.PRATSBase
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test, Dates
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 365)

ref = PRATSBase.BuildNetwork(RawFile)


for (i, load) in ref[:load]
    if !(load["load_bus"] in system.buses.keys) && !(system.loads.buses[i] in system.buses.keys)
        Memento.error(_LOGGER, "bus $(load["load_bus"]) in load $(i) is not defined")
    end
end
ref[:shunt][1]["shunt_bus"]
system.shunts.buses

for (i, shunt) in ref[:shunt]
    if !(shunt["shunt_bus"] in system.buses.keys) || !(system.shunts.buses[i] in system.buses.keys)
        Memento.error(_LOGGER, "bus $(shunt["shunt_bus"]) in shunt $(i) is not defined")
    end
end








N=365
CurrentDir = pwd()
L = 1 #timestep_length
T = timeunits["h"] #timestep_unit
U = perunit["pu"]
#P = powerunits["MW"] #E = energyunits["MWh"] #V = voltageunits["kV"]
start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))

timestamps = range(start_timestamp, length=N, step=T(L))::StepRange{DateTime, Hour}
files = readdir(ReliabilityDataDir; join=false)
cd(ReliabilityDataDir)
network = PRATSBase.BuildNetwork(RawFile)

if network[:per_unit] == false error("Network data must be in per unit format") end

has_buses = haskey(network, :bus) && isempty(network[:bus]) == false
has_loads = haskey(network, :load) && isempty(network[:load]) == false
has_generators = haskey(network, :gen) && isempty(network[:gen]) == false
has_storages = haskey(network, :storage) && isempty(network[:storage]) == false
has_branches = haskey(network, :branch) && isempty(network[:branch]) == false
has_dclines = haskey(network, :dcline) && isempty(network[:dcline]) == false
has_switches = haskey(network, :switch) && isempty(network[:switch]) == false
has_shunts = haskey(network, :shunt) && isempty(network[:shunt]) == false

has_buses || error("Bus data must be provided")
has_generators && has_loads && has_branches || error("Generator, Load and Branch data must be provided")



dict_timeseries, dict_core = PRATSBase.extract(ReliabilityDataDir, files, PRATSBase.Generators, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
container_key = [i for i in keys(dict_timeseries)]
key_order = sortperm(container_key)



"********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************"
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
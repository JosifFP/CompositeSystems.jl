using PRATS
import PRATS.PRATSBase: PRATSBase, BuildNetwork, SystemModel, extract_timeseriesload
import PRATS.CompositeAdequacy: CompositeAdequacy, field, var, topology, makeidxlist, sol,
    assetgrouplist, findfirstunique, build_sol_values, Cache, initialize!, PowerFlowProblem, 
    initialize!, seed!, update!
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
include("solvers.jl")
TimeSeriesFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/Loads.xlsx"
RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/RBTS.m"
ReliabilityFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/R_RBTS.m"

timeseries_load, SParametrics = extract_timeseriesload(TimeSeriesFile)
system = SystemModel(RawFile, ReliabilityFile, timeseries_load, SParametrics)

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    ipopt_optimizer_3,
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)
method = PRATS.SequentialMCS(samples=8, seed=987, threaded=false)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)





systemstates = SystemStates(system, method)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
seed!(rng, (666, 1))
cache = Cache(system, method, multiperiod=false)
pm = PowerFlowProblem(system, field(settings, :powermodel), method, cache, settings)
systemstates = SystemStates(system, method)
initialize!(rng, systemstates, system)

8736 - sum(systemstates.system)

systemstates.system


count(field(systemstates, :generators)[:,1]) <











assetgrouplist(pm.topology.buses_idxs)
assetgrouplist(pm.topology.loads_idxs)
assetgrouplist(pm.topology.branches_idxs)
assetgrouplist(pm.topology.shunts_idxs)
assetgrouplist(pm.topology.generators_idxs)
assetgrouplist(pm.topology.storages_idxs)
assetgrouplist(pm.topology.generatorstorages_idxs)
pm.topology.loads_nodes
pm.topology.shunts_nodes
pm.topology.generators_nodes
pm.topology.storages_nodes
pm.topology.generatorstorages_nodes
@show pm.topology.arcs.buspairs





















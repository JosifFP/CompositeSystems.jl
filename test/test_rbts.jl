using PRATS, PRATS.OPF, PRATS.BaseModule
using PRATS.OPF
using PRATS.CompositeAdequacy
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
method = SequentialMCS(samples=8, seed=654, threaded=false)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)

using Ipopt
IpoptNLSolver()


topo = Topology(system)
@time pm = CompositeAdequacy.Initialize_model(system, topo, settings)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
seed!(rng, (666, 1))
systemstates = SystemStates(system, method)
initialize!(rng, systemstates, system)


t=1
field(systemstates, :generators)[3,t] = 0
field(systemstates, :generators)[7,t] = 0
field(systemstates, :generators)[8,t] = 0
field(systemstates, :generators)[9,t] = 0
systemstates.system[t] = 0
update!(pm.topology, systemstates, system, t)
@code_warntype CompositeAdequacy.build_method!(pm, system, t)
CompositeAdequacy.optimize!(pm.model; ignore_optimize_hook = true)
@code_warntype solve!(pm, system, t)


import PowerModels

PowerModels.silence()
data = PowerModels.parse_file(RawFile)
@time for i in 1:8736
    result = PowerModels.solve_dc_opf(data, ipopt_optimizer_3)
end

JuMP.optimize!(pm.model)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)

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
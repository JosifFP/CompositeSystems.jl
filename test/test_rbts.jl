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

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    ipopt_optimizer_3,
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)

timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)
system = SystemModel(RawFile, ReliabilityFile, timeseries_load, SParametrics)
method = SequentialMCS(samples=20, seed=1, threaded=false)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)












using JuMP
x = JuMP.all_variables(pm.model)
x_solution = JuMP.value.(x)
@show JuMP.set_start_value.(x, x_solution)


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

using Ipopt
IpoptNLSolver()


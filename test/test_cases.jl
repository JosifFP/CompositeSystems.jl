using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")
timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
rawfile = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS4.m"


#timeseriesfile = "test/data/SMCS/MRBTS/Loads_system.xlsx"
#rawfile = "test/data/SMCS/MRBTS/MRBTS.m"
#Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"

#timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
#rawfile = "test/data/SMCS/RTS_79_A/RTS.m"
#Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS2.m"

resultspecs = (Shortfall(), Shortfall())
settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    modelmode = JuMP.AUTOMATIC,
    #powermodel = OPF.NFAPowerModel
    powermodel = OPF.DCPPowerModel
    #powermodel = OPF.DCMPPowerModel
    #powermodel = OPF.DCPLLPowerModel
    #powermodel = OPF.LPACCPowerModel
)

system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = SequentialMCS(samples=2000, seed=100, threaded=true)
#method = SequentialMCS(samples=1, seed=100, threaded=false)
@time shortfall,report = CompositeSystems.assess(system, method, settings, resultspecs...)

CompositeSystems.LOLE.(shortfall, system.buses.keys)
CompositeSystems.EENS.(shortfall, system.buses.keys)
CompositeSystems.LOLE.(shortfall)
CompositeSystems.EENS.(shortfall)



val.(CompositeSystems.EENS.(shortfall, system.buses.keys))




threads = Base.Threads.nthreads()
sampleseeds = Channel{Int}(2*threads)
results = CompositeAdequacy.resultchannel(method, resultspecs, threads)
Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.
method = CompositeAdequacy.SequentialMCS(samples=1, seed=100, threaded=false)
states = CompositeAdequacy.SystemStates(system)
model = OPF.jump_model(settings.modelmode, deepcopy(settings.optimizer))
pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)

recorders = CompositeAdequacy.accumulator.(system, method, resultspecs)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
s=2
t=2544

CompositeAdequacy.seed!(rng, (method.seed, s))
CompositeAdequacy.initialize_states!(rng, states, system)

if OPF.is_empty(pm.model.moi_backend)
    CompositeAdequacy.initialize_powermodel!(pm, system, states)
end

CompositeAdequacy.update!(pm, system, states, t)
states.plc[:,t]


CompositeAdequacy.reset_model!(pm, states, settings, s)
s=3
t=2544
CompositeAdequacy.seed!(rng, (method.seed, s))
CompositeAdequacy.initialize_states!(rng, states, system)

if OPF.is_empty(pm.model.moi_backend)
    CompositeAdequacy.initialize_powermodel!(pm, system, states)
end

states.plc[:,t]
states.branches[:,t]
states.generators[:,t]

pm.topology

assetgrouplist(pm.topology.buses_idxs::Vector{UnitRange{Int}})
assetgrouplist(pm.topology.loads_idxs::Vector{UnitRange{Int}})
assetgrouplist(pm.topology.branches_idxs::Vector{UnitRange{Int}})
assetgrouplist(pm.topology.shunts_idxs::Vector{UnitRange{Int}})
assetgrouplist(pm.topology.generators_idxs::Vector{UnitRange{Int}})
assetgrouplist(pm.topology.storages_idxs::Vector{UnitRange{Int}})
assetgrouplist(pm.topology.generatorstorages_idxs::Vector{UnitRange{Int}})


all(view(states.branches,:,t)) ≠ true
all(view(states.branches,:,t-1)) ≠ true



pm.topology.bus_loads::Dict{Int, Vector{Int}}
pm.topology.bus_shunts::Dict{Int, Vector{Int}}
pm.topology.bus_generators::Dict{Int, Vector{Int}}
pm.topology.bus_storages::Dict{Int, Vector{Int}}
pm.topology.bus_generatorstorages::Dict{Int, Vector{Int}}

pm.topology.arcs_from::Vector{Union{Missing, Tuple{Int, Int, Int}}}
pm.topology.arcs_to::Vector{Union{Missing, Tuple{Int, Int, Int}}}
pm.topology.arcs::Vector{Union{Missing, Tuple{Int, Int, Int}}}
pm.topology.busarcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
pm.topology.buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}


JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
sum(system.buses.pd[:,1])



sum(val.(CompositeSystems.EENS.(shortfall, system.buses.keys)))


a = systemstates.generators[1,:]
using Plots
plot(1:8736, a)

a = systemstates.generators[2,:]
using Plots
plot(1:8736, a)

a = systemstates.generators[3,:]
using Plots
plot(1:8736, a)
import PowerModels
using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
PowerModels.silence()


TimeSeriesFile2 = "test/data/RTS/Loads.xlsx"
Base_RawFile2 = "test/data/RTS/Base/RTS.m"
Base_ReliabilityFile2 = "test/data/RTS/Base/R_RTS.m"
timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile2)
system = BaseModule.SystemModel(Base_RawFile2, Base_ReliabilityFile2, timeseries_load, SParametrics)

systemstates = SystemStates(system)
initial_topology = Topology(system)
include("solvers.jl")
settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    #juniper_optimizer_2,
    modelmode = JuMP.AUTOMATIC,
    powermodel = OPF.DCMPPowerModel
    #powermodel = OPF.DCPLLPowerModel
)
model = JumpModel(settings.modelmode, deepcopy(settings.optimizer))
pm = PowerModel(settings.powermodel, Topology(system), model)
method = SequentialMCS(samples=1, seed=100, threaded=false)
resultspecs = (Shortfall(), Shortfall())
recorders = accumulator.(system, method, resultspecs)   #DON'T MOVE THIS LINE
rng = CompositeAdequacy.Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE
s=1
CompositeAdequacy.seed!(rng, (method.seed, s))  #using the same seed for entire period.
CompositeAdequacy.initialize_states!(rng, systemstates, system) #creates the up/down sequence for each device.
CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
t=2663

states = systemstates
update_idxs!(
    filter(i->BaseModule.field(states, :generators, i, t), field(system, :generators, :keys)), 
    topology(pm, :generators_idxs), topology(pm, :generators_nodes), field(system, :generators, :buses))

update_idxs!(
    filter(i->BaseModule.field(states, :shunts, i, t), field(system, :shunts, :keys)), 
    topology(pm, :shunts_idxs), topology(pm, :shunts_nodes), field(system, :shunts, :buses))

update_idxs!(
    filter(i->BaseModule.field(states, :storages, i, t), field(system, :storages, :keys)), 
    topology(pm, :storages_idxs), topology(pm, :storages_nodes), field(system, :storages, :buses))
    
update_idxs!(filter(i->BaseModule.field(states, :branches, i, t), field(system, :branches, :keys)), topology(pm, :branches_idxs))


if all(view(field(systemstates, :branches),:,t)) == false
    simplify!(system, systemstates, pm.topology, t)
    update_idxs!(filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), topology(pm, :buses_idxs))
end

systemstates.generators[:,t]
@show systemstates.branches[:,t]
systemstates.loads[:,t]

if any(i -> i==4,view(states.buses, :, t)) == true
    build_method!(pm, system, states, t)
else
    update_method!(pm, system, states, t)
end

optimize_method!(pm)
build_result!(pm, system, states, t)

systemstates.plc[:,t]
systemstates.branches[:,:]
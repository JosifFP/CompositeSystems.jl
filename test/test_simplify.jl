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
t=2


systemstates.branches[11,t] = 0

update_idxs!(filter(i->BaseModule.field(systemstates, :generators, i, t), field(system, :generators, :keys)), topology(pm, :generators_idxs))
update_idxs!(filter(i->BaseModule.field(systemstates, :shunts, i, t), field(system, :shunts, :keys)), topology(pm, :shunts_idxs)) 
update_idxs!(filter(i->BaseModule.field(systemstates, :branches, i, t), field(system, :branches, :keys)), topology(pm, :branches_idxs))


busarcs = deepcopy(field(pm.topology, :busarcs))

for i in field(system, :branches, :keys)

    f_bus = field(system, :branches, :f_bus)[i]
    t_bus = field(system, :branches, :t_bus)[i]

    if systemstates.branches[i,t] == false
        busarcs[:,i] = Array{Missing}(undef, size(field(pm.topology, :busarcs),1))
    end
end


systemstates.branches[:,t]
systemstates.buses[:,t]
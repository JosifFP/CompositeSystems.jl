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
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
#rawfile = "test/data/RTS/Base/RTS.m"
#Base_reliabilityfile = "test/data/RTS/Base/R_RTS.m"
#Storage_rawfile = "test/data/RBTS/Storage/RBTS.m"
#Storage_reliabilityfile = "test/data/RBTS/Storage/R_RBTS.m"
#Case1_rawfile = "test/data/RBTS/Case1/RBTS.m"
#Case1_reliabilityfile = "test/data/RBTS/Case1/R_RBTS.m"

resultspecs = (Shortfall(), Shortfall())
settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    modelmode = JuMP.AUTOMATIC,
    #powermodel = OPF.NFAPowerModel
    #powermodel = OPF.DCPPowerModel
    #powermodel = OPF.DCMPPowerModel
    #powermodel = OPF.DCPLLPowerModel
    powermodel = OPF.LPACCPowerModel
)

system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = SequentialMCS(samples=20, seed=100, threaded=false)
@time shortfall,report = CompositeSystems.assess(system, method, settings, resultspecs...)

CompositeSystems.LOLE.(shortfall, system.loads.keys)
CompositeSystems.EENS.(shortfall, system.loads.keys)
CompositeSystems.LOLE.(shortfall)
CompositeSystems.EENS.(shortfall)




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
s=1

CompositeAdequacy.seed!(rng, (method.seed, s))
CompositeAdequacy.initialize_states!(rng, states, system)

if OPF.is_empty(pm.model.moi_backend)
    CompositeAdequacy.initialize_powermodel!(pm, system, states)
end

JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
sum(system.loads.pd[:,1])



sum(val.(CompositeSystems.EENS.(shortfall, system.loads.keys)))


a = systemstates.generators[1,:]
b = systemstates.generators_de[1,:]
using Plots
plot(1:8736, a)
plot(1:8736, b)

a = systemstates.generators[2,:]
b = systemstates.generators_de[2,:]
using Plots
plot(1:8736, a)
plot(1:8736, b)

a = systemstates.generators[3,:]
b = systemstates.generators_de[3,:]
using Plots
plot(1:8736, a)
plot(1:8736, b)
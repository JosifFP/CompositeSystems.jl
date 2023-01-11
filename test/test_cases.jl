using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")
#timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
#rawfile = "test/data/RBTS/Base/RBTS_AC.m"
#Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"

#timeseriesfile = "test/data/SMCS/MRBTS/Loads_system.xlsx"
#rawfile = "test/data/SMCS/MRBTS/MRBTS_DC.m"
#Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"

timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"

resultspecs = (Shortfall(), Shortfall())
settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    modelmode = JuMP.AUTOMATIC,
    #powermodel = OPF.NFAPowerModel
    #powermodel = OPF.DCPPowerModel
    powermodel = OPF.DCMPPowerModel
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
val.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
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
s=1
CompositeAdequacy.seed!(rng, (method.seed, s))
CompositeAdequacy.initialize_states!(rng, states, system)



JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
sum(system.buses.pd[:,1])



a = systemstates.generators[1,:]
using Plots
plot(1:8736, a)

a = systemstates.generators[2,:]
using Plots
plot(1:8736, a)

a = systemstates.generators[3,:]
using Plots
plot(1:8736, a)


""
function _select_largest_component!(data::Dict{String,<:Any})
    ccs = calc_connected_components(data)

    if length(ccs) > 1
        Memento.info(_LOGGER, "found $(length(ccs)) components")

        ccs_order = sort(collect(ccs); by=length)
        largest_cc = ccs_order[end]

        Memento.info(_LOGGER, "largest component has $(length(largest_cc)) buses")

        for (i,bus) in data["bus"]
            if bus["bus_type"] != 4 && !(bus["index"] in largest_cc)
                bus["bus_type"] = 4
                Memento.info(_LOGGER, "deactivating bus $(i) due to small connected component")
            end
        end

        correct_reference_buses!(data)
    end
end
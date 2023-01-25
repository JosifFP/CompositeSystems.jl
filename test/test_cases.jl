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
rawfile = "test/data/RBTS/Base/RBTS_AC.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"

#timeseriesfile = "test/data/SMCS/MRBTS/Loads_system.xlsx"
#rawfile = "test/data/SMCS/MRBTS/MRBTS_AC.m"
#Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"

#timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
#rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
#Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"

resultspecs = (Shortfall(), GeneratorAvailability())
settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    modelmode = JuMP.AUTOMATIC,
    #powermodel = OPF.NFAPowerModel
    #powermodel = OPF.DCPPowerModel
    #powermodel = OPF.DCMPPowerModel
    powermodel = OPF.LPACCPowerModel
)

system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = SequentialMCS(samples=7500, seed=100, threaded=true)
@time shortfall,availability = CompositeSystems.assess(system, method, settings, resultspecs...)


CompositeSystems.LOLE.(shortfall, system.buses.keys)
CompositeSystems.EENS.(shortfall, system.buses.keys)
CompositeSystems.LOLE.(shortfall)
CompositeSystems.EENS.(shortfall)
val.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
val.(CompositeSystems.EENS.(shortfall, system.buses.keys))





key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))
@btime buses_idxs = makeidxlist(key_buses, length(system.buses))



using IterTools

function makeidxlist_v2(keys::Vector{Int}, N::Int)
    grouped = IterTools.groupby(keys)
    idxlist = Vector{Vector{Int}}(undef, N)
    for (val, group) in grouped
        idxlist[val] = vec(group)
    end
    return idxlist
end


key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))
@btime buses_idxs = makeidxlist_v2(key_buses, length(system.buses))



singlestates = NextTransition(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.initialize_availability!(rng, singlestates.generators_available, singlestates.generators_nexttransition, system.generators, 8736)
systemstates = SystemStates(system)
CompositeAdequacy.initialize_states!(rng, systemstates, system)

t=2
BaseModule.check_availability(field(systemstates, :branches), t, t-1)


field(systemstates, :branches)[1,2] = 0


field(systemstates, :branches)



singlestates.generators_available


timestamprow = permutedims(system.timestamps)
busescol = system.buses.keys
println("SpatioTemporal LOLPs:")
display(vcat(
    hcat("", timestamprow),
    hcat(busescol, LOLE(shortfall, :, :))
)); println()

println("SpatioTemporal EUEs:")
display(vcat(
    hcat("", timestamprow),
    hcat(busescol, EENS(shortfall, :, :))
)); println()




a=shortfall.eventperiod_period_mean*100
sum(a)
using Plots
plot(1:8736, a)

a=shortfall.shortfall_busperiod_std*100
sum(a)
using Plots
a
plot(1:8736, a[6,:])







new{N,L,T,P,E}(nsamples, buses, timestamps,
eventperiod_mean, eventperiod_std,
eventperiod_bus_mean, eventperiod_bus_std,
eventperiod_period_mean, eventperiod_period_std,
eventperiod_busperiod_mean, eventperiod_busperiod_std,
shortfall_mean, shortfall_std,
shortfall_bus_std, shortfall_period_std,
shortfall_busperiod_std)




threads = Base.Threads.nthreads()
sampleseeds = Channel{Int}(2*threads)
results = CompositeAdequacy.resultchannel(method, resultspecs, threads)
Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.
method = CompositeAdequacy.SequentialMCS(samples=1, seed=100, threaded=false)
states = CompositeAdequacy.SystemStates(system)
pm = OPF.abstract_model(system, settings)
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
plot(1:8736, a``
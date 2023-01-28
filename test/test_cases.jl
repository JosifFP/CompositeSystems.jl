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
#rawfile = "test/data/SMCS/MRBTS/MRBTS_AC.m"
#Base_reliabilityfile = "test/data/SMCS/MRBTS/R_MRBTS.m"

timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH.m"
Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"

resultspecs = (Shortfall(), GeneratorAvailability())
settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    #powermodel_formulation = OPF.NFAPowerModel
    #powermodel_formulation = OPF.DCPPowerModel
    powermodel_formulation = OPF.DCMPPowerModel
    #powermodel_formulation = OPF.LPACCPowerModel
)

system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method = SequentialMCS(samples=8, seed=100, threaded=true)
@time shortfall,availability = CompositeSystems.assess(system, method, settings, resultspecs...)


shortfall.eventperiod_mean
shortfall.eventperiod_std
shortfall.eventperiod_bus_mean
shortfall.eventperiod_bus_std
shortfall.eventperiod_period_mean
shortfall.eventperiod_period_std
shortfall.eventperiod_busperiod_mean
shortfall.eventperiod_busperiod_std
shortfall.shortfall_mean
shortfall.shortfall_std
shortfall.shortfall_bus_std
shortfall.shortfall_period_std
shortfall.shortfall_busperiod_std

collect(shortfall.eventperiod_bus_mean)
collect(shortfall.eventperiod_busperiod_mean')


CompositeSystems.LOLE.(shortfall, system.buses.keys)
CompositeSystems.EENS.(shortfall, system.buses.keys)
CompositeSystems.LOLE.(shortfall)
CompositeSystems.EENS.(shortfall)
val.(CompositeSystems.LOLE.(shortfall, system.buses.keys))
val.(CompositeSystems.EENS.(shortfall, system.buses.keys))


using XLSX
XLSX.openxlsx("results_shortfall.xlsx", mode="w") do xf
    XLSX.rename!(xf[1], "new_sheet_1")
    xf[1]["A1"] = "eventperiod_mean"
    xf[1]["A2"] = shortfall.eventperiod_mean
    xf[1]["B1"] = "eventperiod_std"
    xf[1]["B2"] = shortfall.eventperiod_std
    xf[1]["C1"] = "eventperiod_bus_mean"
    xf[1]["C2", dim=1] = collect(shortfall.eventperiod_bus_mean)
    xf[1]["D1"] = "eventperiod_bus_std"
    xf[1]["D2", dim=1] = collect(shortfall.eventperiod_bus_std)
    xf[1]["E1"] = "eventperiod_period_mean"
    xf[1]["E2", dim=1] = collect(shortfall.eventperiod_period_mean)
    xf[1]["F1"] = "eventperiod_period_std"
    xf[1]["F2", dim=1] = collect(shortfall.eventperiod_period_std)
    xf[1]["G1"] = "shortfall_std"
    xf[1]["G2"] = shortfall.shortfall_std
    xf[1]["H1"] = "shortfall_bus_std"
    xf[1]["H2", dim=1] = collect(shortfall.shortfall_bus_std)
    xf[1]["I1"] = "shortfall_period_std"
    xf[1]["I2", dim=1] = collect(shortfall.shortfall_period_std)
    XLSX.addsheet!(xf, "eventperiod_busperiod_mean")
    xf[2]["A1"] = collect(shortfall.eventperiod_busperiod_mean')
    XLSX.addsheet!(xf, "eventperiod_busperiod_std")
    xf[3]["A1"] = collect(shortfall.eventperiod_busperiod_std')
    XLSX.addsheet!(xf, "shortfall_mean")
    xf[4]["A1"] = collect(shortfall.shortfall_mean')
    XLSX.addsheet!(xf, "shortfall_busperiod_std")
    xf[5]["A1"] = collect(shortfall.shortfall_busperiod_std')
end





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
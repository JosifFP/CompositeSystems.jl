using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RBTS.m"
PRATSBase.silence()
using Plots


system = PRATSBase.SystemModel(RawFile; ReliabilityDataDir=ReliabilityDataDir, N=8736)
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])

pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCPowerModel, JuMP.Model(optimizer; add_bridges = false), CompositeAdequacy.Topology(system))
systemstate = CompositeAdequacy.SystemState(system)

rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.initialize!(rng, systemstate, system)

y1 = systemstate.generators[1,:]
y2 = systemstate.generators[2,:]
y3 = systemstate.generators[3,:]
y4 = systemstate.generators[4,:]
y5 = systemstate.generators[5,:]
y6 = systemstate.generators[6,:]
y7 = systemstate.generators[7,:]
yy = systemstate.condition
x=1:8736
Plots.plot(x,yy)



shortfall.nsamples
shortfall.loads
shortfall.timestamps
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

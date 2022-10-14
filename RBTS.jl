using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
using Test
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RBTS.m"
PRATSBase.silence()
#InputData = ["Loads", "Generators", "Branches"]
#PRATSBase.FileGenerator(RawFile, InputData)
system = PRATSBase.SystemModel(RawFile; ReliabilityDataDir=ReliabilityDataDir, N=8736)

nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])

resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMonteCarlo(samples=8, seed=1, verbose=false, threaded=true)
@time shortfall,report = PRATS.assess(system, method, resultspecs...)

PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)
shortfall.shortfall_bus_std

pd = Matrix{Float64}(undef, 17, 100)
size(pd, 2)

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
@show shortfall.shortfall_mean
shortfall.shortfall_std
shortfall.shortfall_bus_std
@show shortfall.shortfall_period_std
@show shortfall.shortfall_busperiod_std



topology = CompositeAdequacy.Topology(system)
pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCPowerModel, JuMP.direct_model(optimizer), CompositeAdequacy.Topology(system))
systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.initialize!(rng, systemstate, system)

t=1
CompositeAdequacy.update!(pm.topology, systemstate, system, t)
type = CompositeAdequacy.DCOPF
CompositeAdequacy.build_method!(pm, system, t, type)
JuMP.optimize!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
CompositeAdequacy.empty_model!(pm)
CompositeAdequacy.solve!(pm, systemstate, system, t)
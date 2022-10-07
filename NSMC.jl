using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test, Dates
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 365)
resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMonteCarlo(samples=2, seed=123, verbose=false, threaded=true)


threads = Base.Threads.nthreads()
sampleseeds = Channel{Int}(2*threads)
results = CompositeAdequacy.resultchannel(method, resultspecs, threads)
Base.Threads.@spawn CompositeAdequacy.makeseeds(sampleseeds, method.nsamples)

for _ in 1:threads
    Base.Threads.@spawn CompositeAdequacy.assess(system, optimizer, method, sampleseeds, results, resultspecs...)
end


method.threaded ? threads : 1
results
CompositeAdequacy.finalize(results, system, method.threaded ? threads : 1)
using PRATS
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 2160)
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
minlp_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "time_limit"=>1.5, "log_levels"=>[])
optimizer = [nl_solver, mip_solver, minlp_solver]

threads = Base.Threads.nthreads()
sampleseeds = Channel{Int}(2)
simspec = CompositeAdequacy.SequentialMonteCarlo(samples=1, seed=1)
resultspecs = (Flow(), Flow())
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)
systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)

s=1
CompositeAdequacy.seed!(rng, (simspec.seed, s))
CompositeAdequacy.initialize!(rng, systemstate, system)

"************************************************************************************************"
Dict{String,Any}()

@btime data = Dict(
    [("bus", Dict{String,Any}())
    ("dcline", Dict{String,Any}())
    ("gen", Dict{String,Any}())
    ("branch", Dict{String,Any}())
    ("storage", Dict{String,Any}())
    ("switch", Dict{String,Any}())
    ("shunt", Dict{String,Any}())
    ("load", Dict{String,Any}())]
)

data["bus"] = data

data
@btime empty!(data)
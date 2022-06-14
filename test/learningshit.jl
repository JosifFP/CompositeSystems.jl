using MinCostFlows
using PRATS
import Random: AbstractRNG, rand, seed!

loadfile = "test/data/rts_Load.xlsx";

#how?
#resultspecs = (Shortfall(), Surplus(), Flow(), Utilization(), ShortfallSamples(), SurplusSamples(),
#            FlowSamples(), UtilizationSamples(), GeneratorAvailability());

include("C:/Users/jfiguero/.julia/dev/PRATS/src/PRE/simulations/sequentialmontecarlo/SystemState.jl")
include("C:/Users/jfiguero/.julia/dev/PRATS/src/PRE/simulations/sequentialmontecarlo/DispatchProblem.jl")
include("C:/Users/jfiguero/.julia/dev/PRATS/src/PRE/simulations/sequentialmontecarlo/utils.jl")

system = PRATS.SystemModel(loadfile);
method = SequentialMonteCarlo();
resultspecs = (Shortfall(), Surplus());

#function assess(
#    system::SystemModel,
#    method::SequentialMonteCarlo,
#    resultspecs::ResultSpec...
#)

    threads = Base.Threads.nthreads() #this read #threads specified by VS
    sampleseeds = Channel{Int}(2*threads)
    results = PRATS.resultchannel(method, resultspecs, threads)
    Base.Threads.@spawn makeseeds(sampleseeds, method.nsamples)

    if method.threaded
        for _ in 1:threads
            #Base.Threads.@spawn assess(system, method, sampleseeds, results, resultspecs...)
        end
    else
        #assess(system, method, sampleseeds, results, resultspecs...)
    end

    return finalize(results, system, method.threaded ? threads : 1)

#end
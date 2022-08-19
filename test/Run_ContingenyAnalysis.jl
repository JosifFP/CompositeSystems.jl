using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy

RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)

method = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())
#shortfalls, availability = PRATS.assess(system, method, resultspecs...)

#threads = Base.Threads.nthreads()
threads = 1
sampleseeds = Channel{Int}(2*threads)

results = PRATS.CompositeAdequacy.resultchannel(method, resultspecs, threads)
@async PRATS.CompositeAdequacy.makeseeds(sampleseeds, method.nsamples)

#assess(system, method, sampleseeds, results, resultspecs...)

    sequences = UpDownSequence(system)
    systemstate = SystemState(system)

    recorders = accumulator.(system, method, resultspecs)
    rng = PRATS.CompositeAdequacy.Philox4x((0, 0), 10)
    PRATS.CompositeAdequacy.seed!(rng, (method.seed, 1))  #using the same seed for entire period.
    N =8760
    t = 1



    #for t in 1:N
            
        #advance!(sequences, systemstate, dispatchproblem, system, t)
        #solve!(dispatchproblem, systemstate, system, t)
        #foreach(recorder -> record!(
        #            recorder, system, systemstate, dispatchproblem, s, t
        #        ), recorders)

    #end
using Distributions
using PRATS
using Base.Threads
using TimeZones
using Test
using Random123
import OnlineStatsBase: EqualWeight, fit!, Mean, value, Variance
import Random: AbstractRNG, rand, seed!
import OnlineStats: Series
const tz = tz"UTC"

empty_str = String[]
empty_int(x) = Matrix{Int}(undef, 0, x)
empty_float(x) = Matrix{Float64}(undef, 0, x)

## Single-Region System A
    gens1 = Generators{4,1,Hour,MW}(
        ["Gen1", "Gen2", "Gen3", "VG"], ["Gens", "Gens", "Gens", "VG"],
        [fill(10, 3, 4); [5 6 7 8]],
        [fill(0.1, 3, 4); fill(0.0, 1, 4)],
        [fill(0.9, 3, 4); fill(1.0, 1, 4)]
    )

    emptystors1 = Storages{4,1,Hour,MW,MWh}((empty_str for _ in 1:2)...,
                    (empty_int(4) for _ in 1:3)...,
                    (empty_float(4) for _ in 1:5)...
    )

    emptygenstors1 = GeneratorStorages{4,1,Hour,MW,MWh}(
        (empty_str for _ in 1:2)...,
        (empty_int(4) for _ in 1:3)..., (empty_float(4) for _ in 1:3)...,
        (empty_int(4) for _ in 1:3)..., (empty_float(4) for _ in 1:2)...
    )

    singlenode_a = SystemModel(
        gens1, emptystors1, emptygenstors1,
        DateTime(2010,1,1,0):Hour(1):DateTime(2010,1,1,3),
        [25, 28, 27, 24]
    )
##


timestamps_a = singlenode_a.timestamps
timestamprow_a = permutedims(timestamps_a)

nstderr_tol = 3
simspec = SequentialMonteCarlo(samples=100_000, seed=1, threaded=false)
smallsample = SequentialMonteCarlo(samples=10, seed=123)

resultspecs = (Shortfall(), Flow(), Utilization(),
    ShortfallSamples(), SurplusSamples(),
    FlowSamples(), UtilizationSamples(),
    GeneratorAvailability()
)

shortfalls, flows = assess(singlenode_a, simspec, Shortfall(), Flow())
lole, eue = LOLE(shortfalls), EUE(shortfalls)

@btime shortfalls, flows = assess(singlenode_a, simspec, Shortfall(), Flow())

#1 THREAD, samples=100_000: 
#254.419 ms (1553663 allocations: 425.84 MiB)

#8 THREADS, samples=100_000: 
#827.547 ms (2383445 allocations: 451.19 MiB)


simspec = SequentialMonteCarlo()



#######----------------------------------------------------------------------------------------------------------------------


method = SequentialMonteCarlo(samples=2, seed=1, threaded=false)
system = SystemModel(gens1, emptystors1, emptygenstors1, DateTime(2010,1,1,0):Hour(1):DateTime(2010,1,1,3),[25, 28, 27, 24])
threads = nthreads()
sampleseeds = Channel{Int}(2*threads)
results = PRATS.resultchannel(method, resultspecs, threads)
resultspecs = (Shortfall(), Flow())

function xassess(
    system::SystemModel,
    method::SequentialMonteCarlo
)
    threads = nthreads()
    sampleseeds = Channel{Int}(2*threads)
    resultspecs = (Shortfall(), Flow())
    results =  PRATS.resultchannel(method, resultspecs, threads)

    @spawn  PRATS.makeseeds(sampleseeds, method.nsamples)

    PRATS.assess(system, method, sampleseeds, results, resultspecs...)
    return PRATS.finalize(results, system, method.threaded ? threads : 1)
end



# threads = nthreads()
# sampleseeds = Channel{Int}(2*threads)
# @spawn makeseeds(sampleseeds, method.nsamples)
# chnl = Channel{Int}(2*threads) do sampleseeds
#     for s in 1:method.nsamples
#         put!(sampleseeds, s)
#     end
# end

xassess(system, method)
assess(system, method, Shortfall(), Flow())


method = SequentialMonteCarlo(samples=2, seed=2, threaded=true)
system = SystemModel(gens1, emptystors1, emptygenstors1, DateTime(2010,1,1,0):Hour(1):DateTime(2010,1,1,3),[25, 28, 27, 24])
threads = nthreads()
sampleseeds = Channel{Int}(2*threads)
results = PRATS.resultchannel(method, resultspecs, threads)
@spawn PRATS.makeseeds(sampleseeds, method.nsamples)
dispatchproblem = PRATS.DispatchProblem(system)
systemstate = PRATS.SystemState(system)
recorders = PRATS.accumulator.(system, method, resultspecs)
rng = Philox4x((0, 0), 10)


seed!(rng, (method.seed, 1))
PRATS.initialize!(rng, systemstate, system)


for s in sampleseeds
    seed!(rng, (method.seed, s))
    PRATS.initialize!(rng, systemstate, system)
    for t in 1:4
        PRATS.advance!(rng, systemstate, dispatchproblem, system, t)
        PRATS.solve!(dispatchproblem, systemstate, system, t)
        println(systemstate)
        PRATS.foreach(recorder -> PRATS.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
    end
    foreach(recorder -> PRATS.reset!(recorder, s), recorders)
end
put!(results, recorders)


for s in sampleseeds
println(s)
end

function makeseeds(sampleseeds::Channel{Int}, nsamples::Int)
    for s in 1:nsamples
        put!(sampleseeds, s)
        println(s)
        println(sampleseeds)
    end
    close(sampleseeds)
end
threads = nthreads()
sampleseeds = Channel{Int}(2*threads)
makeseeds(sampleseeds, method.nsamples)
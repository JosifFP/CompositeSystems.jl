using PRATS
using Test
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime
import PRATS.CompositeAdequacy: Philox4x, seed!, ResultSpec, ResultAccumulator
include("testsystems/testsystems.jl")

system =  TestSystems.singlenode_a
simspec = SequentialMonteCarlo(samples=3, seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())
threads = 1
sampleseeds = Channel{Int}(2)
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)  # feed the sampleseeds channel with #N samples.
xassess(system, simspec, sampleseeds, results, resultspecs...)
shortfalls, flows = CompositeAdequacy.finalize(results, system)
lole, eue = LOLE(shortfalls), EUE(shortfalls)


function xassess(
    system::SystemModel{N},  simspec::SequentialMonteCarlo,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMonteCarlo}}}},
    resultspecs::ResultSpec...
) where {R<:ResultSpec, N}

    dispatchproblem = CompositeAdequacy.DispatchProblem(system)
    systemstate = CompositeAdequacy.SystemState(system)
    recorders = CompositeAdequacy.accumulator.(system, simspec, resultspecs)

    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        CompositeAdequacy.seed!(rng, (simspec.seed, s))  #using the same seed for entire period.
        CompositeAdequacy.initialize!(rng, systemstate, system)

        for t in 1:N

            CompositeAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
            CompositeAdequacy.solve!(dispatchproblem, systemstate, system, t)
            CompositeAdequacy.foreach(recorder -> CompositeAdequacy.record!(
                        recorder, system, systemstate, dispatchproblem, s, t
                    ), recorders)

        end

        CompositeAdequacy.foreach(recorder -> CompositeAdequacy.reset!(recorder, s), recorders)

    end
    put!(results, recorders)
end


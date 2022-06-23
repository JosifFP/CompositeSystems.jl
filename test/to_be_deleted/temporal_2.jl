
using PRAS
using PRAS.ResourceAdequacy
import BenchmarkTools: @btime
include("testsystems/testsystems_pras.jl")

system =  TestSystems_pras.singlenode_a11
simspec = SequentialMonteCarlo(samples=1)
resultspecs = (Shortfall(),GeneratorAvailability())
threads = 1
sampleseeds = Channel{Int}(2)
results =  ResourceAdequacy.resultchannel(simspec, resultspecs, threads)
@async ResourceAdequacy.makeseeds(sampleseeds, simspec.nsamples)  # feed the sampleseeds channel with #N samples.
dispatchproblem = ResourceAdequacy.DispatchProblem(system)
systemstate = ResourceAdequacy.SystemState(system)
recorders = ResourceAdequacy.accumulator.(system, simspec, resultspecs)
rng = ResourceAdequacy.Philox4x((0, 0), 10)

s=1
ResourceAdequacy.seed!(rng, (simspec.seed, s))
ResourceAdequacy.initialize!(rng, systemstate, system)
systemstate
#SystemState(Bool[0, 1, 1, 1], [2, 2, 5, 5]

t=1
ResourceAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
ResourceAdequacy.solve!(dispatchproblem, systemstate, system, t)
ResourceAdequacy.foreach(recorder -> ResourceAdequacy.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
systemstate
recorders
#

t=2
ResourceAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
ResourceAdequacy.solve!(dispatchproblem, systemstate, system, t)
ResourceAdequacy.foreach(recorder -> ResourceAdequacy.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
systemstate
recorders
#

t=3
ResourceAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
ResourceAdequacy.solve!(dispatchproblem, systemstate, system, t)
ResourceAdequacy.foreach(recorder -> ResourceAdequacy.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
systemstate
recorders

#

t=4
ResourceAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
ResourceAdequacy.solve!(dispatchproblem, systemstate, system, t)
ResourceAdequacy.foreach(recorder -> ResourceAdequacy.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
systemstate
recorders
#

ResourceAdequacy.foreach(recorder -> ResourceAdequacy.reset!(recorder, s), recorders)
put!(results, recorders)
results


#----------------------------------------------------------------------------------------------------------------------------------

using PRAS
using PRAS.ResourceAdequacy
import BenchmarkTools: @btime
include("testsystems/testsystems_pras.jl")

system =  TestSystems_pras.singlenode_stor
simspec = SequentialMonteCarlo(samples=1)
resultspecs = (Shortfall(),GeneratorAvailability())
threads = 1
sampleseeds = Channel{Int}(2)
results =  ResourceAdequacy.resultchannel(simspec, resultspecs, threads)
@async ResourceAdequacy.makeseeds(sampleseeds, simspec.nsamples)  # feed the sampleseeds channel with #N samples.
dispatchproblem = ResourceAdequacy.DispatchProblem(system)
systemstate = ResourceAdequacy.SystemState(system)
recorders = ResourceAdequacy.accumulator.(system, simspec, resultspecs)
rng = ResourceAdequacy.Philox4x((0, 0), 10)

s=1
ResourceAdequacy.seed!(rng, (simspec.seed, s))
ResourceAdequacy.initialize!(rng, systemstate, system)
systemstate
#SystemState(Bool[0, 1, 1, 1], [2, 2, 5, 5]

t=1
ResourceAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
ResourceAdequacy.solve!(dispatchproblem, systemstate, system, t)
ResourceAdequacy.foreach(recorder -> ResourceAdequacy.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
systemstate
recorders
#

t=2
ResourceAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
ResourceAdequacy.solve!(dispatchproblem, systemstate, system, t)
ResourceAdequacy.foreach(recorder -> ResourceAdequacy.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
systemstate
recorders
#

t=3
ResourceAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
ResourceAdequacy.solve!(dispatchproblem, systemstate, system, t)
ResourceAdequacy.foreach(recorder -> ResourceAdequacy.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
systemstate
recorders

#

t=4
ResourceAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
ResourceAdequacy.solve!(dispatchproblem, systemstate, system, t)
ResourceAdequacy.foreach(recorder -> ResourceAdequacy.record!(recorder, system, systemstate, dispatchproblem, s, t), recorders)
systemstate
recorders
#

ResourceAdequacy.foreach(recorder -> ResourceAdequacy.reset!(recorder, s), recorders)
put!(results, recorders)
results


#----------------------------------------------------------------------------------------------------------------------------------

using PRATS
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime
include("testsystems/testsystems.jl")

system =  TestSystems.singlenode_stor
simspec = SequentialMonteCarlo(samples=1)
resultspecs = (Shortfall(),GeneratorAvailability())
threads = 1
sampleseeds = Channel{Int}(2)
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)  # feed the sampleseeds channel with #N samples.
dispatchproblem = CompositeAdequacy.DispatchProblem(system)
systemstate = CompositeAdequacy.SystemState(system)
recorders = CompositeAdequacy.accumulator.(system, simspec, resultspecs)
rng = CompositeAdequacy.Philox4x((0, 0), 10)

s=1
CompositeAdequacy.seed!(rng, (simspec.seed, s))
sequences = CompositeAdequacy.UpDownSequence(system)
CompositeAdequacy.initialize!(rng, systemstate, system, sequences)
sequences.Up_gens


t=1
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=2
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=3
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=4
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate
sequences.Up_gens

s=2
CompositeAdequacy.seed!(rng, (simspec.seed, s))
CompositeAdequacy.initialize!(rng, systemstate, system, sequences)
sequences.Up_gens

t=1
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=2
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=3
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=4
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate
sequences.Up_gens

s=3
CompositeAdequacy.seed!(rng, (simspec.seed, s))
CompositeAdequacy.initialize!(rng, systemstate, system, sequences)
sequences.Up_gens

t=1
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=2
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=3
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate

t=4
CompositeAdequacy.advance!(sequences, systemstate, dispatchproblem, system, t)
systemstate
sequences.Up_gens

s=4
CompositeAdequacy.seed!(rng, (simspec.seed, s))
CompositeAdequacy.initialize!(rng, systemstate, system, sequences)
sequences.Up_gens


#------------------------------------------------------------------------------------------------------------------------------------------------

using PRATS
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime
include("testsystems/testsystems.jl")

system =  TestSystems.singlenode_stor
sequences = CompositeAdequacy.UpDownSequence(system)

system =  TestSystems.singlenode_a_2
systemstate = CompositeAdequacy.SystemState(system)
sequences = CompositeAdequacy.UpDownSequence(system)

system =  TestSystems.singlenode_a
systemstate = CompositeAdequacy.SystemState(system)
sequences = CompositeAdequacy.UpDownSequence(system)


system =  TestSystems.singlenode_a_2
N=4


file = "test/temporal/testsystems/rts.hdf5"
sys = PRATS.SystemModel(file)


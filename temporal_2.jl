import Base.Broadcast: broadcastable

using PRATS
using Test
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime
include("test/testsystems.jl")
#using MinCostFlows
# import Random: AbstractRNG, GLOBAL_RNG, MersenneTwister, rand
# import OnlineStatsBase: EqualWeight, fit!, Mean, value, Variance
# import OnlineStats: Series
# MeanVariance = Series{ Number, Tuple{Mean{Float64, EqualWeight}, Variance{Float64, Float64, EqualWeight}}}
# abstract type ResultAccumulator{S<:SimulationSpec,R<:ResultSpec} end
# include("src/CompositeAdequacy/simulations/sequentialmontecarlo/SystemState.jl")
# include("src/CompositeAdequacy/simulations/sequentialmontecarlo/utils.jl")
# include("src/CompositeAdequacy/utils.jl")
# include("src/CompositeAdequacy/results/shortfall.jl")
# abstract type SimulationSpec end
# abstract type ResultSpec end
# abstract type ResultAccumulator{S<:SimulationSpec,R<:ResultSpec} end
# include("src/CompositeAdequacy/simulations/sequentialmontecarlo/SequentialMonteCarlo.jl")
# # include("src/CompositeAdequacy/results/results.jl")
# include("src/CompositeAdequacy/simulations/sequentialmontecarlo/result_availability.jl")

system =  TestSystems.singlenode_a
simspec = SequentialMonteCarlo(samples=3, seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())
sampleseeds = Channel{Int}(2)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)  # feed the sampleseeds channel with #N samples.

dispatchproblem = CompositeAdequacy.DispatchProblem(system)
systemstate = CompositeAdequacy.SystemState(system)
recorders = CompositeAdequacy.accumulator.(system, simspec, resultspecs)
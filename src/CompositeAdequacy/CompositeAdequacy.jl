@reexport module CompositeAdequacy

using MinCostFlows
using ..PRATSBase

import Base: -, broadcastable, getindex, merge!
#import Base.Threads: nthreads, @spawn
import Dates: DateTime, Period
import Decimals: Decimal, decimal
import Distributions: DiscreteNonParametric, probs, support, Exponential
import OnlineStatsBase: EqualWeight, fit!, Mean, value, Variance
import OnlineStats: Series
import Printf: @sprintf
import Random: AbstractRNG, rand, seed!
import Random123: Philox4x
import StatsBase: mean, std, stderror
import TimeZones: ZonedDateTime, @tz_str
import PowerModels
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)

export
    # CompositeAdequacy submoduleexport
    assess,
    # Metrics
    ReliabilityMetric, LOLE, EUE, val, stderror,
    # Simulation specifications
    SequentialMonteCarlo, NoContingencies,

    DispatchProblem, SystemState, accumulator, UpDownSequence,

    # Result specifications
    Shortfall, ShortfallSamples, Flow, FlowSamples,
    GeneratorAvailability, StorageAvailability, GeneratorStorageAvailability, BranchAvailability,

    # Convenience re-exports
    ZonedDateTime, @tz_str
#

abstract type ReliabilityMetric end
abstract type SimulationSpec end
abstract type ResultSpec end
abstract type ResultAccumulator{S<:SimulationSpec,R<:ResultSpec} end
abstract type Result{
    N, # Number of timesteps simulated
    L, # Length of each simulation timestep
    T <: Period, # Units of each simulation timestep
} end

MeanVariance = Series{ Number, Tuple{Mean{Float64, EqualWeight}, Variance{Float64, Float64, EqualWeight}}}

include("metrics.jl")
include("results/results.jl")
include("simulations/simulations.jl")
include("utils.jl")

end
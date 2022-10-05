@reexport module CompositeAdequacy

using ..PRATSBase
import Base: -, broadcastable, getindex, merge!
import Base.Threads: nthreads, @spawn
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
import JuMP, Ipopt, Juniper, HiGHS
import LinearAlgebra: qr
import JuMP: @variable, @constraint, @NLexpression, @NLconstraint, @objective, @expression, 
optimize!, Model, LOCALLY_SOLVED
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)

"Suppresses information and warning messages output"
function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.")
    Memento.setlevel!(_LOGGER, "error")
    Memento.setlevel!(Memento.getlogger(Ipopt), "error", recursive=false)
    Memento.setlevel!(Memento.getlogger(PRATSBase), "error", recursive=false)
    #Memento.setlevel!(Memento.getlogger(CompositeAdequacy), "error", recursive=false)
end

export
    # CompositeAdequacy submoduleexport
    assess,
    # Metrics
    ReliabilityMetric, LOLE, EUE, val, stderror,
    # Simulation specifications
    SequentialMonteCarlo, NoContingencies,

    SystemState, accumulator,

    # Result specifications
    Shortfall, ShortfallSamples, Flow, FlowTotal, #Report,

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

include("Optimizer/base.jl")
include("Optimizer/utils.jl")
include("Optimizer/variables.jl")
include("Optimizer/constraints.jl")
include("Optimizer/Optimizer.jl")
include("Optimizer/solution.jl")

include("metrics.jl")
include("results/results.jl")
include("simulations/simulations.jl")
include("utils.jl")

end
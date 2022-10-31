@reexport module CompositeAdequacy

using ..PRATSBase
import Base: -, getindex, merge!
#import Base.Threads: nthreads, @spawn
import Dates: DateTime, Period
import Decimals: Decimal, decimal
#import Distributions: DiscreteNonParametric, probs, support, Exponential
import OnlineStatsBase: EqualWeight, fit!, Mean, value, Variance
import OnlineStats: Series
import Printf: @sprintf
import Random: AbstractRNG, rand, seed!
import Random123: Philox4x
import StatsBase: mean, std, stderror
import StaticArrays: StaticArrays, SVector, SMatrix, SArray
import TimeZones: ZonedDateTime, @tz_str
import LinearAlgebra: qr, pinv
import MathOptInterface
import Ipopt, Juniper, HiGHS
import Memento
import JuMP: @variable, @constraint, @objective, @expression, JuMP, fix, 
    optimize!, Model, direct_model, result_count, optimizer_with_attributes,
    termination_status, isempty, empty!, AbstractModel, VariableRef, 
    GenericAffExpr, GenericQuadExpr, NonlinearExpression, ConstraintRef, 
    dual, UpperBoundRef, LowerBoundRef, upper_bound, lower_bound, 
    has_upper_bound, has_lower_bound, set_lower_bound, set_upper_bound,
    LOCALLY_SOLVED, OPTIMAL, INFEASIBLE, LOCALLY_INFEASIBLE, ITERATION_LIMIT, 
    TIME_LIMIT, OPTIMIZE_NOT_CALLED, set_silent, set_time_limit_sec

import JuMP.Containers: DenseAxisArray

"Suppresses information and warning messages output"
function silence()
    Memento.setlevel!(Memento.getlogger(Ipopt), "error", recursive=false)
    Memento.setlevel!(Memento.getlogger(Juniper), "error", recursive=false)
    Memento.setlevel!(Memento.getlogger(PRATSBase), "error", recursive=false)
end

export
    # CompositeAdequacy submoduleexport
    assess, @def,
    
    # Metrics
    ReliabilityMetric, LOLE, EUE, val, stderror,

    #Abstract PowerModel Formulations
    AbstractPowerModel, AbstractDCPowerModel, AbstractACPowerModel,
    AbstractDCPModel, AbstractDCMPPModel, AbstractNFAModel,

    #optimizationcontainers
    OptimizationContainer, Topology, Variables, Cache,

    # Simulation specification
    SequentialMCS, NonSequentialMCS, PreContingencies, Settings,
    SystemStates, accumulator,

    # Result specifications
    Shortfall, ShortfallSamples,

    # Convenience re-exports
    ZonedDateTime, @tz_str
#

include("statistics.jl")
include("types.jl")
include("optimizationcontainers.jl")
include("systemstates.jl")
include("results/results.jl")
include("simulations/simulations.jl")
include("utils.jl")

end
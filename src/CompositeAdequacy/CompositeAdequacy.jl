@reexport module CompositeAdequacy

    using ..BaseModule
    using ..OPF

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
    import TimeZones: ZonedDateTime, @tz_str
    import LinearAlgebra: qr

    export
        # CompositeAdequacy submoduleexport
        assess, SimulationSpec,
        
        # Metrics
        ReliabilityMetric, LOLE, EUE, val, stderror,

        # Simulation specification
        SequentialMCS, NonSequentialMCS, PreContingencies, accumulator,

        # Result specifications
        Shortfall, ShortfallSamples,

        #utils
        makeidxlist, 

        # Convenience re-exports
        ZonedDateTime, @tz_str
    #

    include("statistics.jl")
    include("types.jl")
    include("results/results.jl")
    include("simulations/simulations.jl")
    include("utils.jl")

end
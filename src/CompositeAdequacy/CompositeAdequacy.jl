@reexport module CompositeAdequacy

    using ..BaseModule
    using ..OPF

    import Base: -, getindex, merge!
    import Dates: Dates, DateTime, Period
    import Decimals: Decimal, decimal
    import OnlineStatsBase: EqualWeight, fit!, Mean, value, Variance
    import OnlineStats: Series
    import Printf: @sprintf
    import Random: AbstractRNG, rand, seed!
    import Random123: Philox4x
    import StatsBase: mean, std, stderror
    import TimeZones: ZonedDateTime
    import LinearAlgebra: qr
    import XLSX: rename!, addsheet!, openxlsx

    export
        # CompositeAdequacy submoduleexport
        assess, SimulationSpec,
        
        # Metrics
        ReliabilityMetric, EDLC, EENS, val, stderror,

        # Simulation specification
        SequentialMCS, accumulator,

        # Result specifications
        Shortfall, ShortfallSamples,
        GeneratorAvailability, StorageAvailability, GeneratorStorageAvailability, 
        BranchAvailability, ShuntAvailability, BusAvailability,
        Utilization, UtilizationSamples,

        #utils
        makeidxlist, print_results

        # Convenience re-exports
        ZonedDateTime
    #
    include("statistics.jl")
    include("types.jl")
    include("results/results.jl")
    include("simulations/simulations.jl")
    include("utils.jl")
end
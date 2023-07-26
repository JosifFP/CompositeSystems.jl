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
    import Distributions: ccdf, Normal
    import Base: minimum, maximum, extrema
    import Distributed: Distributed, @distributed, RemoteChannel
    import JuMP
    import Gurobi

    const GRB_ENV = Ref{Gurobi.Env}()

    function __init__()
        GRB_ENV[] = Gurobi.Env()
        return
    end

    export
        # CompositeAdequacy submoduleexport
        assess, assess_single, SimulationSpec,
        
        # Metrics
        ReliabilityMetric, EDLC, EENS, SI, ELCC, MeanEstimate, val, stderror,

        # Simulation specification
        SequentialMCS, accumulator,

        # Result specifications
        Shortfall, ShortfallSamples,
        GeneratorAvailability, StorageAvailability, 
        BranchAvailability, ShuntAvailability,
        Utilization, UtilizationSamples,

        #utils
        print_results, copy_load, update_load!, 
        resultremotechannel, finalize

        # Convenience re-exports
        ZonedDateTime
    #
    include("statistics.jl")
    include("types.jl")
    include("results/results.jl")
    include("results/CapacityCreditResult.jl")
    include("results/ELCC.jl")
    include("simulations/simulations.jl")
    include("utils.jl")
end
abstract type SimulationSpec end
abstract type Tests <: SimulationSpec end
abstract type ResultSpec end
abstract type ResultAccumulator{S<:SimulationSpec,R<:ResultSpec} end
abstract type Result{
    N, # Number of timesteps simulated
    L, # Length of each simulation timestep
    T <: Period, # Units of each simulation timestep
} end

"Definition of SequentialMCS method"
struct SequentialMCS <: SimulationSpec
    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool

    function SequentialMCS(;
        samples::Int=1_000,
        seed::Int=rand(UInt64),
        verbose::Bool=false,
        threaded::Bool=true
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        workers = Distributed.nprocs() > 1 ? Distributed.nprocs() : 1
        _, remainder = divrem(samples, workers)
        remainder != 0 && throw(DomainError("The ratio of #samples to #workers must be an integer number"))

        new(samples, UInt64(seed), verbose, threaded)
    end

end
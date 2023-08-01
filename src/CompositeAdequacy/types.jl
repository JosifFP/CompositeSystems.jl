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
    count_samples::Bool
    include_master::Bool

    function SequentialMCS(;
        samples::Int=1_000,
        seed::Int=rand(UInt64),
        verbose::Bool=false,
        threaded::Bool=true,
        count_samples::Bool=false,
        include_master::Bool=false
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        if include_master
            workers = Distributed.nprocs() > 1 ? Distributed.nprocs() : 1
        else
            workers = Distributed.nprocs() > 1 ? Distributed.nprocs()-1 : 1
        end

        _, remainder = divrem(samples, workers)
        remainder != 0 && throw(DomainError("The ratio of #samples to workers +- master must be an integer number"))

        new(samples, UInt64(seed), verbose, threaded, count_samples, include_master)
    end
end
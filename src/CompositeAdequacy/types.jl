abstract type SimulationSpec end
abstract type Tests <: SimulationSpec end
abstract type ResultSpec end
abstract type ResultAccumulator{S<:SimulationSpec,R<:ResultSpec} end
abstract type Result{
    N, # Number of timesteps simulated
    L, # Length of each simulation timestep
    T <: Period, # Units of each simulation timestep
} end

"""
    SequentialMCS <: SimulationSpec

A structure defining the Sequential Monte Carlo Simulation (SequentialMCS) method.

# Fields
- `nsamples::Int`: Number of samples for the Monte Carlo Simulation.
- `seed::UInt64`: Random seed for reproducibility.
- `verbose::Bool`: Flag to control verbose output.
- `threaded::Bool`: Flag to control if the simulation uses multi-threading.
- `include_master::Bool`: Flag to determine if the master process should be included in the simulation.

# Constructor
The constructor ensures that the provided samples are positive, the seed is non-negative,
and the ratio of samples to available processors is integer.

"""
struct SequentialMCS <: SimulationSpec
    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool
    include_master::Bool

    function SequentialMCS(;
        samples::Int=1_000,
        seed::Int=rand(UInt64),
        verbose::Bool=false,
        threaded::Bool=true,
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

        new(samples, UInt64(seed), verbose, threaded, include_master)
    end
end
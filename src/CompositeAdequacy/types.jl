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
    nworkers::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool
    distributed::Bool

    function SequentialMCS(;
        samples::Int=1_000,
        seed::Int=rand(UInt64),
        verbose::Bool=false,
        threaded::Bool=true,
        distributed::Bool=false
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        Distributed.nprocs() > 1 ? workers = Distributed.nprocs() - 1 : workers = 1 # Number of workers excluding the master process
            
        if workers > 1 && distributed
            isinteger(samples/workers) ? distributed = true : distributed = false
            !distributed && throw(DomainError("Change number of samples or workers to equally distribute samples between workers"))
            @info("Distributed computing in Julia distributes the workload across the Cluster's nodes and cores")
        else
            distributed && @info("Parameter 'distributed' has been changed to 'false' to use a single worker")
            if distributed distributed = false end
        end

        new(samples, workers, UInt64(seed), verbose, threaded, distributed)
    end

end
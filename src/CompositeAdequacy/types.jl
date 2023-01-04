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
        threaded::Bool=true,
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        new(samples, UInt64(seed), verbose, threaded)

    end

end

"Definition of NonSequentialMCS method"
struct NonSequentialMCS <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool

    function NonSequentialMCS(;
        samples::Int=1_000,
        seed::Int=rand(UInt64),
        verbose::Bool=false,
        threaded::Bool=true
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        new(samples, UInt64(seed), verbose, threaded)

    end

end

"Definition of Pre-Contingencies simulation method"
struct PreContingencies <: SimulationSpec
    
    verbose::Bool
    threaded::Bool

    function PreContingencies(;
        verbose::Bool=false,
        threaded::Bool=false
    )
        new(verbose, threaded)

    end

end


# ""
# struct Settings <: SimulationSpec

#     optimizer::MOI.OptimizerWithAttributes
#     file::String
#     modelmode::JuMP.ModelMode
#     powermodel::Type{<:AbstractPowerModel}

#     function Settings(
#         optimizer::MOI.OptimizerWithAttributes;
#         file::String="",
#         modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
#         powermodel::String="AbstractDCMPPModel"
#         )

#         abstractpm = type(powermodel)

#         new(optimizer, file, modelmode, abstractpm)
#     end

# end
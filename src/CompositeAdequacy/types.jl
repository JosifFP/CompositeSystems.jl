abstract type SimulationSpec end
abstract type Tests <: SimulationSpec end
abstract type ResultSpec end
abstract type ResultAccumulator{S<:SimulationSpec,R<:ResultSpec} end
abstract type Result{
    N, # Number of timesteps simulated
    L, # Length of each simulation timestep
    T <: Period, # Units of each simulation timestep
} end

abstract type OptimizationContainer end

"Types of optimization"
abstract type AbstractPowerModel end
abstract type AbstractDCPowerModel <: AbstractPowerModel end
abstract type AbstractACPowerModel <: AbstractPowerModel end
abstract type AbstractDCMPPModel <: AbstractDCPowerModel end
abstract type AbstractDCPModel <: AbstractDCPowerModel end
abstract type AbstractNFAModel <: AbstractDCPowerModel end
#AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
#AbstractActivePowerModel = Union{AbstractDCPModel, DCPPowerModel, AbstractDCMPPModel, AbstractNFAModel, NFAPowerModel,DCPLLPowerModel}
#AbstractWModels = Union{AbstractWRModels, AbstractBFModel}


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

""
struct Settings <: SimulationSpec

    optimizer::MathOptInterface.OptimizerWithAttributes
    modelmode::JuMP.ModelMode
    powermodel::Type{<:AbstractPowerModel}

    function Settings(
        optimizer::MathOptInterface.OptimizerWithAttributes;
        modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        powermodel::Type{<:AbstractPowerModel}=AbstractDCMPPModel
        )

        @assert powermodel <: AbstractPowerModel

        new(optimizer, modelmode, powermodel)
    end

end

""
function JumpModel(modelmode::JuMP.ModelMode, optimizer)
    if modelmode == JuMP.AUTOMATIC
        jumpmodel = Model(optimizer; add_bridges = false)
        JuMP.set_silent(jumpmodel)
    elseif modelmode == JuMP.DIRECT
        @warn("Direct Mode is unsafe")
        jumpmodel = direct_model(optimizer)
    else
        @warn("Manual Mode not supported")
    end

    return jumpmodel
end
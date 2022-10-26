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


""
function set_optimizer_default()

    nl_solver = optimizer_with_attributes(
        Ipopt.Optimizer, 
        "tol"=>1e-3, 
        "acceptable_tol"=>1e-2, 
        "max_cpu_time"=>1e+2,
        "constr_viol_tol"=>0.01, 
        "print_level"=>0
    )

    optimizer = optimizer_with_attributes(
        Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "log_levels"=>[], "processors"=>1)

    return nl_solver
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

""
struct Settings <: SimulationSpec

    powermodel::Type{<:AbstractPowerModel}
    modelmode::JuMP.ModelMode
    optimizer::MathOptInterface.OptimizerWithAttributes

    function Settings(;
        powermodel::Type{<:AbstractPowerModel}=AbstractDCMPPModel,
        modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        optimizer=set_optimizer_default()
        )

        @assert powermodel <: AbstractPowerModel

        new(powermodel, modelmode, optimizer)
    end

end

"Definition of SequentialMCS method"
struct SequentialMCS <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool
    settings::Settings

    function SequentialMCS(;
        samples::Int=1_000,
        seed::Int=rand(UInt64),
        verbose::Bool=false,
        threaded::Bool=true,
        settings=Settings()
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        new(samples, UInt64(seed), verbose, threaded, settings)

    end

end

"Definition of NonSequentialMCS method"
struct NonSequentialMCS <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool
    settings::Settings

    function NonSequentialMCS(;
        samples::Int=1_000,
        seed::Int=rand(UInt64),
        verbose::Bool=false,
        threaded::Bool=true,
        settings=Settings()
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        new(samples, UInt64(seed), verbose, threaded, settings)

    end

end

"Definition of Pre-Contingencies simulation method"
struct PreContingencies <: SimulationSpec
    
    verbose::Bool
    threaded::Bool
    settings::Settings

    function PreContingencies(;
        verbose::Bool=false,
        threaded::Bool=true,
        settings=Settings()
    )
        new(verbose, threaded, settings)

    end

end
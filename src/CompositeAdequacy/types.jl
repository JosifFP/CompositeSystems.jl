MeanVariance = Series{ Number, Tuple{Mean{Float64, EqualWeight}, Variance{Float64, Float64, EqualWeight}}}
meanvariance() = Series(Mean(), Variance())

abstract type ReliabilityMetric end
abstract type SimulationSpec end
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
    optimizer::Union{Nothing, MathOptInterface.OptimizerWithAttributes}

    function SequentialMCS(;
        samples::Int=1_000, seed::Int=rand(UInt64),
        verbose::Bool=false, threaded::Bool=true, optimizer=nothing
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        if optimizer === nothing
            nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2, 
                "constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
            optimizer = optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])
            #Model(optimizer; add_bridges = false) #direct_model(optimizer)
        end

        new(samples, UInt64(seed), verbose, threaded, optimizer)

    end

end

"Definition of NonSequentialMCS method"
struct NonSequentialMCS <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool
    optimizer::Union{Nothing, MathOptInterface.OptimizerWithAttributes}

    function NonSequentialMCS(;
        samples::Int=1_000, seed::Int=rand(UInt64),
        verbose::Bool=false, threaded::Bool=true, optimizer=nothing
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))

        if optimizer === nothing
            nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2, 
                "constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
            optimizer = optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])
            #Model(optimizer; add_bridges = false) #direct_model(optimizer)
        end

        new(samples, UInt64(seed), verbose, threaded, optimizer)

    end

end

"root of the power model formulation type hierarchy"
abstract type AbstractPowerModel end
abstract type AbstractDCPowerModel <: AbstractPowerModel end
abstract type AbstractACPowerModel <: AbstractPowerModel end
#AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
#AbstractActivePowerModel = Union{AbstractDCPModel, DCPPowerModel, AbstractDCMPPModel, AbstractNFAModel, NFAPowerModel,DCPLLPowerModel}
#AbstractWModels = Union{AbstractWRModels, AbstractBFModel}
abstract type  DCOPF <: AbstractDCPowerModel end
abstract type  Transportation <: AbstractDCPowerModel end

"Definition of States"
abstract type AbstractState end

struct GroupStates <: AbstractState
    system::Vector{Bool}
    loads::Union{Nothing, Vector{Bool}}
    branches::Union{Nothing, Vector{Bool}}
    shunts::Union{Nothing, Vector{Bool}}
    generators::Union{Nothing, Vector{Bool}}
    storages::Union{Nothing, Vector{Bool}}
    generatorstorages::Union{Nothing, Vector{Bool}}
end

struct SystemStates <: AbstractState

    loads::Array{Bool}
    branches::Array{Bool}
    shunts::Array{Bool}
    generators::Array{Bool}
    storages::Array{Bool}
    generatorstorages::Array{Bool}

    loads_nexttransition::Union{Nothing, Vector{Int}}
    branches_nexttransition::Union{Nothing, Vector{Int}}
    shunts_nexttransition::Union{Nothing, Vector{Int}}
    generators_nexttransition::Union{Nothing, Vector{Int}}
    storages_nexttransition::Union{Nothing, Vector{Int}}
    generatorstorages_nexttransition::Union{Nothing, Vector{Int}}

    storages_energy::Array{Float16}
    generatorstorages_energy::Array{Float16}

    groupstates::GroupStates

end

"root of the power formulation type hierarchy"
abstract type AbstractPowerModel end

"Topology"
struct Topology

    branches_available::Vector{Bool}
    branches_pasttransition::Vector{Bool}
    interfaces_available::Vector{Bool}
    interfaces_pasttransition::Vector{Bool}
    generators_available::Vector{Bool}
    generators_pasttransition::Vector{Bool}
    storages_available::Vector{Bool}
    storages_pasttransition::Vector{Bool}
    buses_available::Vector{Bool}
    buses_pasttransition::Vector{Bool}
    loads_available::Vector{Bool}
    loads_pasttransition::Vector{Bool}
    shunts_available::Vector{Bool}
    shunts_pasttransition::Vector{Bool}

    buses_generators_available::Dict{Int, Vector{Int}}
    buses_storages_available::Dict{Int, Vector{Int}}
    buses_loads_base::Dict{Int, Vector{Int}}
    buses_loads_available::Dict{Int, Vector{Int}}
    buses_shunts_available::Dict{Int, Vector{Int}}

    arcs_from_base::Vector{Tuple{Int, Int, Int}}
    arcs_to_base::Vector{Tuple{Int, Int, Int}}
    arcs_from_available::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs_to_available::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs_available::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    busarcs_available::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs_available::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}
    delta_bounds::Vector{Float64}
    ref_buses::Vector{Int}

    branches_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}

    busshortfall_pd::Vector{Float64}
    busshortfall_qd::Vector{Float64}
    branchflow_from::Vector{Float64}
    branchflow_to::Vector{Float64}
    stored_energy::Vector{Float64}
    failed_systemstate::Vector{Bool}
end

"a macro for adding the base AbstractPowerModels fields to a type definition"
_IM.@def pm_fields begin
    model::AbstractModel
    topology::Topology
    var::Dict{Symbol, AbstractArray}
    con::Dict{Symbol, AbstractArray}
end

"Types of optimization"
abstract type AbstractDCPowerModel <: AbstractPowerModel end

"""AbstractDCPModel: Linearized 'DC' power flow Model with polar voltage variables.
    This model is a basic linear active-power-only approximation, which uses branch 
    susceptance values  br_b = -br_x / (br_x^2 + br_x^2) for determining the network phase angles. 
    Furthermore, transformer parameters such as tap ratios and phase shifts are 
    not considered as part of this model.
"""
abstract type AbstractDCPModel <: AbstractDCPowerModel end
struct DCPPowerModel <: AbstractDCPModel @pm_fields end

"""AbstractDCMPPModel: Linearized 'DC' power flow model with polar voltage variables.
    Similar to the DCPPowerModel with the following changes:
        It uses branch susceptance values br_b = -1 / br_x for determining the network phase angles.
        Transformer parameters such as tap ratios and phase shifts are considered.
"""
abstract type AbstractDCMPPModel <: AbstractDCPModel end
struct DCMPPowerModel <: AbstractDCMPPModel @pm_fields end

"""
AbstractNFAModel: The an active power only network flow approximation, 
    also known as the transportation model.
"""
abstract type AbstractNFAModel <: AbstractDCPModel end
struct NFAPowerModel <: AbstractNFAModel @pm_fields end

"""
AbstractLPACModel: The LPAC Cold-Start AC Power Flow Approximation.
    The original publication suggests to use polyhedral outer approximations for 
    the cosine and line thermal lit constraints. Given the recent improvements 
    in MIQCQP solvers, this implementation uses quadratic functions for those constraints.
    
    @article{doi:10.1287/ijoc.2014.0594,
        author = {Coffrin, Carleton and Van Hentenryck, Pascal},
        title = {A Linear-Programming Approximation of AC Power Flows},
        journal = {INFORMS Journal on Computing},
        volume = {26},
        number = {4},
        pages = {718-734},
        year = {2014},
        doi = {10.1287/ijoc.2014.0594},
        eprint = {https://doi.org/10.1287/ijoc.2014.0594}
    }
"""
abstract type AbstractLPACModel <: AbstractPowerModel end
struct LPACCPowerModel <: AbstractLPACModel @pm_fields end

AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
AbstractPolarModels = Union{AbstractLPACModel, AbstractDCPowerModel}

""
mutable struct Settings

    optimizer::MOI.OptimizerWithAttributes
    optimizer_name::String
    jump_modelmode::JuMP.ModelMode
    powermodel_formulation::Type
    select_largest_splitnetwork::Bool
    deactivate_isolated_bus_gens_stors::Bool
    set_string_names_on_creation::Bool

    function Settings(;
        optimizer::MOI.OptimizerWithAttributes,
        jump_modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        powermodel_formulation::Type=OPF.DCPPowerModel,
        select_largest_splitnetwork::Bool=false,
        deactivate_isolated_bus_gens_stors::Bool=true,
        set_string_names_on_creation::Bool=false,
        )

        optimizer === nothing && throw(DomainError("Solver/Optimizer not attached"))
        optimizer_name = MathOptInterface.get(JuMP.Model(optimizer), MathOptInterface.SolverName())

        new(optimizer, optimizer_name, jump_modelmode, powermodel_formulation, 
            select_largest_splitnetwork, deactivate_isolated_bus_gens_stors,
            set_string_names_on_creation)
    end
end

Base.:(==)(x::T, y::T) where {T <: Settings} =
    x.optimizer == y.optimizer &&
    x.optimizer_name == y.optimizer_name &&
    x.jump_modelmode == y.jump_modelmode &&
    x.powermodel_formulation == y.powermodel_formulation &&
    x.select_largest_splitnetwork == y.select_largest_splitnetwork &&
    x.deactivate_isolated_bus_gens_stors == y.deactivate_isolated_bus_gens_stors &&
    x.set_string_names_on_creation == y.set_string_names_on_creation


topology(pm::AbstractPowerModel, subfield::Symbol) = getfield(getfield(pm, :topology), subfield)
topology(pm::AbstractPowerModel, subfield::Symbol, indx::Int) = getfield(getfield(pm, :topology), subfield)[indx]
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol) = getfield(getfield(getfield(pm, :topology), field), subfield)
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol, nw::Int) = getindex(getfield(getfield(getfield(pm, :topology), field), subfield), nw)


var(pm::AbstractPowerModel) = getfield(pm, :var)
var(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(pm, :var), field)
var(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(pm, :var), field), nw)
var(pm::AbstractPowerModel, field::Symbol, ::Colon) = getindex(getindex(getfield(pm, :var), field), 1)

con(pm::AbstractPowerModel) = getfield(pm, :con)
con(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(pm, :con), field)
con(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(pm, :con), field), nw)

BaseModule.field(topology::Topology, field::Symbol) = getfield(topology, field)
BaseModule.field(topology::Topology, field::Symbol, subfield::Symbol) = getfield(getfield(topology, field), subfield)
BaseModule.field(settings::Settings, field::Symbol) = getfield(settings, field)

""
function Base.getproperty(e::AbstractPowerModel, s::Symbol) 
    if s === :model 
        getfield(e, :model)::JuMP.Model
    elseif s===:topology 
        getfield(e, :topology)::Topology
    elseif s === :var
        getfield(e, :var)
    elseif s === :con
        getfield(e, :con) 
    elseif s === :sol
        getfield(e, :sol) 
    end
end

""
function Base.getproperty(e::Settings, s::Symbol) 
    if s === :optimizer 
        getfield(e, :optimizer)::MOI.OptimizerWithAttributes
    elseif s === :optimizer_name
        getfield(e, :optimizer_name)::String
    elseif s === :jump_modelmode 
        getfield(e, :jump_modelmode)::JuMP.ModelMode
    elseif s === :powermodel_formulation
        getfield(e, :powermodel_formulation)::Type
    elseif s === :select_largest_splitnetwork
        getfield(e, :select_largest_splitnetwork)::Bool
    elseif s === :deactivate_isolated_bus_gens_stors
        getfield(e, :deactivate_isolated_bus_gens_stors)::Bool  
    elseif s === :set_string_names_on_creation
        getfield(e, :set_string_names_on_creation)::Bool
    else
        @error("Configuration $(s) not supported")
    end
end

"root of the power formulation type hierarchy"
abstract type AbstractPowerModel end

"Topology"
struct Topology

    branches_available::Vector{Bool}
    branches_pasttransition::Vector{Bool}
    commonbranches_available::Vector{Bool}
    commonbranches_pasttransition::Vector{Bool}
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

    buses_curtailed_pd::Vector{Float64}
    buses_curtailed_qd::Vector{Float64}
    branches_flow_from::Vector{Float64}
    branches_flow_to::Vector{Float64}
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

abstract type AbstractDCPModel <: AbstractDCPowerModel end
struct DCPPowerModel <: AbstractDCPModel @pm_fields end

abstract type AbstractDCMPPModel <: AbstractDCPModel end
struct DCMPPowerModel <: AbstractDCMPPModel @pm_fields end

abstract type AbstractNFAModel <: AbstractDCPModel end
struct NFAPowerModel <: AbstractNFAModel @pm_fields end

abstract type AbstractLPACModel <: AbstractPowerModel end
struct LPACCPowerModel <: AbstractLPACModel @pm_fields end

AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
AbstractPolarModels = Union{AbstractLPACModel, AbstractDCPowerModel}

""
mutable struct Settings

    gurobi_env::Union{Gurobi.Env, Nothing}
    optimizer::Union{MOI.OptimizerWithAttributes, Nothing}
    jump_modelmode::JuMP.ModelMode
    powermodel_formulation::Type
    select_largest_splitnetwork::Bool
    deactivate_isolated_bus_gens_stors::Bool
    set_string_names_on_creation::Bool

    function Settings(;
        gurobi_env::Union{Gurobi.Env, Nothing} = nothing,
        optimizer::Union{MOI.OptimizerWithAttributes, Nothing} = nothing,
        jump_modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        powermodel_formulation::Type=OPF.DCPPowerModel,
        select_largest_splitnetwork::Bool=false,
        deactivate_isolated_bus_gens_stors::Bool=true,
        set_string_names_on_creation::Bool=false,
        )
        new(gurobi_env, optimizer, jump_modelmode, powermodel_formulation, 
        select_largest_splitnetwork, deactivate_isolated_bus_gens_stors,
        set_string_names_on_creation)
    end
end

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
    if s === :gurobi_env 
        getfield(e, :gurobi_env)::Union{Gurobi.Env, Nothing}
    elseif s === :optimizer 
        getfield(e, :optimizer)::Union{MOI.OptimizerWithAttributes, Nothing}
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
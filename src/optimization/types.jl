"Topology"
struct Topology

    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    branches_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    bus_loads_init::Dict{Int, Vector{Int}}
    bus_loads::Dict{Int, Vector{Int}}
    bus_shunts::Dict{Int, Vector{Int}}
    bus_generators::Dict{Int, Vector{Int}}
    bus_storages::Dict{Int, Vector{Int}}

    arcs_from::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs_to::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    busarcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}
    delta_bounds::Vector{Float64}

    function Topology(system::SystemModel{N}) where {N}

        key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))
        buses_idxs = makeidxlist(key_buses, length(system.buses))

        key_loads = filter(i->field(system, :loads, :status)[i], field(system, :loads, :keys))
        loads_idxs = makeidxlist(key_loads, length(system.loads))
        bus_loads_init = Dict((i, Int[]) for i in key_buses)
        bus_asset!(bus_loads_init, key_loads, field(system, :loads, :buses))
        bus_loads = deepcopy(bus_loads_init)

        key_shunts = filter(i->field(system, :shunts, :status)[i], field(system, :shunts, :keys))
        shunts_idxs = makeidxlist(key_shunts, length(system.shunts))
        bus_shunts = Dict((i, Int[]) for i in key_buses)
        bus_asset!(bus_shunts, key_shunts, field(system, :shunts, :buses))

        key_generators = filter(i->field(system, :generators, :status)[i], field(system, :generators, :keys))
        generators_idxs = makeidxlist(key_generators, length(system.generators))
        bus_generators = Dict((i, Int[]) for i in key_buses)
        bus_asset!(bus_generators, key_generators, field(system, :generators, :buses))

        key_storages = filter(i->field(system, :storages, :status)[i], field(system, :storages, :keys))
        storages_idxs = makeidxlist(key_storages, length(system.storages))
        bus_storages = Dict((i, Int[]) for i in key_buses)
        bus_asset!(bus_storages, key_storages, field(system, :storages, :buses))

        key_branches = filter(i->field(system, :branches, :status)[i], field(system, :branches, :keys))
        branches_idxs = makeidxlist(key_branches, length(system.branches))

        arcs_from = deepcopy(system.arcs_from)
        arcs_to = deepcopy(system.arcs_to)
        arcs = [arcs_from; arcs_to]
        buspairs = deepcopy(system.buspairs)

        busarcs = Dict((i, Tuple{Int, Int, Int}[]) for i in eachindex(key_buses))
        bus_asset!(busarcs, arcs)

        vad_min,vad_max = calc_theta_delta_bounds(key_buses, key_branches, system.branches)
        delta_bounds = [vad_min,vad_max]

        return new(
            buses_idxs::Vector{UnitRange{Int}}, loads_idxs::Vector{UnitRange{Int}}, 
            branches_idxs::Vector{UnitRange{Int}}, shunts_idxs::Vector{UnitRange{Int}}, 
            generators_idxs::Vector{UnitRange{Int}}, storages_idxs::Vector{UnitRange{Int}}, 
            bus_loads_init, bus_loads, bus_shunts, bus_generators, bus_storages, 
            arcs_from, arcs_to, arcs, busarcs, buspairs, delta_bounds)
    end
end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.bus_loads_init == y.bus_loads_init &&
    x.bus_loads == y.bus_loads &&
    x.bus_shunts == y.bus_shunts &&
    x.bus_generators == y.bus_generators &&
    x.bus_storages == y.bus_storages &&
    x.busarcs == y.busarcs &&
    x.arcs_from == y.arcs_from &&
    x.arcs_to == y.arcs_to &&
    x.arcs == y.arcs &&
    x.buspairs == y.buspairs &&
    x.delta_bounds == y.delta_bounds

"a macro for adding the base AbstractPowerModels fields to a type definition"
_IM.@def pm_fields begin
    model::AbstractModel
    topology::Topology
    var::Dict{Symbol, AbstractArray}
    con::Dict{Symbol, AbstractArray}
end

"root of the power formulation type hierarchy"
abstract type AbstractPowerModel end

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

    optimizer::MOI.OptimizerWithAttributes
    jump_modelmode::JuMP.ModelMode
    powermodel_formulation::Type
    select_largest_splitnetwork::Bool
    deactivate_isolated_bus_gens_stors::Bool
    min_generators_off::Int
    set_string_names_on_creation::Bool
    count_samples::Bool
    record_branch_flow::Bool

    function Settings(
        optimizer::MOI.OptimizerWithAttributes;
        jump_modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        powermodel_formulation::Type=OPF.DCPPowerModel,
        select_largest_splitnetwork::Bool=false,
        deactivate_isolated_bus_gens_stors::Bool=true,
        min_generators_off::Int=1,
        set_string_names_on_creation::Bool=false,
        count_samples::Bool=false,
        record_branch_flow::Bool=false
        )
        new(optimizer, jump_modelmode, powermodel_formulation, 
        select_largest_splitnetwork, deactivate_isolated_bus_gens_stors, min_generators_off, 
        set_string_names_on_creation, count_samples, record_branch_flow)
    end
end
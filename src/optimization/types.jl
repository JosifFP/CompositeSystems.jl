"Topology"
struct Topology

    branches_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}

    buses_generators_base::Dict{Int, Vector{Int}}
    buses_generators_available::Dict{Int, Vector{Int}}
    buses_storages_base::Dict{Int, Vector{Int}}
    buses_storages_available::Dict{Int, Vector{Int}}
    buses_loads_base::Dict{Int, Vector{Int}}
    buses_loads_available::Dict{Int, Vector{Int}}
    buses_shunts_base::Dict{Int, Vector{Int}}
    buses_shunts_available::Dict{Int, Vector{Int}}

    buses_curtailed_pd::Vector{Float64}
    buses_curtailed_qd::Vector{Float64}
    branches_flow_from::Vector{Float64}
    branches_flow_to::Vector{Float64}
    stored_energy::Vector{Float64}

    arcs_from::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs_to::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    busarcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}
    delta_bounds::Vector{Float64}

    function Topology(system::SystemModel{N}) where {N}

        nbranches = length(system.branches)
        ngens = length(system.generators)
        nstors = length(system.storages)
        nbuses = length(system.buses)
        nloads = length(system.loads)
        nshunts = length(system.loads)

        key_branches = filter(i->field(system, :branches, :status)[i], field(system, :branches, :keys))
        branches_idxs = makeidxlist(key_branches, nbranches)

        key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))
        buses_idxs = makeidxlist(key_buses, nbuses)

        key_generators = filter(i->field(system, :generators, :status)[i], field(system, :generators, :keys))
        generators_idxs = makeidxlist(key_generators, ngens)
        buses_generators_base = Dict((i, Int[]) for i in key_buses)
        buses_asset!(buses_generators_base, key_generators, field(system, :generators, :buses))
        buses_generators_available = deepcopy(buses_generators_base)

        key_storages = filter(i->field(system, :storages, :status)[i], field(system, :storages, :keys))
        storages_idxs = makeidxlist(key_storages, nstors)
        buses_storages_base = Dict((i, Int[]) for i in key_buses)
        buses_asset!(buses_storages_base, key_storages, field(system, :storages, :buses))
        buses_storages_available = deepcopy(buses_storages_base)

        key_loads = filter(i->field(system, :loads, :status)[i], field(system, :loads, :keys))
        loads_idxs = makeidxlist(key_loads, nloads)
        buses_loads_base = Dict((i, Int[]) for i in key_buses)
        buses_asset!(buses_loads_base, key_loads, field(system, :loads, :buses))
        buses_loads_available = deepcopy(buses_loads_base)

        key_shunts = filter(i->field(system, :shunts, :status)[i], field(system, :shunts, :keys))
        shunts_idxs = makeidxlist(key_shunts, nshunts)
        buses_shunts_base = Dict((i, Int[]) for i in key_buses)
        buses_asset!(buses_shunts_base, key_shunts, field(system, :shunts, :buses))
        buses_shunts_available = deepcopy(buses_shunts_base)

        branches_flow_from = Vector{Float64}(undef, nbranches) # Active power withdrawn at the from bus
        branches_flow_to = Vector{Float64}(undef, nbranches) # Active power withdrawn at the from bus
        buses_curtailed_pd = Vector{Float64}(undef, nbuses) #curtailed load in p.u. (active power)
        buses_curtailed_qd = Vector{Float64}(undef, nbuses) #curtailed load in p.u. (reactive power)
        stored_energy = Vector{Float64}(undef, nstors) #stored energy

        arcs_from = deepcopy(system.arcs_from)
        arcs_to = deepcopy(system.arcs_to)
        arcs = [arcs_from; arcs_to]
        buspairs = deepcopy(system.buspairs)

        busarcs = Dict((i, Tuple{Int, Int, Int}[]) for i in eachindex(key_buses))
        buses_asset!(busarcs, arcs)

        vad_min,vad_max = calc_theta_delta_bounds(key_buses, key_branches, system.branches)
        delta_bounds = [vad_min,vad_max]

        fill!(branches_flow_from, 0.0)
        fill!(branches_flow_to, 0.0)
        fill!(buses_curtailed_pd, 0.0)
        fill!(buses_curtailed_qd, 0.0)
        fill!(stored_energy, 0.0)

        return new(
            branches_idxs,  
            generators_idxs, 
            storages_idxs,
            buses_idxs, 
            loads_idxs, 
            shunts_idxs,
            buses_generators_base,
            buses_generators_available, 
            buses_storages_base, 
            buses_storages_available, 
            buses_loads_base, 
            buses_loads_available, 
            buses_shunts_base,
            buses_shunts_available,
            buses_curtailed_pd,
            buses_curtailed_qd,
            branches_flow_from,
            branches_flow_to,
            stored_energy,
            arcs_from,
            arcs_to,
            arcs,
            busarcs,
            buspairs,
            delta_bounds)
    end
end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.branches_idxs == y.branches_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.buses_generators_base == y.buses_generators_base &&
    x.buses_generators_available == y.buses_generators_available &&
    x.buses_storages_base == y.buses_storages_base &&
    x.buses_storages_available == y.buses_storages_available &&
    x.buses_loads_base == y.buses_loads_base &&
    x.buses_loads_available == y.buses_loads_available &&
    x.buses_shunts_base == y.buses_shunts_base &&
    x.buses_shunts_available == y.buses_shunts_available &&
    x.buses_curtailed_pd == x.buses_curtailed_pd &&
    x.buses_curtailed_qd == x.buses_curtailed_qd &&
    x.branches_flow_from == x.branches_flow_from &&
    x.branches_flow_to == x.branches_flow_to &&
    x.stored_energy == x.stored_energy &&
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

    optimizer::Union{MOI.OptimizerWithAttributes, Nothing}
    jump_modelmode::JuMP.ModelMode
    powermodel_formulation::Type
    select_largest_splitnetwork::Bool
    deactivate_isolated_bus_gens_stors::Bool
    set_string_names_on_creation::Bool
    count_samples::Bool
    record_branch_flow::Bool

    function Settings(;
        optimizer::Union{MOI.OptimizerWithAttributes, Nothing} = nothing,
        jump_modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        powermodel_formulation::Type=OPF.DCPPowerModel,
        select_largest_splitnetwork::Bool=false,
        deactivate_isolated_bus_gens_stors::Bool=true,
        set_string_names_on_creation::Bool=false,
        count_samples::Bool=false,
        record_branch_flow::Bool=false
        )
        new(optimizer, jump_modelmode, powermodel_formulation, 
        select_largest_splitnetwork, deactivate_isolated_bus_gens_stors,
        set_string_names_on_creation, count_samples, record_branch_flow)
    end
end
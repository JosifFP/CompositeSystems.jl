"Topology"
struct Topology

    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    branches_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    generatorstorages_idxs::Vector{UnitRange{Int}}

    init_loads_nodes::Dict{Int, Vector{Int}}
    bus_loads::Dict{Int, Vector{Int}}
    bus_shunts::Dict{Int, Vector{Int}}
    bus_generators::Dict{Int, Vector{Int}}
    bus_storages::Dict{Int, Vector{Int}}
    bus_generatorstorages::Dict{Int, Vector{Int}}

    arcs_from::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs_to::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    busarcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}

    function Topology(system::SystemModel{N}) where {N}

        key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))
        buses_idxs = makeidxlist(key_buses, length(system.buses))

        key_loads = filter(i->field(system, :loads, :status)[i], field(system, :loads, :keys))
        loads_idxs = makeidxlist(key_loads, length(system.loads))
        init_loads_nodes = Dict((i, Int[]) for i in key_buses)
        bus_asset!(init_loads_nodes, key_loads, field(system, :loads, :buses))
        bus_loads = deepcopy(init_loads_nodes)

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

        key_generatorstorages = filter(i->field(system, :generatorstorages, :status)[i], field(system, :generatorstorages, :keys))
        generatorstorages_idxs = makeidxlist(key_generatorstorages, length(system.generatorstorages))
        bus_generatorstorages = Dict((i, Int[]) for i in key_buses)
        bus_asset!(bus_generatorstorages, key_generatorstorages, field(system, :generatorstorages, :buses))

        key_branches = filter(i->field(system, :branches, :status)[i], field(system, :branches, :keys))
        branches_idxs = makeidxlist(key_branches, length(system.branches))

        arcs_from = deepcopy(system.arcs_from)
        arcs_to = deepcopy(system.arcs_to)
        arcs = [arcs_from; arcs_to]
        buspairs = deepcopy(system.buspairs)

        busarcs = Dict((i, Tuple{Int, Int, Int}[]) for i in eachindex(key_buses))
        bus_asset!(busarcs, arcs)

        return new(
            buses_idxs::Vector{UnitRange{Int}}, loads_idxs::Vector{UnitRange{Int}}, 
            branches_idxs::Vector{UnitRange{Int}}, shunts_idxs::Vector{UnitRange{Int}}, 
            generators_idxs::Vector{UnitRange{Int}}, storages_idxs::Vector{UnitRange{Int}}, 
            generatorstorages_idxs::Vector{UnitRange{Int}}, init_loads_nodes,
            bus_loads, bus_shunts, bus_generators, bus_storages, bus_generatorstorages, 
            arcs_from, arcs_to, arcs, busarcs, buspairs)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.generatorstorages_idxs == y.generatorstorages_idxs &&
    x.init_loads_nodes == y.init_loads_nodes &&
    x.bus_loads == y.bus_loads &&
    x.bus_shunts == y.bus_shunts &&
    x.bus_generators == y.bus_generators &&
    x.bus_storages == y.bus_storages &&
    x.bus_generatorstorages == y.bus_generatorstorages &&
    x.busarcs == y.busarcs &&
    x.arcs_from == y.arcs_from &&
    x.arcs_to == y.arcs_to &&
    x.arcs == y.arcs &&
    x.buspairs == y.buspairs

"a macro for adding the base AbstractPowerModels fields to a type definition"
@def pm_fields begin
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

abstract type AbstractDCPLLModel <: AbstractDCPModel end
struct DCPLLPowerModel <: AbstractDCPLLModel @pm_fields end

abstract type AbstractNFAModel <: AbstractDCPModel end
struct NFAPowerModel <: AbstractNFAModel @pm_fields end

abstract type AbstractLPACModel <: AbstractPowerModel end
struct LPACCPowerModel <: AbstractLPACModel @pm_fields end

abstract type PM_AbstractDCPModel <: AbstractDCPowerModel end
struct PM_DCPPowerModel <: PM_AbstractDCPModel @pm_fields end

AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
AbstractPolarModels = Union{AbstractLPACModel, AbstractDCPowerModel}

""
struct Settings

    optimizer::MOI.OptimizerWithAttributes
    modelmode::JuMP.ModelMode
    powermodel::Type

    function Settings(
        optimizer::MOI.OptimizerWithAttributes;
        modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        powermodel::Type=OPF.DCPPowerModel
        )
        new(optimizer, modelmode, powermodel)
    end

end

""
function jump_model(modelmode::JuMP.ModelMode, optimizer; string_names = false)

    if modelmode == JuMP.AUTOMATIC
        jump_model = Model(optimizer; add_bridges = false)
    elseif modelmode == JuMP.DIRECT
        @error("Mode not supported")
        jump_model = direct_model(optimizer)
    else
        @warn("Manual Mode not supported")
    end

    if string_names == false
    JuMP.set_string_names_on_creation(jump_model, false)
    end

    JuMP.set_silent(jump_model)

    return jump_model
    
end


"Constructor for an AbstractPowerModel modeling object"
function abstract_model(method::Type{M}, topology::Topology, model::JuMP.Model) where {M<:AbstractPowerModel}

    var = Dict{Symbol, AbstractArray}()
    con = Dict{Symbol, AbstractArray}()
    return M(model, topology, var, con)

end

""
function initialize_pm_containers!(pm::AbstractDCPowerModel, system::SystemModel; timeseries=false)

    if timeseries == true
        @error("Timeseries containers not supported")
        #add_var_container!(pm.var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    else
        add_var_container!(pm.var, :pg, field(system, :generators, :keys))
        add_var_container!(pm.var, :va, field(system, :buses, :keys))
        add_var_container!(pm.var, :z_demand, field(system, :loads, :keys))
        add_var_container!(pm.var, :z_shunt, field(system, :shunts, :keys))
        add_var_container!(pm.var, :p, field(pm.topology, :arcs))

        add_con_container!(pm.con, :power_balance_p, field(system, :buses, :keys))
        add_con_container!(pm.con, :ohms_yt_from_p, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_to_p, field(system, :branches, :keys))
        add_con_container!(pm.con, :voltage_angle_diff_upper, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :voltage_angle_diff_lower, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :model_voltage, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :thermal_limit_from, field(system, :branches, :keys))
        add_con_container!(pm.con, :thermal_limit_to, field(system, :branches, :keys))

        add_var_container!(pm.var, :ps, field(system, :storages, :keys))
        add_var_container!(pm.var, :se, field(system, :storages, :keys))
        add_var_container!(pm.var, :sc, field(system, :storages, :keys))
        add_var_container!(pm.var, :sd, field(system, :storages, :keys))
        add_var_container!(pm.var, :sc_on, field(system, :storages, :keys))
        add_var_container!(pm.var, :sd_on, field(system, :storages, :keys))

        add_con_container!(pm.con, :storage_state, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_1, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_2, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_3, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    end

    return

end

""
function initialize_pm_containers!(pm::AbstractLPACModel, system::SystemModel; timeseries=false)

    if timeseries == true
        @error("Timeseries containers not supported")
        #add_var_container!(pm.var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    else
        add_var_container!(pm.var, :pg, field(system, :generators, :keys))
        add_var_container!(pm.var, :qg, field(system, :generators, :keys))
        add_var_container!(pm.var, :va, field(system, :buses, :keys))
        add_var_container!(pm.var, :phi, field(system, :buses, :keys))
        add_var_container!(pm.var, :cs, field(pm.topology, :buspairs))
        add_var_container!(pm.var, :z_demand, field(system, :loads, :keys))
        add_var_container!(pm.var, :z_shunt, field(system, :shunts, :keys))
        add_var_container!(pm.var, :p, field(pm.topology, :arcs))
        add_var_container!(pm.var, :q, field(pm.topology, :arcs))

        add_con_container!(pm.con, :power_balance_p, field(system, :buses, :keys))
        add_con_container!(pm.con, :power_balance_q, field(system, :buses, :keys))
        add_con_container!(pm.con, :ohms_yt_from_p, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_to_p, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_from_q, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_to_q, field(system, :branches, :keys))
        add_con_container!(pm.con, :voltage_angle_diff_upper, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :voltage_angle_diff_lower, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :model_voltage, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :thermal_limit_from, field(system, :branches, :keys))
        add_con_container!(pm.con, :thermal_limit_to, field(system, :branches, :keys))

        add_var_container!(pm.var, :ps, field(system, :storages, :keys))
        add_var_container!(pm.var, :qs, field(system, :storages, :keys))
        add_var_container!(pm.var, :qsc, field(system, :storages, :keys))
        add_var_container!(pm.var, :se, field(system, :storages, :keys))
        add_var_container!(pm.var, :sc, field(system, :storages, :keys))
        add_var_container!(pm.var, :sd, field(system, :storages, :keys))
        add_var_container!(pm.var, :sc_on, field(system, :storages, :keys))
        add_var_container!(pm.var, :sd_on, field(system, :storages, :keys))

        add_con_container!(pm.con, :storage_state, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_1, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_2, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_3, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    end

    return

end

""
function empty_model!(pm::AbstractDCPowerModel)
    JuMP.empty!(pm.model)
    MOIU.reset_optimizer(pm.model)
    return
end

""
function reset_model!(pm::AbstractPowerModel, states::SystemStates, settings::Settings, s)

    if iszero(s%10) && settings.optimizer == Ipopt
        JuMP.set_optimizer(pm.model, deepcopy(settings.optimizer); add_bridges = false)
    elseif iszero(s%30) && settings.optimizer == Gurobi
        JuMP.set_optimizer(pm.model, deepcopy(settings.optimizer); add_bridges = false)
    else
        MOIU.reset_optimizer(pm.model)
    end

    fill!(getfield(states, :plc), 0)
    fill!(getfield(states, :qlc), 0)
    fill!(getfield(states, :se), 0)
    fill!(getfield(states, :loads), 1)
    fill!(getfield(states, :shunts), 1)
    return

end

""
function update_topology!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    if all(view(states.branches,:,t)) ≠ true || all(view(states.branches,:,t-1)) ≠ true
        simplify!(pm, system, states, t, no_isolated=true)
        update_arcs!(pm, system, states.branches, t)
    end
    update_all_idxs!(pm, system, states, t)
    return

end

""
function _update_topology!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    simplify!(pm, system, states, t, no_isolated=false)
    update_arcs!(pm, system, states.branches, t)
    update_all_idxs!(pm, system, states, t)
    
    return

end
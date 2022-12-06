"Topology"
struct Topology

    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    branches_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    generatorstorages_idxs::Vector{UnitRange{Int}}

    loads_nodes::Dict{Int, Vector{Int}}
    shunts_nodes::Dict{Int, Vector{Int}}
    generators_nodes::Dict{Int, Vector{Int}}
    storages_nodes::Dict{Int, Vector{Int}}
    generatorstorages_nodes::Dict{Int, Vector{Int}}

    arcs_from::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs_to::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    busarcs::Matrix{Union{Missing, Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Union{Missing,Vector{Float16}}}

    function Topology(system::SystemModel{N}) where {N}

        key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))
        buses_idxs = makeidxlist(key_buses, length(system.buses))

        key_loads = filter(i->field(system, :loads, :status)[i], field(system, :loads, :keys))
        loads_idxs = makeidxlist(key_loads, length(system.loads))
        tmp = Dict((i, Int[]) for i in key_buses)
        loads_nodes = bus_asset!(tmp, key_loads, field(system, :loads, :buses))

        key_shunts = filter(i->field(system, :shunts, :status)[i], field(system, :shunts, :keys))
        shunts_idxs = makeidxlist(key_shunts, length(system.shunts))
        tmp = Dict((i, Int[]) for i in key_buses)
        shunts_nodes = bus_asset!(tmp, key_shunts, field(system, :shunts, :buses))

        key_generators = filter(i->field(system, :generators, :status)[i], field(system, :generators, :keys))
        generators_idxs = makeidxlist(key_generators, length(system.generators))
        tmp = Dict((i, Int[]) for i in key_buses)
        generators_nodes = bus_asset!(tmp, key_generators, field(system, :generators, :buses))

        key_storages = filter(i->field(system, :storages, :status)[i], field(system, :storages, :keys))
        storages_idxs = makeidxlist(key_storages, length(system.storages))
        tmp = Dict((i, Int[]) for i in key_buses)
        storages_nodes = bus_asset!(tmp, key_storages, field(system, :storages, :buses))

        key_generatorstorages = filter(i->field(system, :generatorstorages, :status)[i], field(system, :generatorstorages, :keys))
        generatorstorages_idxs = makeidxlist(key_generatorstorages, length(system.generatorstorages))
        tmp = Dict((i, Int[]) for i in key_buses)
        generatorstorages_nodes = bus_asset!(tmp, key_generatorstorages, field(system, :generatorstorages, :buses))

        key_branches = filter(i->field(system, :branches, :status)[i], field(system, :branches, :keys))
        branches_idxs = makeidxlist(key_branches, length(system.branches))

        Nodes = length(system.buses)
        Edges = length(system.branches)

        A = Array{Union{Missing,Tuple{Int,Int,Int}}, 2}(undef, Nodes, Edges)

        f_bus = field(system, :branches, :f_bus)
        t_bus = field(system, :branches, :t_bus)
        keys = field(system, :branches, :keys)

        for j in keys
            for i in field(system, :branches, :keys)
                if f_bus[j]==i
                    A[i,j] = (j, f_bus[j], t_bus[j])
                elseif t_bus[j]==i
                    A[i,j] = (j, t_bus[j], f_bus[j])
                end
            end
        end

        arcs_from = filter(i -> i[2] < i[3], skipmissing(A))
        arcs_to = filter(i -> i[2] > i[3], skipmissing(A))
        arcs = [arcs_from; arcs_to]

        buspairs = calc_buspair_parameters(field(system, :branches), keys)

        return new(
            buses_idxs::Vector{UnitRange{Int}}, loads_idxs::Vector{UnitRange{Int}}, 
            branches_idxs::Vector{UnitRange{Int}}, shunts_idxs::Vector{UnitRange{Int}}, 
            generators_idxs::Vector{UnitRange{Int}}, storages_idxs::Vector{UnitRange{Int}}, 
            generatorstorages_idxs::Vector{UnitRange{Int}}, 
            loads_nodes, shunts_nodes, generators_nodes, storages_nodes, generatorstorages_nodes, 
            arcs_from, arcs_to, arcs, A, buspairs)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.generatorstorages_idxs == y.generatorstorages_idxs &&
    x.loads_nodes == y.loads_nodes &&
    x.shunts_nodes == y.shunts_nodes &&
    x.generators_nodes == y.generators_nodes &&
    x.storages_nodes == y.storages_nodes &&
    x.generatorstorages_nodes == y.generatorstorages_nodes &&
    x.busarcs == y.busarcs &&
    x.arcs_from == y.arcs_from &&
    x.arcs_to == y.arcs_to &&
    x.arcs == y.arcs &&
    x.buspairs == y.buspairs

"a macro for adding the base AbstractPowerModels fields to a type definition"
OPF.@def pm_fields begin
    model::AbstractModel
    topology::Topology
    var::Dict{Symbol, AbstractArray}
    con::Dict{Symbol, AbstractArray}
end

"root of the power formulation type hierarchy"
abstract type AbstractPowerModel end

"Types of optimization"
abstract type AbstractDCPowerModel <: AbstractPowerModel end
abstract type AbstractACPowerModel <: AbstractPowerModel end
abstract type AbstractLPACModel <: AbstractPowerModel end
abstract type AbstractLPACCModel <: AbstractLPACModel end

abstract type AbstractDCPModel <: AbstractDCPowerModel end
abstract type AbstractDCMPPModel <: AbstractDCPModel end
abstract type AbstractDCPLLModel <: AbstractDCPModel end
abstract type AbstractNFAModel <: AbstractDCPModel end

abstract type PM_AbstractDCPModel <: AbstractDCPowerModel end
LoadCurtailment = Union{AbstractDCPModel, AbstractLPACCModel}

struct LPACCPowerModel <: AbstractLPACCModel @pm_fields end
struct DCPPowerModel <: AbstractDCPModel @pm_fields end
struct DCMPPowerModel <: AbstractDCMPPModel @pm_fields end
struct DCPLLPowerModel <: AbstractDCPLLModel @pm_fields end
struct NFAPowerModel <: AbstractNFAModel @pm_fields end

struct PM_DCPPowerModel <: PM_AbstractDCPModel @pm_fields end
StructPowerModel = Union{DCPPowerModel, DCMPPowerModel, DCPLLPowerModel, NFAPowerModel}

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
function JumpModel(modelmode::JuMP.ModelMode, optimizer)

    if modelmode == JuMP.AUTOMATIC
        jumpmodel = Model(optimizer; add_bridges = false)
    elseif modelmode == JuMP.DIRECT
        @error("Mode not supported")
        jumpmodel = direct_model(optimizer)
    else
        @warn("Manual Mode not supported")
    end

    JuMP.set_string_names_on_creation(jumpmodel, false)
    JuMP.set_silent(jumpmodel)

    return jumpmodel
    
end


"Constructor for an AbstractPowerModel modeling object"
function PowerModel(method::Type{M}, topology::Topology, model::JuMP.Model) where {M<:AbstractDCPowerModel}
    
    var = Dict{Symbol, AbstractArray}()
    con = Dict{Symbol, AbstractArray}()
    #method == DCMPPowerModel && @error("method $(method) not supported yet. DCPPowerModel method was built")
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
        add_var_container!(pm.var, :plc, field(system, :loads, :keys))
        add_var_container!(pm.var, :p, field(pm.topology, :arcs))

        add_con_container!(pm.con, :power_balance, field(system, :buses, :keys))
        add_con_container!(pm.con, :ohms_yt_from, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_to, field(system, :branches, :keys))
        add_con_container!(pm.con, :voltage_angle_diff_upper, field(system, :branches, :keys))
        add_con_container!(pm.con, :voltage_angle_diff_lower, field(system, :branches, :keys))

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
        add_var_container!(pm.var, :plc, field(system, :loads, :keys))
        add_var_container!(pm.var, :qlc, field(system, :loads, :keys))
        add_var_container!(pm.var, :p, field(pm.topology, :arcs))
        add_var_container!(pm.var, :q, field(pm.topology, :arcs))

        add_con_container!(pm.con, :power_balance, field(system, :buses, :keys))
        add_con_container!(pm.con, :ohms_yt_from, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_to, field(system, :branches, :keys))
        add_con_container!(pm.con, :voltage_angle_diff_upper, field(system, :branches, :keys))
        add_con_container!(pm.con, :voltage_angle_diff_lower, field(system, :branches, :keys))

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
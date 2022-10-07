""
struct Topology

    sol_plc::Vector{Int}
    sol_qlc::Vector{Int}
    sol_pg::Vector{Int}
    sol_qg::Vector{Int}
    arcs_from::Vector{Tuple{Int, Int, Int}}
    arcs_to::Vector{Tuple{Int, Int, Int}}
    arcs::Vector{Tuple{Int, Int, Int}}
    key_buses::Vector{Int}
    key_loads::Vector{Int}
    key_branches::Vector{Int}
    key_shunts::Vector{Int}
    key_generators::Vector{Int}
    key_storages::Vector{Int}
    key_generatorstorages::Vector{Int}
    bus_gens::Dict{Int, <:Any}
    bus_loads::Dict{Int, <:Any}
    bus_shunts::Dict{Int, <:Any}
    bus_storage::Dict{Int, <:Any}
    bus_arcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Dict{String, Real}} 
    ref_buses::Vector{Int}

    function Topology(system::SystemModel{N,L,T,S}) where {N,L,T,S}

        key_buses = deepcopy(field(system, Buses, :keys))
        key_loads = deepcopy(field(system, Loads, :keys))
        key_branches = deepcopy(field(system, Branches, :keys))
        key_shunts = deepcopy(field(system, Shunts, :keys))
        key_generators = deepcopy(field(system, Generators, :keys))
        key_storages = deepcopy(field(system, Storages, :keys))
        key_generatorstorages = deepcopy(field(system, GeneratorStorages, :keys))

        arcs_from = [(l,field(system, Branches, :f_bus)[l],field(system, Branches, :t_bus)[l]) for l in key_branches]
        arcs_to   = [(l,field(system, Branches, :t_bus)[l],field(system, Branches, :f_bus)[l]) for l in key_branches]
        arcs = [arcs_from; arcs_to]

        bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage = get_bus_components(
            arcs, field(system, :buses), field(system, :loads), field(system, :shunts), field(system, :generators), field(system, :storages))
        
        ref_buses = [i for i in key_buses if field(system, Buses, :bus_type)[i] == 3]

        if length(ref_buses) > 1
            Memento.error(_LOGGER, "multiple reference buses found, $(keys(ref_buses)), this can cause infeasibility if they are in the same connected component")
        end

        buspairs = calc_buspair_parameters(field(system, :buses), field(system, :branches))

        return new(
        zeros(Int, length(key_loads)), zeros(Int, length(key_loads)), 
        zeros(Int, length(key_loads)), zeros(Int, length(key_loads)),
        arcs_from, arcs_to, arcs,
        key_buses, key_loads, key_branches, key_shunts, key_generators, key_storages, key_generatorstorages, 
        bus_gens, bus_loads, bus_shunts, bus_storage, bus_arcs, buspairs, ref_buses)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.sol_plc == y.sol_plc &&
    x.sol_qlc == y.sol_qlc &&
    x.sol_pg == y.sol_pg &&
    x.sol_qg == y.sol_qg &&
    x.arcs_from == y.arcs_from &&
    x.arcs_to == y.arcs_to &&
    x.arcs == y.arcs &&
    x.key_buses == y.key_buses &&
    x.key_loads == y.key_loads &&
    x.key_branches == y.key_branches &&
    x.key_shunts == y.key_shunts &&
    x.key_generators == y.key_generators &&
    x.key_storages == y.key_storages &&
    x.key_generatorstorages == y.key_generatorstorages &&
    x.bus_gens == y.bus_gens &&
    x.bus_loads == y.bus_loads &&
    x.bus_shunts == y.bus_shunts &&
    x.bus_storage == y.bus_storage &&
    x.bus_arcs == y.bus_arcs &&
    x.buspairs == y.buspairs &&
    x.ref_buses == y.ref_buses
#


"""
The `def` macro is used to build other macros that can insert the same block of
julia code into different parts of a program.
"""
macro def(name, definition)
    return quote
        macro $(esc(name))()
            esc($(Expr(:quote, definition)))
        end
    end
end

"root of the power model formulation type hierarchy"
abstract type AbstractPowerModel end

"a macro for adding the standard AbstractPowerModel fields to a type definition"
CompositeAdequacy.@def pm_fields begin
    
    model::JuMP.AbstractModel
    topology:: Topology
    sol::Dict{Symbol,<:Any}

end

struct AbstractDCPowerModel <: AbstractPowerModel @pm_fields end
struct AbstractACPowerModel <: AbstractPowerModel @pm_fields end
#AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
#AbstractWModels = Union{AbstractWRModels, AbstractBFModel}
#struct ACPowerModel <: AbstractACPowerModel @pm_fields end
#struct DCPowerModel <: AbstractDCPowerModel @pm_fields end

"Types of optimization"
abstract type DCOPF <: AbstractPowerModel end
abstract type Transportation <: AbstractPowerModel end
LCDCMethod = Union{DCOPF, Transportation}

"Constructor for an AbstractPowerModel modeling object"
function PowerFlowProblem(PowerModel::Type{<:AbstractPowerModel}, model::JuMP.AbstractModel, topology:: Topology)

    return PowerModel(model, topology, Dict{Symbol, Any}())

end


sol(pm::AbstractPowerModel, args...) = _sol(pm.sol, args...)
sol(pm::AbstractPowerModel, key::Symbol) = pm.sol[key]

""
function _sol(sol::Dict, args...)
    for arg in args
        if haskey(sol, arg)
            sol = sol[arg]
        else
            sol = sol[arg] = Dict()
        end
    end

    return sol
end
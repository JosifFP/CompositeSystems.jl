""
struct Topology

    #::Union{UnitRange{Int}, Vector{UnitRange{Int}}}
    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    branches_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    generatorstorages_idxs::Vector{UnitRange{Int}}
    
    bus_loads_idxs::Vector{UnitRange{Int}}
    bus_shunts_idxs::Vector{UnitRange{Int}}
    bus_generators_idxs::Vector{UnitRange{Int}}
    bus_storages_idxs::Vector{UnitRange{Int}}
    bus_generatorstorages_idxs::Vector{UnitRange{Int}}

    arcs_from_0::Vector{Tuple{Int, Int, Int}}
    arcs_to_0::Vector{Tuple{Int, Int, Int}}
    bus_arcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Dict{String, Real}} 
    ref_buses::Vector{Int}

    sol_plc::Vector{Float16}
    sol_pg::Vector{Float16}

    function Topology(system::SystemModel)

        nbuses = length(system.buses)

        key_buses = [i for i in CompositeAdequacy.field(system, Buses, :keys) if CompositeAdequacy.field(system, Buses, :bus_type)[i] != 4]
        buses_idxs = makeidxlist(key_buses, nbuses)

        key_loads = [i for i in field(system, Loads, :keys) if field(system, Loads, :status)[i] == 1]
        bus_loads = [field(system, Loads, :buses)[i] for i in key_loads]
        loads_idxs = makeidxlist(key_loads, length(system.loads))
        bus_loads_idxs = makeidxlist(bus_loads, nbuses)
        
        key_branches = [i for i in field(system, Branches, :keys) if field(system, Branches, :status)[i] == 1]
        branches_idxs = makeidxlist(key_branches, length(system.branches))

        key_shunts = [i for i in field(system, Shunts, :keys) if field(system, Shunts, :status)[i] == 1]
        bus_shunts = [field(system, Shunts, :buses)[i] for i in key_shunts]
        shunts_idxs = makeidxlist(key_shunts, length(system.shunts))
        bus_shunts_idxs = makeidxlist(bus_shunts, nbuses)

        key_generators = [i for i in field(system, Generators, :keys) if field(system, Generators, :status)[i] == 1]
        bus_generators = [field(system, Generators, :buses)[i] for i in key_generators]
        generators_idxs = makeidxlist(key_generators, length(system.generators))
        bus_generators_idxs = makeidxlist(bus_generators, nbuses)

        key_storages = [i for i in field(system, Storages, :keys) if field(system, Storages, :status)[i] == 1]
        bus_storages = [field(system, Storages, :buses)[i] for i in key_storages]
        storages_idxs = makeidxlist(key_storages, length(system.storages))
        bus_storages_idxs = makeidxlist(bus_storages, nbuses)

        key_generatorstorages = [i for i in field(system, GeneratorStorages, :keys) if field(system, GeneratorStorages, :status)[i] == 1]
        bus_generatorstorages = [field(system, GeneratorStorages, :buses)[i] for i in key_generatorstorages]
        generatorstorages_idxs = makeidxlist(key_generatorstorages, length(system.generatorstorages))
        bus_generatorstorages_idxs = makeidxlist(bus_generatorstorages, nbuses)

        arcs_from_0 = [(l,field(system, Branches, :f_bus)[l],field(system, Branches, :t_bus)[l]) for l in key_branches]
        arcs_to_0 = [(l,field(system, Branches, :t_bus)[l],field(system, Branches, :f_bus)[l]) for l in key_branches]

        bus_arcs = Dict((i, Tuple{Int,Int,Int}[]) for i in key_buses)
        for (l,i,j) in [arcs_from_0; arcs_to_0]
            push!(bus_arcs[i], (l,i,j))
        end
        
        ref_buses = [i for i in key_buses if field(system, Buses, :bus_type)[i] == 3]

        buspairs = calc_buspair_parameters(field(system, :buses), field(system, :branches))

        sol_plc = zeros(Float16, length(system.loads))
        sol_pg = zeros(Float16, length(system.generators))

        return new(
        buses_idxs, loads_idxs, branches_idxs, shunts_idxs, generators_idxs, storages_idxs, generatorstorages_idxs, 
        bus_loads_idxs, bus_shunts_idxs, bus_generators_idxs, bus_storages_idxs, bus_generatorstorages_idxs,
        arcs_from_0, arcs_to_0, bus_arcs, buspairs, ref_buses, sol_plc, sol_pg)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.generatorstorages_idxs == y.generatorstorages_idxs &&
    x.bus_loads_idxs == y.bus_loads_idxs &&
    x.bus_shunts_idxs == y.bus_shunts_idxs &&
    x.bus_generators_idxs == y.bus_generators_idxs &&
    x.bus_storages_idxs == y.bus_storages_idxs &&
    x.bus_generatorstorages_idxs == y.bus_generatorstorages_idxs &&
    x.arcs_from_0 == y.key_generators &&
    x.arcs_to_0 == y.key_storages &&
    x.buspairs == y.key_generatorstorages &&
    x.ref_buses == y.bus_gens &&
    x.sol_plc == y.bus_loads &&
    x.sol_pg == y.bus_shunts
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


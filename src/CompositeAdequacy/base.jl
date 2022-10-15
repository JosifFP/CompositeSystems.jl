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
    
    bus_loads::Dict{Int, Vector{Int}}
    bus_shunts::Dict{Int, Vector{Int}}
    bus_generators::Dict{Int, Vector{Int}}
    bus_storages::Dict{Int, Vector{Int}}
    bus_generatorstorages::Dict{Int, Vector{Int}}

    bus_arcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Dict{String, Real}}

    plc::Matrix{Float16}

    function Topology(system::SystemModel{N}) where {N}

        nbuses = length(system.buses)

        key_buses = [i for i in field(system, Buses, :keys) if field(system, Buses, :bus_type)[i] != 4]
        buses_idxs = makeidxlist(key_buses, nbuses)

        key_loads = [i for i in field(system, Loads, :keys) if field(system, Loads, :status)[i] == 1]
        #bus_loads = [field(system, Loads, :buses)[i] for i in key_loads] #bus_loads_idxs = makeidxlist(bus_loads, nbuses)
        loads_idxs = makeidxlist(key_loads, length(system.loads))
        tmp = Dict((i, Int[]) for i in key_buses)
        bus_loads = bus_asset!(tmp, key_loads, field(system, Loads, :buses))

        key_branches = [i for i in field(system, Branches, :keys) if field(system, Branches, :status)[i] == 1]
        branches_idxs = makeidxlist(key_branches, length(system.branches))

        key_shunts = [i for i in field(system, Shunts, :keys) if field(system, Shunts, :status)[i] == 1]
        shunts_idxs = makeidxlist(key_shunts, length(system.shunts))
        tmp = Dict((i, Int[]) for i in key_buses)
        bus_shunts = bus_asset!(tmp, key_shunts, field(system, Shunts, :buses))

        key_generators = [i for i in field(system, Generators, :keys) if field(system, Generators, :status)[i] == 1]
        generators_idxs = makeidxlist(key_generators, length(system.generators))
        tmp = Dict((i, Int[]) for i in key_buses)
        bus_generators = bus_asset!(tmp, key_generators, field(system, Generators, :buses))

        key_storages = [i for i in field(system, Storages, :keys) if field(system, Storages, :status)[i] == 1]
        storages_idxs = makeidxlist(key_storages, length(system.storages))
        tmp = Dict((i, Int[]) for i in key_buses)
        bus_storages = bus_asset!(tmp, key_storages, field(system, Storages, :buses))

        key_generatorstorages = [i for i in field(system, GeneratorStorages, :keys) if field(system, GeneratorStorages, :status)[i] == 1]
        generatorstorages_idxs = makeidxlist(key_generatorstorages, length(system.generatorstorages))
        tmp = Dict((i, Int[]) for i in key_buses)
        bus_generatorstorages = bus_asset!(tmp, key_generatorstorages, field(system, GeneratorStorages, :buses))

        bus_arcs = Dict((i, Tuple{Int,Int,Int}[]) for i in key_buses)
        for (l,i,j) in field(system, :arcs)
            push!(bus_arcs[i], (l,i,j))
        end

        buspairs = calc_buspair_parameters(field(system, :buses), field(system, :branches), key_branches)

        plc = zeros(Float16,length(system.loads), N)

        return new(
        buses_idxs, loads_idxs, branches_idxs, shunts_idxs, generators_idxs, storages_idxs, generatorstorages_idxs, 
        bus_loads, bus_shunts, bus_generators, bus_storages, bus_generatorstorages, bus_arcs, buspairs, plc)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.generatorstorages_idxs == y.generatorstorages_idxs &&
    x.bus_loads == y.bus_loads &&
    x.bus_shunts == y.bus_shunts &&
    x.bus_generators == y.bus_generators &&
    x.bus_storages == y.bus_storages &&
    x.bus_generatorstorages == y.bus_generatorstorages &&
    x.bus_arcs == y.bus_arcs &&
    x.buspairs == y.buspairs &&
    x.plc == y.plc
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
abstract type AbstractDCPowerModel <: AbstractPowerModel end
abstract type AbstractACPowerModel <: AbstractPowerModel end

"a macro for adding the standard AbstractPowerModel fields to a type definition"
CompositeAdequacy.@def ca_fields begin
    
    model::AbstractModel
    topology:: Topology
    var::Dict{Symbol,<:Any}

end

"Constructor for an AbstractPowerModel modeling object"
function PowerFlowProblem(PowerModel::Type{<:AbstractPowerModel}, model::AbstractModel, topology:: Topology)

    @assert PowerModel <: AbstractPowerModel

    var = Dict{Symbol, Any}(
        :va => Array{Int, VariableRef}[],
        #:vm => Dict{Int, VariableRef}(),
        :pg => Dict{Int, VariableRef}(),
        #:qg => Dict{Int, VariableRef}(),
        :p => Dict{Tuple{Int, Int, Int}, Any}(),
        #:q => Dict{Tuple{Int, Int, Int}, Any}(),
        :plc => Dict{Int, VariableRef}()
        #:qlc => Dict{Int, VariableRef}()
    )

    return PowerModel(model, topology, var)

end

"Types of optimization"
struct AbstractOPF <: AbstractDCPowerModel @ca_fields end
abstract type  DCOPF <: AbstractPowerModel end
abstract type  Transportation <: AbstractPowerModel end

var(pm::AbstractPowerModel) = pm.var
var(pm::AbstractPowerModel, key::Symbol) = pm.var[key]
var(pm::AbstractPowerModel, key::Symbol, idx) = pm.var[key][idx]
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


#AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
#AbstractActivePowerModel = Union{AbstractDCPModel, DCPPowerModel, AbstractDCMPPModel, AbstractNFAModel, NFAPowerModel,DCPLLPowerModel}
#AbstractWModels = Union{AbstractWRModels, AbstractBFModel}
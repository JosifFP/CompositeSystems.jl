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

""
abstract type VariableType end

struct VariableContainer <: OptimizationContainer 

    va::DenseAxisArray
    vm::DenseAxisArray
    pg::DenseAxisArray
    qg::DenseAxisArray
    plc::DenseAxisArray
    qlc::DenseAxisArray
    p::DenseAxisArray
    q::DenseAxisArray

end

""
function VariableContainer(system::SystemModel{N}, method::SimulationSpec) where {N}
    
    va = add_variable_container!(field(system, Buses, :keys), N, method)
    vm = add_variable_container!(field(system, Buses, :keys), N, method)
    pg = add_variable_container!(field(system, Generators, :keys), N, method)
    qg = add_variable_container!(field(system, Generators, :keys), N, method)
    plc = add_variable_container!(field(system, Loads, :keys), N, method)
    qlc = add_variable_container!(field(system, Loads, :keys), N, method)
    p = add_variable_container_dict!(field(system, :arcs), N, method)
    q = add_variable_container_dict!(field(system, :arcs), N, method)
    

    return VariableContainer(va, vm, pg, qg, plc, qlc, p, q)
end

""
function add_variable_container!(vkeys, N::Int, method::SequentialMCS)

    conts = DenseAxisArray{DenseAxisArray}(undef, [i for i in 1:N]) #Initiate empty 2-D DenseAxisArray container
    s_container = container_spec(VariableRef, vkeys)
    return fill!(conts, s_container)
end

""
function add_variable_container!(vkeys, N::Int, method::NonSequentialMCS)

    s_container = container_spec(VariableRef, vkeys)
    return fill!(DenseAxisArray{DenseAxisArray}(undef, [0]), s_container)
end

""
function add_variable_container_dict!(vkeys, N::Int, method::SequentialMCS)

    conts = DenseAxisArray{Dict}(undef, [i for i in 1:N]) #Initiate empty 2-D DenseAxisArray container
    s_container = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in vkeys)
    return fill!(conts, s_container)
end

""
function add_variable_container_dict!(vkeys, N::Int, method::NonSequentialMCS)

    s_container = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in vkeys)
    return fill!(DenseAxisArray{DenseAxisArray}(undef, [0]), s_container)
end

"""
Returns the correct container specification for the selected type of JuMP Model
"""
function container_spec(::Type{T}, axs...) where {T <: Any}
    return DenseAxisArray{T}(undef, axs...)
end


"Topology Container"
struct Topology <: OptimizationContainer

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

"a macro for adding the standard AbstractPowerModel fields to a type definition"
CompositeAdequacy.@def ca_fields begin
    
    model::AbstractModel
    topology::OptimizationContainer
    var::VariableContainer

end


struct DCPPowerModel <: AbstractDCPModel @ca_fields end
struct DCMPPowerModel <: AbstractDCMPPModel @ca_fields end
struct NFAPowerModel <: AbstractNFAModel @ca_fields end


"Constructor for an AbstractPowerModel modeling object"
function PowerFlowProblem(system::SystemModel{N}, method::SimulationSpec, settings::Settings, topology::OptimizationContainer) where {N}

    PowerModel = field(settings, :powermodel)
    @assert PowerModel<:AbstractPowerModel

    if PowerModel <: AbstractDCMPPModel 
        PowerModel = DCMPPowerModel
    elseif PowerModel <: AbstractNFAModel 
        PowerModel = NFAPowerModel
    end

    model = set_jumpmodel(field(settings, :modelmode), set_optimizer_default())
    var = VariableContainer(system, method)

    return PowerModel(model, topology, var)

end

include("Optimizer/utils.jl")
include("Optimizer/variables.jl")
include("Optimizer/constraints.jl")
include("Optimizer/Optimizer.jl")
include("Optimizer/solution.jl")
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

"Topology Container"
struct Topology <: OptimizationContainer

    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    branches_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    generatorstorages_idxs::Vector{UnitRange{Int}}
    
    nodes::Dict{Int, Vector{Int}}
    loads_nodes::Dict{Int, Vector{Int}}
    shunts_nodes::Dict{Int, Vector{Int}}
    generators_nodes::Dict{Int, Vector{Int}}
    storages_nodes::Dict{Int, Vector{Int}}
    generatorstorages_nodes::Dict{Int, Vector{Int}}
    arcs::Arcs
    plc::Matrix{Float16}

    function Topology(system::SystemModel{N}) where {N}

        key_buses = filter(i->field(system, Buses, :bus_type)[i]≠ 4, field(system, Buses, :keys))
        buses_idxs = makeidxlist(key_buses, length(system.buses))

        nodes = Dict((i, Int[]) for i in key_buses)

        key_loads = filter(i->field(system, Loads, :status)[i], field(system, Loads, :keys))
        loads_idxs = makeidxlist(key_loads, length(system.loads))
        tmp = Dict((i, Int[]) for i in key_buses)
        loads_nodes = bus_asset!(tmp, key_loads, field(system, Loads, :buses))

        key_shunts = filter(i->field(system, Shunts, :status)[i], field(system, Shunts, :keys))
        shunts_idxs = makeidxlist(key_shunts, length(system.shunts))
        tmp = Dict((i, Int[]) for i in key_buses)
        shunts_nodes = bus_asset!(tmp, key_shunts, field(system, Shunts, :buses))

        key_generators = filter(i->field(system, Generators, :status)[i], field(system, Generators, :keys))
        generators_idxs = makeidxlist(key_generators, length(system.generators))
        tmp = Dict((i, Int[]) for i in key_buses)
        generators_nodes = bus_asset!(tmp, key_generators, field(system, Generators, :buses))

        key_storages = filter(i->field(system, Storages, :status)[i], field(system, Storages, :keys))
        storages_idxs = makeidxlist(key_storages, length(system.storages))
        tmp = Dict((i, Int[]) for i in key_buses)
        storages_nodes = bus_asset!(tmp, key_storages, field(system, Storages, :buses))

        key_generatorstorages = filter(i->field(system, GeneratorStorages, :status)[i], field(system, GeneratorStorages, :keys))
        generatorstorages_idxs = makeidxlist(key_generatorstorages, length(system.generatorstorages))
        tmp = Dict((i, Int[]) for i in key_buses)
        generatorstorages_nodes = bus_asset!(tmp, key_generatorstorages, field(system, GeneratorStorages, :buses))

        key_branches = filter(i->field(system, Branches, :status)[i], field(system, Branches, :keys))
        branches_idxs = makeidxlist(key_branches, length(system.branches))

        arcs = deepcopy(field(system, :arcs))
        plc = zeros(Float16,length(system.loads), N)

        return new(
            buses_idxs::Vector{UnitRange{Int}}, loads_idxs::Vector{UnitRange{Int}}, 
            branches_idxs::Vector{UnitRange{Int}}, shunts_idxs::Vector{UnitRange{Int}}, 
            generators_idxs::Vector{UnitRange{Int}}, storages_idxs::Vector{UnitRange{Int}}, 
            generatorstorages_idxs::Vector{UnitRange{Int}}, nodes,
            loads_nodes, shunts_nodes, generators_nodes, storages_nodes, 
            generatorstorages_nodes, arcs, plc)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.generatorstorages_idxs == y.generatorstorages_idxs &&
    x.nodes == y.nodes &&
    x.loads_nodes == y.loads_nodes &&
    x.shunts_nodes == y.shunts_nodes &&
    x.generators_nodes == y.generators_nodes &&
    x.storages_nodes == y.storages_nodes &&
    x.generatorstorages_nodes == y.generatorstorages_nodes &&
    x.arcs == y.arcs &&
    x.plc == y.plc
#


""
mutable struct Variables <: OptimizationContainer
    va::DenseAxisArray{DenseAxisArray}
    vm::DenseAxisArray{DenseAxisArray}
    pg::DenseAxisArray{DenseAxisArray}
    qg::DenseAxisArray{DenseAxisArray}
    plc::DenseAxisArray{DenseAxisArray}
    qlc::DenseAxisArray{DenseAxisArray}
    p::DenseAxisArray{Dict}
    q::DenseAxisArray{Dict}

    function Variables(system::SystemModel{N}; timeseries::Bool=false) where {N}
        va = VarContainerArray(field(system, Buses, :keys), N; timeseries=timeseries)
        vm = VarContainerArray(field(system, Buses, :keys), N; timeseries=timeseries)
        pg = VarContainerArray(field(system, Generators, :keys), N; timeseries=timeseries)
        qg = VarContainerArray(field(system, Generators, :keys), N; timeseries=timeseries)
        plc = VarContainerArray(field(system, Loads, :keys), N; timeseries=timeseries)
        qlc = VarContainerArray(field(system, Loads, :keys), N; timeseries=timeseries)
        p = VarContainerDict(field(system, :arcs), N; timeseries=timeseries)
        q = VarContainerDict(field(system, :arcs), N; timeseries=timeseries)
        return new(va, vm, pg, qg, plc, qlc, p, q)
    end
end

""
function VarContainerArray(vkeys::Vector{Int}, N::Int; timeseries::Bool=false)
    if timeseries
        conts = DenseAxisArray{DenseAxisArray}(undef, [i for i in 1:N]) #Initiate empty 2-D DenseAxisArray container
        s_container = container_spec(VariableRef, vkeys)
        varcont = fill!(conts, s_container)
    else
        s_container = container_spec(VariableRef, vkeys)
        varcont = fill!(DenseAxisArray{DenseAxisArray}(undef, [0]), s_container)
    end
    return varcont
end

""
function VarContainerDict(container::Arcs, N::Int; timeseries::Bool=false)

    if timeseries
        conts = DenseAxisArray{Dict}(undef, [i for i in 1:N]) #Initiate empty 2-D DenseAxisArray container
        s_container = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in container.arcs)
        varcont = fill!(conts, s_container)
    else
        s_container = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in container.arcs)
        varcont = fill!(DenseAxisArray{Dict}(undef, [0]), s_container)
    end
    return varcont
end

""
function reset_variables!(var::Variables, var_cache::Variables; nw::Int=0)
    getfield(var, :va)[nw] = getindex(getfield(var_cache, :va), nw)
    getfield(var, :vm)[nw] = getindex(getfield(var_cache, :vm), nw)
    getfield(var, :pg)[nw] = getindex(getfield(var_cache, :pg), nw)
    getfield(var, :qg)[nw] = getindex(getfield(var_cache, :qg), nw)
    getfield(var, :plc)[nw] = getindex(getfield(var_cache, :plc), nw)
    getfield(var, :p)[nw] = getindex(getfield(var_cache, :p), nw)
end

"""
Returns the container specification for the selected type of JuMP Model
"""
function container_spec(::Type{T}, axs...) where {T <: Any}
    return DenseAxisArray{T}(undef, axs...)
end

"a macro for adding the standard AbstractPowerModel fields to a type definition"
CompositeAdequacy.@def ca_fields begin
    
    model::AbstractModel
    topology::OptimizationContainer
    var::Variables
    var_cache::Variables

end


struct DCPPowerModel <: AbstractDCPModel @ca_fields end
struct DCMPPowerModel <: AbstractDCMPPModel @ca_fields end
struct NFAPowerModel <: AbstractNFAModel @ca_fields end


"Constructor for an AbstractPowerModel modeling object"
function PowerFlowProblem(system::SystemModel{N}, method::SimulationSpec, settings::Settings; kwargs...) where {N}

    PowerModel = field(settings, :powermodel)
    @assert PowerModel<:AbstractPowerModel

    #Nodes = Base.length(system.buses)

    if PowerModel <: AbstractDCMPPModel 
        PowerModel = DCMPPowerModel
    elseif PowerModel <: AbstractNFAModel 
        PowerModel = NFAPowerModel
    end
    
    var = Variables(system, timeseries=false)

    return PowerModel(
        JumpModel(field(settings, :modelmode), set_optimizer_default()),
        Topology(system),
        var,
        deepcopy(var)
    )
end

include("Optimizer/utils.jl")
include("Optimizer/variables.jl")
include("Optimizer/constraints.jl")
include("Optimizer/Optimizer.jl")
include("Optimizer/solution.jl")
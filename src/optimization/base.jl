abstract type OptimizationContainer end

"Types of optimization"
abstract type AbstractPowerModel end
abstract type AbstractDCPowerModel <: AbstractPowerModel end
abstract type AbstractACPowerModel <: AbstractPowerModel end
abstract type AbstractDCMPPModel <: AbstractDCPowerModel end
abstract type AbstractDCPModel <: AbstractDCPowerModel end
abstract type AbstractNFAModel <: AbstractDCPowerModel end
abstract type PM_AbstractDCPModel <: AbstractDCPowerModel end
LoadCurtailment =  Union{AbstractDCMPPModel, AbstractDCPModel, AbstractNFAModel}

""
struct Settings

    optimizer::MOI.OptimizerWithAttributes
    modelmode::JuMP.ModelMode
    powermodel::Type{<:AbstractPowerModel}

    function Settings(
        optimizer::MOI.OptimizerWithAttributes;
        modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        powermodel::String="AbstractDCMPPModel"
        )

        abstractpm = type(powermodel)

        new(optimizer, modelmode, abstractpm)
    end

end


"""
Variables: A struct DatasetContainer for AbstractACPowerModel variables that are mutated by JuMP.
An alternate solution could be specifying a contaner within JuMP macros (container=Array, DenseAxisArray, Dict, etc.).
However, the latter generates more allocations and slow down simulations.
"""
struct DatasetContainer{T} <: OptimizationContainer
    object::Dict{Symbol, T}
    function DatasetContainer{T}() where {T <: AbstractArray}
        return new(Dict{Symbol, T}())
    end
end

"Topology"
struct Topology

    loads_nodes::Dict{Int, Vector{Int}}
    shunts_nodes::Dict{Int, Vector{Int}}
    generators_nodes::Dict{Int, Vector{Int}}
    storages_nodes::Dict{Int, Vector{Int}}
    generatorstorages_nodes::Dict{Int, Vector{Int}}
    arcs_from::Vector{Tuple{Int, Int, Int}}
    arcs_to::Vector{Tuple{Int, Int, Int}}
    arcs::Vector{Tuple{Int, Int, Int}}
    busarcs::Matrix{Union{Missing, Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Vector{Float16}}

    function Topology(system::SystemModel{N}) where {N}

        key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))

        key_loads = filter(i->field(system, :loads, :status)[i], field(system, :loads, :keys))
        tmp = Dict((i, Int[]) for i in key_buses)
        loads_nodes = bus_asset!(tmp, key_loads, field(system, :loads, :buses))

        key_shunts = filter(i->field(system, :shunts, :status)[i], field(system, :shunts, :keys))
        tmp = Dict((i, Int[]) for i in key_buses)
        shunts_nodes = bus_asset!(tmp, key_shunts, field(system, :shunts, :buses))

        key_generators = filter(i->field(system, :generators, :status)[i], field(system, :generators, :keys))
        tmp = Dict((i, Int[]) for i in key_buses)
        generators_nodes = bus_asset!(tmp, key_generators, field(system, :generators, :buses))

        key_storages = filter(i->field(system, :storages, :status)[i], field(system, :storages, :keys))
        tmp = Dict((i, Int[]) for i in key_buses)
        storages_nodes = bus_asset!(tmp, key_storages, field(system, :storages, :buses))

        key_generatorstorages = filter(i->field(system, :generatorstorages, :status)[i], field(system, :generatorstorages, :keys))
        tmp = Dict((i, Int[]) for i in key_buses)
        generatorstorages_nodes = bus_asset!(tmp, key_generatorstorages, field(system, :generatorstorages, :buses))

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

        return new(loads_nodes, shunts_nodes, generators_nodes, storages_nodes, generatorstorages_nodes, arcs_from, arcs_to, arcs, A, buspairs)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
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

""
struct DCPPowerModel <: AbstractDCPModel

    model::AbstractModel
    topology::Topology
    var::DatasetContainer
    sol::DatasetContainer

    function DCPPowerModel(
        model::AbstractModel,
        topology::Topology,
        var::DatasetContainer,
        sol::DatasetContainer
    )
        return new(model, topology, var, sol)
    end
end

""
struct DCMPPowerModel <: AbstractDCMPPModel

    model::AbstractModel
    topology::Topology
    var::DatasetContainer
    sol::DatasetContainer

    function DCMPPowerModel(
        model::AbstractModel,
        topology::Topology,
        var::DatasetContainer,
        sol::DatasetContainer
    )
        return new(model, topology, var, sol)
    end
end

""
struct NFAPowerModel <: AbstractNFAModel

    model::AbstractModel
    topology::Topology
    var::DatasetContainer
    sol::DatasetContainer

    function NFAPowerModel(
        model::AbstractModel,
        topology::Topology,
        var::DatasetContainer,
        sol::DatasetContainer
    )
        return new(model, topology, var, sol)
    end
end

""
struct PM_DCPPowerModel <: PM_AbstractDCPModel

    model::AbstractModel
    topology::Topology
    var::DatasetContainer
    sol::DatasetContainer

    function PM_DCPPowerModel(
        model::AbstractModel,
        topology::Topology,
        var::DatasetContainer,
        sol::DatasetContainer
    )
        return new(model, topology, var, sol)
    end
end



# "a macro for adding the standard AbstractPowerModel fields to a type definition"
# CompositeAdequacy.@def ca_fields begin
    
#     model::AbstractModel
#     topology::Topology
#     var::Variables
#     sol::Matrix{Float16}

# end


#struct DCPPowerModel <: AbstractDCPModel @ca_fields end
#struct DCMPPowerModel <: AbstractDCMPPModel @ca_fields end
#struct NFAPowerModel <: AbstractNFAModel @ca_fields end
#struct PM_DCPPowerModel <: PM_AbstractDCPModel @ca_fields end

# """
# Cache: a OptimizationContainer structure that stores variables and results in mutable containers.
# """
# struct Cache <: OptimizationContainer

#     var::Variables

#     function Cache(system::SystemModel{N}; multiperiod::Bool=false) where {N}

#         var = Variables(system, multiperiod=multiperiod)
#         return new(var)

#     end
# end

# """
# The `def` macro is used to build other macros that can insert the same block of
# julia code into different parts of a program.
# """
# macro def(name, definition)
#     return quote
#         macro $(esc(name))()
#             esc($(Expr(:quote, definition)))
#         end
#     end
# end

# struct DatasetContainer{T}
#     variables::Dict{Symbol, Union{AbstractArray, Dict}}
#     function DatasetContainer()
#         return new(Dict{Symbol, Union{AbstractArray, Dict}}())
#     end
# end
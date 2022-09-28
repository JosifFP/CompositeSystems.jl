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

#AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
#AbstractWModels = Union{AbstractWRModels, AbstractBFModel}

""
mutable struct MutableNetwork
    areas::Dict{Int,<:Any}
    bus::Dict{Int,<:Any}
    dcline::Dict{Int,<:Any}
    gen::Dict{Int,<:Any}
    branch::Dict{Int,<:Any}
    storage::Dict{Int,<:Any}
    switch::Dict{Int,<:Any}
    shunt::Dict{Int,<:Any}
    load::Dict{Int,<:Any}
    baseMVA::Int
    per_unit::Bool

    arcs_from::Vector{Tuple{Int, Int, Int}}
    arcs_to::Vector{Tuple{Int, Int, Int}}
    arcs::Vector{Tuple{Int, Int, Int}}
    arcs_from_dc::Vector{Tuple{Int, Any, Any}}
    arcs_to_dc::Vector{Tuple{Int, Any, Any}}
    arcs_dc::Vector{Tuple{Int, Any, Any}}
    arcs_from_sw::Vector{Tuple{Int, Any, Any}}
    arcs_to_sw::Vector{Tuple{Int, Any, Any}}
    arcs_sw::Vector{Tuple{Int, Any, Any}}

    bus_gens::Dict{Int, <:Any}
    bus_loads::Dict{Int, <:Any}
    bus_shunts::Dict{Int, <:Any}
    bus_storage::Dict{Int, <:Any}
    bus_arcs_dc::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    bus_arcs_sw::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    bus_arcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Dict{String, <:Any}} 
    ref_buses::Dict{Int, <:Any}

    function MutableNetwork(network::Network)

        return new(network.areas, network.bus, network.dcline, network.gen, network.branch, network.storage, 
        network.switch, network.shunt, network.load, network.baseMVA, network.per_unit, 
        network.arcs_from, network.arcs_to, network.arcs, network.arcs_from_dc, 
        network.arcs_to_dc, network.arcs_dc, network.arcs_from_sw, network.arcs_to_sw, network.arcs_sw, 
        network.bus_gens, network.bus_loads, network.bus_shunts, network.bus_storage, network.bus_arcs_dc, 
        network.bus_arcs_sw, network.bus_arcs, network.buspairs, network.ref_buses
        )

    end
end

"a macro for adding the standard AbstractPowerModel fields to a type definition"
CompositeAdequacy.@def pm_fields begin
    
    model::JuMP.AbstractModel
    ref::MutableNetwork
    var::Dict{Symbol,<:Any}
    sol::Dict{Symbol,<:Any}
    #ext::Dict{Symbol,<:Any}

end

mutable struct ACPowerModel <: AbstractACPowerModel @pm_fields end
mutable struct DCPowerModel <: AbstractDCPowerModel @pm_fields end

"Types of optimization"
abstract type DCMPPowerModel <: AbstractDCPowerModel end
abstract type DCOPF <: AbstractDCPowerModel end
abstract type Transportation <: AbstractDCPowerModel end
LCDCMethod = Union{DCOPF, Transportation}

"Constructor for an AbstractPowerModel modeling object"
function BuildAbstractPowerModel!(PowerModel::Type{<:AbstractPowerModel}, model::JuMP.AbstractModel, network::MutableNetwork) where {N}

    pm = PowerModel(
        model,
        network,
        Dict{Symbol, Any}(),
        Dict{Symbol, Any}()
        #Dict{Symbol, Any}()
    )
    return pm
end

""
function RestartAbstractPowerModel!(pm::AbstractPowerModel, network::MutableNetwork)

    if JuMP.isempty(pm.model)==false JuMP.empty!(pm.model) end
    network
    empty!(pm.var)
    empty!(pm.sol)
    #empty!(pm.ext)
    return
end

""
function initialize_ref(network::Network{N})  where {N}

    data = Dict{Symbol,Any}(
        :bus => network.bus,
        :dcline => network.dcline,
        :gen => network.gen,
        :branch => network. branch,
        :storage => network.storage,
        :switch => network.switch,
        :shunt => network.shunt,
        :areas => network.areas,
        :load => network.load
    )

    return data

end

# ""
# function _initialize_dict_from_ref(ref::Dict{Symbol, <:Any})

#     dict = Dict{Symbol, Any}(:nw => Dict{Int, Any}())

#     for nw in keys(ref[:nw])
#         dict[:nw][nw] = Dict{Symbol, Any}()
#     end

#     return dict
# end

ext(pm::AbstractPowerModel) = pm.ext
ext(pm::AbstractPowerModel, key::Symbol) = pm.ext[key]

ids(pm::AbstractPowerModel, key::Symbol) = keys(getfield(pm.ref, key))

ref(pm::AbstractPowerModel) = pm.ref
ref(pm::AbstractPowerModel, key::Symbol) = getfield(pm.ref, key)
ref(pm::AbstractPowerModel, key::Symbol, idx) = getfield(pm.ref, key)[idx]
ref(pm::AbstractPowerModel, key::Symbol, idx, param::String) =  getfield(pm.ref, key)[idx][param]

var(pm::AbstractPowerModel) = pm.var
var(pm::AbstractPowerModel, key::Symbol) = pm.var[key]
var(pm::AbstractPowerModel, key::Symbol, idx) = pm.var[key][idx]

con(pm::AbstractPowerModel) = pm.con
con(pm::AbstractPowerModel, key::Symbol) = pm.con[key]
con(pm::AbstractPowerModel, key::Symbol, idx) = pm.con[key][idx]

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
#************************************************************************************************
# File is mostly based on InfrastructureModels.jl without any dependencies.
#************************************************************************************************

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

"a macro for adding the standard AbstractPowerModel fields to a type definition"
CompositeAdequacy.@def pm_fields begin
    
    model::JuMP.AbstractModel
    ref::Dict{Symbol,<:Any}
    var::Dict{Symbol,<:Any}
    sol::Dict{Symbol,<:Any}
    ext::Dict{Symbol,<:Any}

end

mutable struct ACPowerModel <: AbstractACPowerModel @pm_fields end
mutable struct DCPowerModel <: AbstractDCPowerModel @pm_fields end

"Types of optimization"
abstract type DCMPPowerModel <: AbstractDCPowerModel end
abstract type DCOPF <: AbstractDCPowerModel end
abstract type Transportation <: AbstractDCPowerModel end
LCDCMethod = Union{DCOPF, Transportation}

"Constructor for an AbstractPowerModel modeling object"
function InitializeAbstractPowerModel(PowerModel::Type{<:AbstractPowerModel}, model::JuMP.AbstractModel) where {N}

    @assert PowerModel <: AbstractPowerModel

    pm = PowerModel(
        model,
        Dict{Symbol,Any}(),
        Dict{Symbol,Any}(),
        Dict{Symbol,Any}(),
        Dict{Symbol,Any}()
    )
    
    return pm
end

""
function RestartAbstractPowerModel!(pm::AbstractPowerModel, dictionary::Dict{Symbol, <:Any})

    if JuMP.isempty(pm.model)==false JuMP.empty!(pm.model) end

    ref = Dict{Symbol, Any}(:nw => Dict{Int, Any}(0 => dictionary))
    pm.ref = ref
    pm.var = _initialize_dict_from_ref(ref)
    pm.sol = _initialize_dict_from_ref(ref)
    pm.ext = _initialize_dict_from_ref(ref)
    return
end

""
function BuildAbstractPowerModel!(PowerModel::Type{<:AbstractPowerModel}, model::JuMP.AbstractModel, dictionary::Dict{Symbol, <:Any}) where {N}

    @assert PowerModel <: AbstractPowerModel
    
    ref = dictionary
    var = _initialize_dict_from_ref(ref)
    sol = _initialize_dict_from_ref(ref)
    ext = _initialize_dict_from_ref(ref)

    pm = PowerModel(
        model,
        ref,
        var,
        sol,
        ext
    )
    return pm
end

""
function initialize_ref(network::Network{N}; multinetwork=true)  where {N}

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

    nws_data = Dict{Symbol,Any}(
        :nw => Dict{Int, Any}(),
        #:base => data,
        #:multinetwork => multinetwork,
        #:per_unit => network.per_unit,
        #:baseMVA => network.baseMVA
    )

    # Build a multinetwork representation of the data.
    if multinetwork == true
        for i in 0:N
            get!(nws_data[:nw], i, data)
        end
    else
        get!(nws_data[:nw], 0, data)
    end

    return nws_data

end

function _initialize_dict_from_ref(ref::Dict{Symbol, <:Any})

    dict = Dict{Symbol, Any}(:nw => Dict{Int, Any}())

    for nw in keys(ref[:nw])
        dict[:nw][nw] = Dict{Symbol, Any}()
    end

    return dict
end


nw_ids(pm::AbstractPowerModel) = keys(pm.ref[:nw])
nws(pm::AbstractPowerModel) = pm.ref[:nw]

ext(pm::AbstractPowerModel) = pm.ext[:nw]
ext(pm::AbstractPowerModel, nw::Int) = pm.ext[:nw][nw]
ext(pm::AbstractPowerModel, nw::Int, key::Symbol) = pm.ext[:nw][nw][key]

ids(pm::AbstractPowerModel, nw::Int, key::Symbol) = keys(pm.ref[:nw][nw][key])
ids(pm::AbstractPowerModel, key::Symbol; nw::Int=0) = keys(pm.ref[:nw][nw][key])

ref(pm::AbstractPowerModel, nw::Int) = pm.ref[:nw][nw]
ref(pm::AbstractPowerModel, nw::Int, key::Symbol) = pm.ref[:nw][nw][key]
ref(pm::AbstractPowerModel, nw::Int, key::Symbol, idx) = pm.ref[:nw][nw][key][idx]
ref(pm::AbstractPowerModel, nw::Int, key::Symbol, idx, param::String) = pm.ref[:nw][nw][key][idx][param]

# base(pm::AbstractPowerModel) = pm.ref[:base]
# base(pm::AbstractPowerModel, key::Symbol) = pm.ref[:base][key]
# base(pm::AbstractPowerModel, key::Symbol, idx) = pm.ref[:base][key][idx]
# base(pm::AbstractPowerModel, key::Symbol, idx, param::String) = pm.ref[:base][key][idx][param]

ref(pm::AbstractPowerModel; nw::Int=0) = pm.ref[:nw][nw]
ref(pm::AbstractPowerModel, key::Symbol; nw::Int=0) = pm.ref[:nw][nw][key]
ref(pm::AbstractPowerModel, key::Symbol, idx; nw::Int=0) = pm.ref[:nw][nw][key][idx]
ref(pm::AbstractPowerModel, key::Symbol, idx, param::String; nw::Int=0) = pm.ref[:nw][nw][key][idx][param]

var(pm::AbstractPowerModel, nw::Int) = pm.var[:nw][nw]
var(pm::AbstractPowerModel, nw::Int, key::Symbol) = pm.var[:nw][nw][key]
var(pm::AbstractPowerModel, nw::Int, key::Symbol, idx) = pm.var[:nw][nw][key][idx]

var(pm::AbstractPowerModel; nw::Int=0) = pm.var[:nw][nw]
var(pm::AbstractPowerModel, key::Symbol; nw::Int=0) = pm.var[:nw][nw][key]
var(pm::AbstractPowerModel, key::Symbol, idx; nw::Int=0) = pm.var[:nw][nw][key][idx]

con(pm::AbstractPowerModel, nw::Int) = pm.con[:nw][nw]
con(pm::AbstractPowerModel, nw::Int, key::Symbol) = pm.con[:nw][nw][key]
con(pm::AbstractPowerModel, nw::Int, key::Symbol, idx) = pm.con[:nw][nw][key][idx]

con(pm::AbstractPowerModel; nw::Int=0) = pm.con[:nw][nw]
con(pm::AbstractPowerModel, key::Symbol; nw::Int=0) = pm.con[:nw][nw][key]
con(pm::AbstractPowerModel, key::Symbol, idx; nw::Int=0) = pm.con[:nw][nw][key][idx]

sol(pm::AbstractPowerModel, nw::Int, args...) = _sol(pm.sol[:nw][nw], args...)
sol(pm::AbstractPowerModel, key::Symbol) = pm.sol[:nw][0][key]
sol(pm::AbstractPowerModel, args...; nw::Int=0) = _sol(pm.sol[:nw][nw], args...)

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


# function InitializeAbstractPowerModel(
#     PowerModel::Type{<:AbstractPowerModel}, ref::Dict{Symbol, <:Any}, optimizer; multinetwork=false) where {N}

#     @assert PowerModel <: AbstractPowerModel

#     #if isempty(ref) == true ref = initialize_ref(network; multinetwork) end

#     if optimizer === nothing
#         JuMPmodel = JuMP.Model()
#         @debug "The optimization model has no optimizer attached"
#     else
#         model = JuMP.direct_model(optimizer)
#         JuMP.set_string_names_on_creation(model, false)
#         #model = JuMP.Model(optimizer, add_bridges=false)
#     end

#     var = _initialize_dict_from_ref(ref)
#     con = _initialize_dict_from_ref(ref)
#     sol = _initialize_dict_from_ref(ref)
#     ext = _initialize_dict_from_ref(ref)

#     pm = PowerModel(
#         model,
#         ref,
#         var,
#         con,
#         sol,
#         ext,
#     )
    
#     return pm

# end
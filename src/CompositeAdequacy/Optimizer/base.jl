macro def(name, definition)
    return quote
        macro $(esc(name))()
            esc($(Expr(:quote, definition)))
        end
    end
end

"a macro for adding the standard InfrastructureModels fields to a type definition"
CompositeAdequacy.@def pm_fields begin
    model::Union{Model, Nothing}
    data::Dict{String,<:Any}
    solution::Dict{String,<:Any}
    ref::Union{Dict{Symbol,<:Any}, Nothing}
end

"Types of optimization"
abstract type AbstractPowerModel end
abstract type AbstractACPModel <: AbstractPowerModel end
abstract type AbstractDCPModel <: AbstractPowerModel end

mutable struct DCMLPowerModel <: AbstractDCPModel @pm_fields end
mutable struct DCPPowerModel <: AbstractDCPModel @pm_fields end
mutable struct ACMLPowerModel <: AbstractACPModel @pm_fields end
mutable struct ACPPowerModel <: AbstractACPModel @pm_fields end

function InitializeAbstractPowerModel(data::Dict{String, <:Any}, PowerModel::Type{DCPPowerModel}, optimizer)

    #@assert PowerModel <: AbstractDCPModel || PowerModel <: AbstractACPModel
    ref = ref_initialize!(data)
    ref_add!(ref)

    pm = PowerModel(
        JuMP.direct_model(optimizer[1]),
        data["load"],
        Dict{String,Any}(), # empty solution data
        ref
    )

    JuMP.set_silent(pm.model)
    return pm

end

function InitializeAbstractPowerModel(data::Dict{String, <:Any}, PowerModel::Type{DCMLPowerModel}, optimizer)

    #@assert PowerModel <: AbstractDCPModel || PowerModel <: AbstractACPModel
    ref = ref_initialize!(data)
    ref_add!(ref)

    pm = PowerModel(
        JuMP.direct_model(optimizer[2]),
        #JuMP.Model(optimizer[2]),
        data["load"],
        Dict{String,Any}(), # empty solution data
        ref
    )
    JuMP.set_silent(pm.model)
    return pm
    
end

function InitializeAbstractPowerModel(data::Dict{String, <:Any}, PowerModel::Type{DCPPowerModel})

    pm = PowerModel(
        nothing, 
        data,
        Dict{String,Any}(), 
        nothing
    )

    push!(pm.solution, 
    "termination_status"    => "No optimizer used",  
    "optimizer"             => "No optimizer used",
    "solution"              => Dict{String,Any}()
    )
    return pm

end
macro def(name, definition)
    return quote
        macro $(esc(name))()
            esc($(Expr(:quote, definition)))
        end
    end
end

"Types of optimization"
abstract type AbstractPowerModel end

"a macro for adding the standard InfrastructureModels fields to a type definition"
CompositeAdequacy.@def pm_fields begin
    model::Union{Model, Nothing}
    dictionary::Dict{Symbol,<:Any}
    ref::Dict{Symbol,<:Any}
    load_curtailment::Dict{Int,<:Any}
    termination_status::String
end

abstract type OPFMethod <: AbstractPowerModel end
abstract type LMOPFMethod <: AbstractPowerModel end
mutable struct AbstractACPModel <: AbstractPowerModel @pm_fields end
mutable struct AbstractDCPModel <: AbstractPowerModel @pm_fields end


function InitializeAbstractPowerModel(ref::Dict{Symbol, <:Any}, PowerModel::Type{<:AbstractPowerModel}, optimizer)

    ref_add!(ref)
    
    pm = PowerModel(
        JuMP.direct_model(optimizer),
        deepcopy(ref),
        ref,
        Dict{Int,Any}(),
        ""
    )
    return pm

end
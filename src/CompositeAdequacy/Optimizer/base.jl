macro def(name, definition)
    return quote
        macro $(esc(name))()
            esc($(Expr(:quote, definition)))
        end
    end
end

"Types of optimization"
abstract type AbstractPowerModel end
abstract type OPFMethod <: AbstractPowerModel end
abstract type LMOPFMethod <: AbstractPowerModel end

"a macro for adding the standard InfrastructureModels fields to a type definition"
CompositeAdequacy.@def pm_fields begin
    model::Model
    ref::Dict{Symbol,<:Any}
    load_curtailment::Dict{Int,<:Any}
    type::Union{Type{<:AbstractPowerModel}, Nothing}
    termination_status::Int
end

mutable struct AbstractACPModel <: AbstractPowerModel @pm_fields end
mutable struct AbstractDCPModel <: AbstractPowerModel @pm_fields end

function InitializeAbstractPowerModel(network::Network, dictionary::Dict{Symbol, <:Any}, PowerModel::Type{<:AbstractPowerModel}, optimizer)

    model = JuMP.direct_model(optimizer)
    #model = JuMP.Model(optimizer, add_bridges=false)
    JuMP.set_string_names_on_creation(model, false)

    pm = PowerModel(
        model,
        #JuMP.Model(optimizer, add_bridges=false),
        #fill_dictionary!(network, dictionary),
        dictionary,
        Dict{Int,Any}(),
        nothing,
        0
    )
    
    return pm

end
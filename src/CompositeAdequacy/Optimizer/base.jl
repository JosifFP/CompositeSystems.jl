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
    sol::Dict{Symbol,<:Any}

end

mutable struct ACPowerModel <: AbstractACPowerModel @pm_fields end
struct DCPowerModel <: AbstractDCPowerModel @pm_fields end

"Types of optimization"
abstract type DCMPPowerModel <: AbstractDCPowerModel end
abstract type DCOPF <: AbstractDCPowerModel end
abstract type Transportation <: AbstractDCPowerModel end
LCDCMethod = Union{DCOPF, Transportation}

"Constructor for an AbstractPowerModel modeling object"
function BuildAbstractPowerModel!(PowerModel::Type{<:AbstractPowerModel}, model::JuMP.AbstractModel)

    pm = PowerModel(
        model,
        Dict{Symbol, Any}()
    )
    return pm
end


#var(pm::AbstractPowerModel) = pm.var
#var(pm::AbstractPowerModel, key::Symbol) = pm.var[key]
#var(pm::AbstractPowerModel, key::Symbol, idx) = pm.var[key][idx]
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
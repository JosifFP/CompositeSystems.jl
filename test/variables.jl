import BenchmarkTools: @btime
import JuMP: JuMP, VariableRef

abstract type OptimizationContainerKey end 
abstract type VariableType end
abstract type va <: VariableType end


struct VariableKey{T <: VariableType} <: OptimizationContainerKey 
    var::Symbol
end

function VariableKey(var::Type{T}) where {T <: VariableType}
    return VariableKey{T}(Symbol(var))
end


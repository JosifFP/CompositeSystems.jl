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

"a macro for adding the standard AbstractPowerModel fields to a type definition"
CompositeAdequacy.@def ca_fields begin
    
    model::AbstractModel
    topology:: Topology
    var::Dict{Symbol,<:Any}

end

"Types of optimization"
struct AbstractDCOPF <: AbstractDCPowerModel @ca_fields end
struct AbstractACOPF <: AbstractACPowerModel @ca_fields end

"Constructor for an AbstractPowerModel modeling object"
function PowerFlowProblem(PowerModel::Type{<:AbstractPowerModel}, model::AbstractModel, topology:: Topology)

    @assert PowerModel <: AbstractPowerModel

    var = Dict{Symbol, Any}(
        :va => Array{Int, VariableRef}[],
        :pg => Dict{Int, VariableRef}(),
        :p => Dict{Tuple{Int, Int, Int}, Any}(),
        :plc => Dict{Int, VariableRef}()
        #:vm => Dict{Int, VariableRef}(),
        #:qg => Dict{Int, VariableRef}(),
        #:q => Dict{Tuple{Int, Int, Int}, Any}(),
        #:qlc => Dict{Int, VariableRef}()
    )

    return PowerModel(model, topology, var)

end

include("Optimizer/utils.jl")
include("Optimizer/variables.jl")
include("Optimizer/constraints.jl")
include("Optimizer/Optimizer.jl")
include("Optimizer/solution.jl")



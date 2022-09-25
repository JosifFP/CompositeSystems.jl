"""
    num_variables(model::Model)::Int64

Returns number of variables in `model`.
"""
num_variables(model::Model)::Int64 = MOI.get(model, MOI.NumberOfVariables())

"""
    empty!(model::Model)::Model

Empty the model, that is, remove all variables, constraints and model
attributes but not optimizer attributes. Always return the argument.

Note: removes extensions data.
"""
function Base.empty!(model::Model)::Model
    # The method changes the Model object to, basically, the state it was when
    # created (if the optimizer was already pre-configured). The exceptions
    # are:
    # * optimize_hook: it is basically an optimizer attribute and we promise
    #   to leave them alone (as do MOI.empty!).
    # * bridge_types: for consistency with MOI.empty! for
    #   MOI.Bridges.LazyBridgeOptimizer.
    # * operator_counter: it is just a counter for a single-time warning
    #   message (so keeping it helps to discover inefficiencies).
    MOI.empty!(model.moi_backend)
    empty!(model.shapes)
    model.nlp_model = nothing
    empty!(model.obj_dict)
    empty!(model.ext)
    model.is_model_dirty = false
    return model
end


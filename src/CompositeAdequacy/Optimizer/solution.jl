""
function build_result!(pm::AbstractDCPowerModel, system::SystemModel, t::Int)

    plc = build_sol_values(var(pm, :plc))

    if termination_status(pm.model) == LOCALLY_SOLVED
        for i in field(system, Loads, :keys)
            if haskey(plc, i) == false
                get!(plc, i, field(system, Loads, :pd)[i,t])
            end
            field(pm.topology, :plc)[i,t] = plc[i]
        end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model))")        
    end

    if sum(field(pm.topology, :plc)[:,t]) > 0 println("t=$(t), total_curtailed_load=$(sum(field(pm.topology, :plc)[:,t]))") end

end

""
function build_results!(pm::AbstractDCPowerModel, system::SystemModel, t::Int)

    #plc = sol(pm)[:plc] = build_sol_values(pm.var[:plc])
    plc = build_sol_values(var(pm, :plc))

    if termination_status(pm.model) == LOCALLY_SOLVED
        for i in field(system, Loads, :keys)
            if haskey(plc, i) == false
                get!(plc, i, field(system, Loads, :pd)[i,t])
            end
        end
    #else
        #for i in field(system, Loads, :keys)
        #    get!(plc, i, Float16(0.0))
        #end        
    end

    for r in field(system, Loads, :keys)
        pm.topology.plc[r,t] = CompositeAdequacy.sol(pm, :plc)[r]
    end

end

""
function term_status(model::Model, status::JuMP.MathOptInterface.TerminationStatusCode)

    if status == LOCALLY_SOLVED || status == OPTIMAL
        status = 1
    elseif status == INFEASIBLE || status == LOCALLY_INFEASIBLE
        status = 2
    elseif status == ITERATION_LIMIT || status == TIME_LIMIT
        status = 3
    elseif status == OPTIMIZE_NOT_CALLED
        status = 4
    else
        #if result_count <= 0 
        #    status = 5
        if isempty(model) == true 
            status = 5
        else 
            status = 6 
        end
    end
end

function result_counts(model::Model)
    result_count = 1
    try
        result_count = result_count(model)
    catch
        Memento.warn(_LOGGER, "the given optimizer does not provide the ResultCount() attribute, assuming the solver returned a solution which may be incorrect.");
    end
end

""
function build_sol_values(var::Dict)

    sol = Dict{Int, Float16}()

    for (key, val) in var
        val_r = abs(build_sol_values(val))
        if val_r > 1e-4
            sol[key] = Float16(val_r)
        else
            sol[key] = Float16(0.0)
        end
    end

    return sol
end

""
function build_sol_values(var::Array{<:Any,1})
    return [build_sol_values(val) for val in var]
end

""
function build_sol_values(var::Array{<:Any,2})
    return [build_sol_values(var[i, j]) for i in 1:size(var, 1), j in 1:size(var, 2)]
end

""
function build_sol_values(var::Number)
    return var
end

""
function build_sol_values(var::VariableRef)
    return JuMP.value(var)
end

""
function build_sol_values(var::GenericAffExpr)
    return JuMP.value(var)
end

""
function build_sol_values(var::GenericQuadExpr)
    return JuMP.value(var)
end

""
function build_sol_values(var::NonlinearExpression)
    return JuMP.value(var)
end

""
function build_sol_values(var::ConstraintRef)
    return dual(var)
end

""
function build_sol_values(var::Any)
    Memento.warn(_LOGGER, "build_solution_values found unknown type $(typeof(var))")
    return var
end


# ""
# function get_loads_sol!(curt_loads::Dict{Int,<:Any}, pm::AbstractDCPModel, type::Type)
#     return get_loads_sol!(curt_loads, pm, type)
# end


# ""
# function get_buses_sol!(tmp, pm::AbstractDCPModel)

#     for (i, bus) in pm.ref[:bus]
#         if bus["bus_type"] ≠ 4
#             get!(tmp, i, Dict("va"=>Float16(value(pm.model[:va][bus["index"]]))))
#         end
#     end
#     return tmp
# end

# ""
# function get_gens_sol!(tmp, pm::AbstractDCPModel)

#     for (i, gen) in pm.ref[:gen]
#         if gen["gen_status"] ≠ 0
#             get!(tmp, i, Dict("qg"=>0.0, "pg"=>Float16(value(pm.model[:pg][gen["index"]]))))
#         end
#     end
#     return tmp
# end

# ""
# function get_branches_sol!(tmp, pm::AbstractDCPModel)

#     for (i, branch) in pm.ref[:branch]
#         if branch["br_status"]≠ 0  
#             get!(tmp, i, Dict("qf"=>0.0, "qt"=>0.0,        
#             "pt" => float(-value(pm.model[:p][(branch["index"],branch["f_bus"],branch["t_bus"])])),
#             "pf" => float(value(pm.model[:p][(branch["index"],branch["f_bus"],branch["t_bus"])])))
#             )
#         end
#     end
#     return tmp
# end

# ""
# function guard_objective_value(opf_model)
#     obj_val = NaN
#     try
#         obj_val = JuMP.objective_value(opf_model)
#     catch
#     end
#     return obj_val
# end

# ""
# function guard_objective_bound(opf_model)
#     obj_lb = -Inf
#     try
#         obj_lb = JuMP.objective_bound(opf_model)
#     catch
#     end
#     return obj_lb
# end

# ""
# function build_solution!(pm::AbstractDCPModel)
    
#     pm.solution["solution"][:bus]              = get_buses_sol!(Dict{Int64,Dict{String,Float16}}(), pm)
#     #pm.solution["solution"]["gen"]              = get_gens_sol!(Dict{Int64,Dict{String,Float16}}(), pm)
#     pm.solution["solution"][:branch]           = get_branches_sol!(Dict{Int64,Dict{String,Float16}}(), pm)
#     pm.solution["solution"][:load_initial], 
#     pm.solution["solution"][:load], 
#     pm.solution["solution"][:load_curtailment] = get_loads_sol!(Dict{Int64,Dict{String,Float16}}(), pm)
#     # pm.solution["solution"]["total"]            = Dict(
#     #                                             "total_Pg"            => sum([pm.solution["solution"]["gen"][i]["pg"] for i in keys(pm.solution["solution"]["gen"])]),
#     #                                             "total_P_load_before" => sum([pm.solution["solution"]["load_initial"][i]["pl"] for i in keys(pm.solution["solution"]["load_initial"])]),
#     #                                             "total_P_load_after"  => sum([pm.solution["solution"]["load"][i]["pl"] for i in keys(pm.solution["solution"]["load"])]),
#     #                                             "P_load_curtailed"    => sum([pm.solution["solution"]["load_curtailment"][i]["pl"] for i in keys(pm.solution["solution"]["load_curtailment"])]),
#     #                                             "P_balance_mismatch"  => sum([pm.solution["solution"]["gen"][i]["pg"] for i in keys(pm.solution["solution"]["gen"])])-
#     #                                                                     sum([pm.solution["solution"]["load"][i]["pl"] for i in keys(pm.solution["solution"]["load"])])
#     # )
        
#     #pm.solution["primal_status"] = JuMP.primal_status(pm.model)
#     #pm.solution["dual_status"] = JuMP.dual_status(pm.model)
#     #pm.solution["objective"] = guard_objective_value(pm.model)
#     #pm.solution["objective_lb"] => guard_objective_bound(pm.model)
#     #pm.solution["solve_time"] => solve_time,
#     #pm.solution["solution_details"] => JuMP.solution_summary(pm.model, verbose=false)
    
# end
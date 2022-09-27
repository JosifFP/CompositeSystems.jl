""
function build_result!(pm::AbstractDCPowerModel, type::Type; nw::Int=0)

    result_count = 1
    try
        result_count = JuMP.result_count(pm.model)
    catch
        Memento.warn(_LOGGER, "the given optimizer does not provide the ResultCount() attribute, assuming the solver returned a solution which may be incorrect.");
    end

    if result_count <= 0 
        #Memento.warn(_LOGGER, "model has no results, solution cannot be built")
        ext(pm,nw)[:termination_status] = termination_status = 2
    elseif JuMP.isempty(pm.model) == true
        ext(pm,nw)[:termination_status] = termination_status = 0
    end

    status = JuMP.termination_status(pm.model)
    #termination_status: 0=Nothing / 1=JuMP.LOCALLY_SOLVED / 2="No results available" / <3="Any other status"
    if status == JuMP.LOCALLY_SOLVED || status == JuMP.OPTIMAL
        ext(pm,nw)[:termination_status] = termination_status = 1
    elseif status == JuMP.INFEASIBLE || status == JuMP.LOCALLY_INFEASIBLE
        ext(pm,nw)[:termination_status] = termination_status = 3
    elseif status == JuMP.ITERATION_LIMIT || status == JuMP.TIME_LIMIT
        ext(pm,nw)[:termination_status] = termination_status = 4
    elseif status == JuMP.OPTIMIZE_NOT_CALLED
        ext(pm,nw)[:termination_status] = termination_status = 5
    else
        ext(pm,nw)[:termination_status] = termination_status = 6
    end

    load_dict =  ext(pm, nw)[:load_initial]
    #ext(pm,nw)[:load_curtailment]
    get_loads_sol!(pm, Dict{Int,Dict{String,Float16}}(), load_dict, termination_status, type, nw)
    
end

# ""
# function get_loads_sol!(curt_loads::Dict{Int,<:Any}, pm::AbstractDCPModel, type::Type)
#     return get_loads_sol!(curt_loads, pm, type)
# end

""
function get_loads_sol!(pm::AbstractDCPowerModel, curt_loads::Dict{Int,<:Any}, load_dict::Dict{Int,<:Any}, termination_status::Int, type::Type, nw::Int)

    p_lc = build_sol_values(sol(pm, nw, :load_curtailment))

    if termination_status == 1 && type == Type{<:LCDCMethod}
        for (i, load) in load_dict
            if haskey(p_lc, string(i)) == true
                if JuMP.value(p_lc[string(i)]["p_lc"])>1e-4            
                    get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> Float16(p_lc[string(i)]["p_lc"])))
                else
                    get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> 0.0))
                end
            else
                get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> Float16(load["pd"])))
            end
    
        end
    else
        for key in keys(load_dict)
            get!(curt_loads, key, Dict("ql"=>0.0, "pl"=> 0.0))
        end
    end

    return sol(pm, nw)[:load_curtailment] = curt_loads

end
""
# ""
# function get_buses_sol!(tmp, pm::AbstractDCPModel)

#     for (i, bus) in pm.ref[:bus]
#         if bus["bus_type"] ≠ 4
#             get!(tmp, i, Dict("va"=>Float16(JuMP.value(pm.model[:va][bus["index"]]))))
#         end
#     end
#     return tmp
# end

# ""
# function get_gens_sol!(tmp, pm::AbstractDCPModel)

#     for (i, gen) in pm.ref[:gen]
#         if gen["gen_status"] ≠ 0
#             get!(tmp, i, Dict("qg"=>0.0, "pg"=>Float16(JuMP.value(pm.model[:pg][gen["index"]]))))
#         end
#     end
#     return tmp
# end

# ""
# function get_branches_sol!(tmp, pm::AbstractDCPModel)

#     for (i, branch) in pm.ref[:branch]
#         if branch["br_status"]≠ 0  
#             get!(tmp, i, Dict("qf"=>0.0, "qt"=>0.0,        
#             "pt" => float(-JuMP.value(pm.model[:p][(branch["index"],branch["f_bus"],branch["t_bus"])])),
#             "pf" => float(JuMP.value(pm.model[:p][(branch["index"],branch["f_bus"],branch["t_bus"])])))
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

""
function build_sol_values(var::Dict)

    sol = Dict{String, Any}()

    for (key, val) in var
        sol[string(key)] = build_sol_values(val)
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
function build_sol_values(var::JuMP.VariableRef)
    return JuMP.value(var)
end

""
function build_sol_values(var::JuMP.GenericAffExpr)
    return JuMP.value(var)
end

""
function build_sol_values(var::JuMP.GenericQuadExpr)
    return JuMP.value(var)
end

""
function build_sol_values(var::JuMP.NonlinearExpression)
    return JuMP.value(var)
end

""
function build_sol_values(var::JuMP.ConstraintRef)
    return JuMP.dual(var)
end

""
function build_sol_values(var::Any)
    Memento.warn(_LOGGER, "build_solution_values found unknown type $(typeof(var))")
    return var
end
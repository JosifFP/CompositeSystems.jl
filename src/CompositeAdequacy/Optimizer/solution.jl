""
function build_result!(pm::AbstractPowerModel, load_dict::Dict{Int, <:Any})
    
    result_count = 1
    try
        result_count = JuMP.result_count(pm.model)
    catch
        Memento.warn(_LOGGER, "the given optimizer does not provide the ResultCount() attribute, assuming the solver returned a solution which may be incorrect.");
    end

    if result_count <= 0 
        #Memento.warn(_LOGGER, "model has no results, solution cannot be built")
        pm.termination_status = 2
    elseif JuMP.isempty(pm.model) == true
        pm.termination_status = 0
    end

    status = JuMP.termination_status(pm.model)
    #termination_status: 0=Nothing / 1=JuMP.LOCALLY_SOLVED / 2="No results available" / <3="Any other status"
    if status == JuMP.LOCALLY_SOLVED || status == JuMP.OPTIMAL
        pm.termination_status = 1
    elseif status == JuMP.INFEASIBLE || status == JuMP.LOCALLY_INFEASIBLE
        pm.termination_status = 3
    elseif status == JuMP.ITERATION_LIMIT || status == JuMP.TIME_LIMIT
        pm.termination_status = 4
    elseif status == JuMP.OPTIMIZE_NOT_CALLED
        pm.termination_status = 5
    else
        pm.termination_status = 6
    end

    pm.load_curtailment = get_loads_sol!(pm, Dict{Int,Dict{String,Float16}}(), load_dict, pm.type)

    return pm.load_curtailment
    
end

# ""
# function get_loads_sol!(curt_loads::Dict{Int,<:Any}, pm::AbstractDCPModel, type::Type)
#     return get_loads_sol!(curt_loads, pm, type)
# end

""
function get_loads_sol!(pm::AbstractPowerModel, curt_loads::Dict{Int,<:Any}, load_dict::Dict{Int,<:Any}, type::Type{LMOPFMethod})

    if pm.termination_status == 1
        for (i, load) in load_dict
            if load["status"]≠ 0 && haskey(pm.ref[:load], i) == true
                if JuMP.value(pm.model[:plc][load["index"]])>1e-4            
                    get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> Float16(JuMP.value(pm.model[:plc][load["index"]]))))
                    #actual load    
                    #get!(loads, i, Dict("ql"=>0.0, "pl"=> Float16(load["pd"]-JuMP.value(pm.model[:plc][load["index"]]))))
                else
                    get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> 0.0))
                    #get!(loads, i, Dict("ql"=>0.0, "pl"=> Float16(load["pd"])))
                end
            else
                get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> Float16(load["pd"])))
                #get!(loads, i, Dict("ql"=>0.0, "pl"=> 0.0)) 
            end

        end
    else
        println("check")
        for key in keys(load_dict)
            get!(curt_loads, key, Dict("ql"=>0.0, "pl"=> 0.0))
        end        
    end

    return curt_loads

end

""
function get_loads_sol!(pm::AbstractPowerModel, curt_loads::Dict{Int,<:Any}, load_dict::Dict{Int,<:Any}, type::Type{OPFMethod})

    for key in keys(load_dict)
        get!(curt_loads, key, Dict("ql"=>0.0, "pl"=> 0.0))
    end

    return curt_loads
end

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
"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
"""

"Transportation"
function build_method!(pm::AbstractNFAModel, system::SystemModel, t)
 
    var_gen_power(pm, system, nw=t)
    var_branch_power(pm, system, nw=t)
    var_load_curtailment(pm, system, nw=t)

    # Add Constraints
    # ---------------
    for i in assetgrouplist(topology(pm, :buses_idxs))
        constraint_power_balance(pm, system, i, nw=t)
    end

    #for i in assetgrouplist(topology(pm, :branches_idxs))
    #    constraint_thermal_limits(pm, system, i, t)
    #end

    objective_min_load_curtailment(pm, system, nw=t)
    return

end

"Load Minimization version of DCOPF"
function build_method!(pm::Union{AbstractDCMPPModel, AbstractDCPModel}, system::SystemModel, t)
    # Add Optimization and State Variables
    var_bus_voltage(pm, system, nw=t)
    var_gen_power(pm, system, nw=t)
    var_branch_power(pm, system, nw=t)
    var_load_curtailment(pm, system, nw=t)
    #variable_storage_power_mi(pm)
    #var_dcline_power(pm)

    # Add Constraints
    # ---------------
    for i in field(system, :ref_buses)
        constraint_theta_ref(pm, i, nw=t)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        constraint_power_balance(pm, system, i, nw=t)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        constraint_ohms_yt(pm, system, i, nw=t)
        constraint_voltage_angle_diff(pm, system, i, nw=t)
        #constraint_thermal_limits(pm, system, i, t)
    end

    # for i in ids(pm, :dcline)
    #     constraint_dcline_power_losses(pm, i)
    # end
    objective_min_load_curtailment(pm, system, nw=t)
    return

end

""
function build_opf!(pm::PM_AbstractDCPModel, system::SystemModel, t)
    # Add Optimization and State Variables
    var_bus_voltage(pm, system, nw=t)
    var_gen_power(pm, system, nw=t)
    var_branch_power(pm, system, nw=t)
    #variable_storage_power_mi(pm)
    #var_dcline_power(pm)

    # Add Constraints
    # ---------------
    for i in field(system, :ref_buses)
        constraint_theta_ref(pm, i, nw=t)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        constraint_power_balance(pm, system, i, nw=t)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        constraint_ohms_yt(pm, system, i, nw=t)
        constraint_voltage_angle_diff(pm, system, i, nw=t)
        #constraint_thermal_limits(pm, system, i, t)
    end

    # for i in ids(pm, :dcline)
    #     constraint_dcline_power_losses(pm, i)
    # end
    #objective_min_cost(pm, system, nw=t)
    objective_min_fuel_and_flow_cost(pm, system, nw=t)
    return

end

""
function objective_min_fuel_and_flow_cost(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    for i in system.generators.keys
        cost = reverse(system.generators.cost[i])
        pg = var(pm, :pg, nw)[i]
        if length(cost) == 1
            gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1])
        elseif length(cost) == 2
            gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1] + cost[2]*pg)
        elseif length(cost) == 3
            gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1] + cost[2]*pg + cost[3]*pg^2)
        else
            gen_cost[i] = JuMP.@NLexpression(pm.model, 0.0)
        end
    end

    return JuMP.@NLobjective(pm.model, MIN_SENSE, sum(gen_cost[i] for i in eachindex(gen_idxs)))
    
end


""
function objective_min_load_curtailment(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1)

    # gen_cost = Dict{Int, Any}()
    # gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    # for i in system.generators.keys
    #     cost = reverse(system.generators.cost[i])
    #     gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1] + cost[2]*var(pm, :pg, nw)[i])
    # end

    # fg = JuMP.@NLexpression(pm.model, sum(gen_cost[i] for i in eachindex(gen_idxs)))

    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in assetgrouplist(topology(pm, :loads_idxs))))

    return @objective(pm.model, MIN_SENSE, fd)
    
end

function optimize_method!(model::Model)
    optimize!(model; ignore_optimize_hook = true)
end

""
function build_result!(pm::AbstractDCPowerModel, system::SystemModel, t::Int)

    plc = build_sol_values(var(pm, :plc, t))

    if termination_status(pm.model) == LOCALLY_SOLVED
        for i in field(system, :loads, :keys)
            if haskey(plc, i) == false
                get!(plc, i, field(system, :loads, :pd)[i,t])
            end
            sol(pm, :plc)[i,t] = getindex(plc, i)
        end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model))")        
    end

end


""
function build_sol_values(var::DenseAxisArray)

    sol = Dict{Int, Float16}()

    for key in axes(var)[1]
        val_r = abs(build_sol_values(var[key]))
        sol[key] = Float16(val_r)
    end

    return sol
end

""
function build_sol_values(var::Dict)

    sol = Dict{Int, Float16}()

    for (key, val) in var
        val_r = abs(build_sol_values(val))
        sol[key] = Float16(val_r)
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
    @warn("build_solution_values found unknown type $(typeof(var))")
    return var
end


# index representing which side the HVDC line is starting
#from_idx = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])
#lc = @expression(pm.model, #sum(gen["cost"][1]*model[:pg][i]^2 + gen["cost"][2]*model[:pg][i] + gen["cost"][3] for (i,gen) in ref[:gen]) +
#sum(dcline["cost"][1]*model[:p_dc][from_idx[i]]^2 + dcline["cost"][2]*model[:p_dc][from_idx[i]] + dcline["cost"][3] for (i,dcline) in ref[:dcline]) +
#sum(ref[:load][i]["cost"]*model[:plc][i] for i in keys(ref[:load]))
#sum(pm.ref[:load][i]["cost"]*pm.model[:plc][i] for i in keys(pm.ref[:load])))
# Objective Function: minimize load curtailment

# ""
# function optimization!(pm::AbstractPowerModel, type::Type)
    
#     #JuMP.set_time_limit_sec(pm.model, 2.0)
#     JuMP.optimize!(pm.model)

#     # if JuMP.termination_status(pm.model) ≠ JuMP.LOCALLY_SOLVED && type == DCOPF
#     #     JuMP.set_time_limit_sec(pm.model, 2.0)
#     #     var_buspair_current_magnitude_sqr(pm)
#     #     var_bus_voltage_magnitude_sqr(pm)
#     #     for i in ids(pm, :branch)
#     #         constraint_voltage_magnitude_diff(pm, i)
#     #     end
#     #     JuMP.optimize!(pm.model)
#     # end
    
#     return

# end


    #if sum(sol(pm, :plc)[:,t]) > 0 
        #println("t=$(t), total_curtailed_load=$(sol(pm, :plc)[:,t])")
        #println("t=$(t), total_curtailed_load=$(sol(pm, :plc)[:,t]), $(assetgrouplist(topology(pm, :branches_idxs)))") 
    #else
        #println("t=$(t), $(assetgrouplist(topology(pm, :branches_idxs)))") 
    #end
    #if sum(sol(pm, :plc, t)) > 0 println("t=$(t)") end

# ""
# function term_status(model::Model, status::JuMP.MOI.TerminationStatusCode)

#     if status == LOCALLY_SOLVED || status == OPTIMAL
#         status = 1
#     elseif status == INFEASIBLE || status == LOCALLY_INFEASIBLE
#         status = 2
#     elseif status == ITERATION_LIMIT || status == TIME_LIMIT
#         status = 3
#     elseif status == OPTIMIZE_NOT_CALLED
#         status = 4
#     else
#         #if result_count <= 0 
#         #    status = 5
#         if isempty(model) == true 
#             status = 5
#         else 
#             status = 6 
#         end
#     end
# end

# function result_counts(model::Model)
#     result_count = 1
#     try
#         result_count = result_count(model)
#     catch
#         @warn(_LOGGER, "the given optimizer does not provide the ResultCount() attribute, assuming the solver returned a solution which may be incorrect.");
#     end
# end

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
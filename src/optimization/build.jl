"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
"""

"Load Minimization version of OPF"
function build_method!(pm::AbstractPowerModel, system::SystemModel, t)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system)
    var_branch_power(pm, system)
    var_load_curtailment(pm, system, t)
    var_storage_power_mi(pm, system)

    objective_min_stor_load_curtailment(pm, system)

    # Add Constraints
    # ---------------

    con_model_voltage(pm, system)

    for i in field(system, :ref_buses)
        con_theta_ref(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :loads_idxs))
        con_power_factor(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        con_power_balance(pm, system, i, t)
    end

    for i in assetgrouplist(topology(pm, :storages_idxs))
        con_storage_state(pm, system, i) # Model only considers initial stored energy (1 period).
        con_storage_complementarity_mi(pm, system, i)
        con_storage_losses(pm, system, i)
        con_storage_thermal_limit(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        con_ohms_yt(pm, system, i)
        con_voltage_angle_difference(pm, system, i)
        con_thermal_limits(pm, system, i)
    end

    return

end

"Load Minimization version of OPF"
function build_method!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system, states, t)
    var_branch_power(pm, system, states, t)
    var_load_curtailment(pm, system, t)

    #objective_min_load_curtailment(pm, system)
    objective_min_stor_load_curtailment(pm, system)

    # Add Constraints
    # ---------------
    con_model_voltage(pm, system)

    for i in field(system, :ref_buses)
        con_theta_ref(pm, system, i)
    end

    for i in field(system, :loads, :keys)
        con_power_factor(pm, system, i)
    end

    for i in field(system, :buses, :keys)
        #if field(system, :buses, :bus_type)[i] != 4
            con_power_balance(pm, system, i, t)
        #end
    end

    for i in field(system, :branches, :keys)
        if field(states, :branches)[i,t] ≠ 0
            con_ohms_yt(pm, system, i)
            con_voltage_angle_difference(pm, system, i)
            con_thermal_limits(pm, system, i)
        end
    end

    return

end

"Load Minimization version of OPF"
function build_method_stor!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system, states, t)
    var_branch_power(pm, system, states, t)
    var_load_curtailment(pm, system, t)
    var_storage_power_mi(pm, system, states, t)

    objective_min_stor_load_curtailment(pm, system)

    # Add Constraints
    # ---------------
    con_model_voltage(pm, system)
    
    for i in field(system, :ref_buses)
        con_theta_ref(pm, system, i)
    end

    for i in field(system, :loads, :keys)
        con_power_factor(pm, system, i)
    end

    for i in field(system, :buses, :keys)
        con_power_balance(pm, system, i, t)
    end
    
    for i in field(system, :storages, :keys)
        if field(states, :storages)[i,t] ≠ 0
            con_storage_state(pm, system, states, i, t)
            con_storage_complementarity_mi(pm, system, i)
            con_storage_losses(pm, system, i)
            con_storage_thermal_limit(pm, system, i)
        end
    end

    for i in field(system, :branches, :keys)
        if field(states, :branches)[i,t] ≠ 0
            con_ohms_yt(pm, system, i)
            con_voltage_angle_difference(pm, system, i)
            con_thermal_limits(pm, system, i)
        end
    end

    return

end


""
function _build_opf!(pm::AbstractPowerModel, system::SystemModel, t)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system)
    var_branch_power(pm, system)
    var_load_curtailment(pm, system, t)
    var_storage_power_mi(pm, system)

    objective_min_fuel_and_flow_cost(pm, system)

    # Add Constraints
    # ---------------
    for i in field(system, :ref_buses)
        con_theta_ref(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :loads_idxs))
        con_power_factor(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        con_power_balance(pm, system, i, t)
    end

    for i in assetgrouplist(topology(pm, :storages_idxs))
        con_storage_state(pm, system, i) # Model only considers initial stored energy (1 period).
        con_storage_complementarity_mi(pm, system, i)
        con_storage_losses(pm, system, i)
        con_storage_thermal_limit(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        con_ohms_yt(pm, system, i)
        con_voltage_angle_difference(pm, system, i)
        con_thermal_limits(pm, system, i)
    end

    return

end

"Load Minimization version of DCOPF"
function update_method!(pm::AbstractNFAModel, system::SystemModel, states::SystemStates, t::Int)
    
    update_var_gen_power(pm, system, states, t)
    update_var_branch_power(pm, system, states, t)

    for i in field(system, :loads, :keys)
        update_var_load_curtailment_real(pm, system, states, i, t)
        update_var_load_curtailment_imaginary(pm, system, states, i, t)
    end

    for i in field(system, :buses, :keys)
        update_con_power_balance(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
    end

    return

end

"Load Minimization version of DCOPF"
function update_method!(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
    
    update_var_gen_power(pm, system, states, t)
    update_var_branch_power(pm, system, states, t)

    for i in field(system, :loads, :keys)
        update_var_load_curtailment_real(pm, system, states, i, t)
        update_var_load_curtailment_imaginary(pm, system, states, i, t)
    end

    for i in field(system, :buses, :keys)
        update_con_power_balance(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
    end

    if all(view(states.branches,:,t)) ≠ true || all(view(states.branches,:,t-1)) ≠ true
        active_branches = assetgrouplist(topology(pm, :branches_idxs))
        JuMP.delete(pm.model, con(pm, :ohms_yt_from_p, 1).data)
        add_con_container!(pm.con, :ohms_yt_from_p, active_branches)
        for i in active_branches
            con_ohms_yt(pm, system, i)
        end
    end

    return

end

"Load Minimization version of DCOPF"
function update_method!(pm::AbstractDCPLLModel, system::SystemModel, states::SystemStates, t::Int)
    
    #if any(i -> i==4,view(states.buses, :, t-1)) == true var_bus_voltage(pm, system) end
    update_var_gen_power(pm, system, states, t)
    update_var_branch_power(pm, system, states, t)

    for i in field(system, :loads, :keys)
        update_var_load_curtailment_real(pm, system, states, i, t)
        update_var_load_curtailment_imaginary(pm, system, states, i, t)
    end

    for i in field(system, :buses, :keys)
        update_con_power_balance(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
    end

    if all(view(states.branches,:,t)) ≠ true || all(view(states.branches,:,t-1)) ≠ true

        active_branches = assetgrouplist(topology(pm, :branches_idxs))
        JuMP.delete(pm.model, con(pm, :ohms_yt_from_p, 1).data)
        JuMP.delete(pm.model, con(pm, :ohms_yt_to_p, 1).data)
        add_con_container!(pm.con, :ohms_yt_from_p, active_branches)
        add_con_container!(pm.con, :ohms_yt_to_p, active_branches)
        for i in active_branches
            con_ohms_yt(pm, system, i)
        end
    end
    return

end

"Load Minimization version of ACOPF"
function update_method!(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, t::Int)
    
    update_var_gen_power(pm, system, states, t)
    update_var_branch_power(pm, system, states, t)

    for i in field(system, :loads, :keys)
        update_var_load_curtailment_real(pm, system, states, i, t)
        update_var_load_curtailment_imaginary(pm, system, states, i, t)
    end

    for i in field(system, :buses, :keys)
        update_con_power_balance(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
    end

    if all(view(states.branches,:,t)) ≠ true || all(view(states.branches,:,t-1)) ≠ true

        active_branches = assetgrouplist(topology(pm, :branches_idxs))
        JuMP.delete(pm.model, con(pm, :ohms_yt_from_p, 1).data)
        JuMP.delete(pm.model, con(pm, :ohms_yt_to_p, 1).data)
        JuMP.delete(pm.model, con(pm, :ohms_yt_from_q, 1).data)
        JuMP.delete(pm.model, con(pm, :ohms_yt_to_q, 1).data)

        add_con_container!(pm.con, :ohms_yt_from_p, active_branches)
        add_con_container!(pm.con, :ohms_yt_to_p, active_branches)
        add_con_container!(pm.con, :ohms_yt_from_q, active_branches)
        add_con_container!(pm.con, :ohms_yt_to_q, active_branches)

        for i in active_branches
            con_ohms_yt(pm, system, i)
        end
    end
    return

end

""
function objective_min_fuel_and_flow_cost(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    for i in system.generators.keys
        cost = reverse(system.generators.cost[i])
        pg = var(pm, :pg, nw)[i]
        if length(cost) == 1
            gen_cost[i] = @expression(pm.model, cost[1])
        elseif length(cost) == 2
            gen_cost[i] = @expression(pm.model, cost[1] + cost[2]*pg)
        #elseif length(cost) == 3
            #gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1] + cost[2]*pg + cost[3]*pg^2)
        else
            @error("Nonlinear problems not supported")
            gen_cost[i] = @expression(pm.model, 0.0)
        end
    end

    fg = @expression(pm.model, sum(gen_cost[i] for i in eachindex(gen_idxs)))
    return JuMP.@objective(pm.model, MIN_SENSE, fg)
    
end

""
function objective_min_gen_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    for i in system.generators.keys
        cost = field(system, :generators, :cost)[i]
        pg = var(pm, :pg, nw)[i]
        if length(cost) == 1
            gen_cost[i] = @expression(pm.model, cost[1])
        elseif length(cost) == 2
            gen_cost[i] = @expression(pm.model, cost[1]*pg + cost[2])
        elseif length(cost) == 3

            gen_cost[i] = @expression(pm.model, cost[1]*0.0 + cost[2]*pg + cost[3])

            # This linearization is not supported by Gurobi, due to RotatedSecondOrderCone.
            # pmin = field(system, :generators, :pmin)[i]
            # pmax = field(system, :generators, :pmax)[i]
            # pg_sqr_ub = max(pmin^2, pmax^2)
            # pg_sqr_lb = 0.0
            # if pmin > 0.0
            #     pg_sqr_lb = pmin^2
            # end
            # if pmax < 0.0
            #     pg_sqr_lb = pmax^2
            # end
            #pg_sqr = @variable(pm.model, lower_bound = pg_sqr_lb, upper_bound = pg_sqr_ub, start = 0.0)
            #@constraint(pm.model, [0.5, pg_sqr, pg] in JuMP.RotatedSecondOrderCone())
            #gen_cost[i] = @expression(pm.model,cost[1]*pg_sqr + cost[2]*pg + cost[3])

        else
            #@error("Nonlinear problems not supported. Length=$(length(cost)), $(cost)")
            gen_cost[i] = 0.0
        end
    end

    stor_cost = minimum(system.loads.cost)*0.5
    fg = @expression(pm.model, sum(gen_cost[i] for i in eachindex(gen_idxs)))
    fe = @expression(pm.model, stor_cost*sum(field(system, :storages, :energy_rating)[i] - var(pm, :se, nw)[i] for i in field(system, :storages, :keys)))
    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))
    
    @objective(pm.model, MIN_SENSE, fg+fd+fe)
    
end

""
function objective_min_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    fe = @expression(pm.model, 1000*sum(field(system, :storages, :energy_rating)[i] - var(pm, :se, nw)[i] for i in field(system, :storages, :keys)))
    f_fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*field(system, :loads, :firm_load)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))
    c_fd = @expression(pm.model, sum(1100*(field(system, :loads, :firm_load)[i]-1.0)*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))
    return @objective(pm.model, MIN_SENSE, f_fd+c_fd+fe)
    
end

""
function objective_min_load_curtailment(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))
    return @objective(pm.model, MIN_SENSE, fd)
    
end

function optimize_method!(pm::AbstractPowerModel)

    #optimize!(model; ignore_optimize_hook = true)
    _ = JuMP.optimize!(pm.model)
    #_ = optimize!(pm.model; ignore_optimize_hook = true)
    return
end

""
function build_result!(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1)

    plc = build_sol_values(var(pm, :plc, nw))
    se = build_sol_values(var(pm, :se, nw))

    if termination_status(pm.model) == LOCALLY_SOLVED || termination_status(pm.model) == OPTIMAL
        for i in field(system, :loads, :keys)
            if haskey(plc, i) == false
                get!(plc, i, field(system, :loads, :pd)[i,t])
            end
            states.plc[i,t] = abs.(getindex(plc, i))
        end
        for i in field(system, :storages, :keys)
            if haskey(se, i) == false
                get!(se, i, 0.0)
            end
            states.se[i,t] = getindex(se, i)
        end
        #if sum(states.plc[:,t]) > 0  && states.branches[9,t] == false
        #if sum(states.plc[5,t]) > 0
         #   println("t=$(t), plc = $(states.plc[:,t]), branches = $(states.branches[:,t]), gens = $(states.generators[:,t])")  end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model))")        
    end
    return

end

""
function build_result!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1)

    plc = build_sol_values(var(pm, :plc, nw))
    qlc = build_sol_values(var(pm, :qlc, nw))
    se = build_sol_values(var(pm, :se, nw))

    if termination_status(pm.model) == LOCALLY_SOLVED || termination_status(pm.model) == OPTIMAL
        for i in field(system, :loads, :keys)
            if haskey(plc, i) == false
                get!(plc, i, field(system, :loads, :pd)[i,t])
            end
            if haskey(qlc, i) == false
                get!(qlc, i, field(system, :loads, :pd)[i,t]*field(system, :loads, :pf)[i])
            end
            states.plc[i,t] = abs.(getindex(plc, i))
            states.qlc[i,t] = abs.(getindex(qlc, i))
        end
        for i in field(system, :storages, :keys)
            if haskey(se, i) == false
                get!(se, i, 0.0)
            end
            states.se[i,t] = getindex(se, i)
        end
        #if sum(states.plc[:,t]) > 0  println("t=$(t), PLC = $(sum(states.plc[:,t]))")  end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model))")        
    end
    return

end

""
function build_sol_values(var::DenseAxisArray)

    sol = Dict{Int, Float64}()

    for key in axes(var)[1]
        val_r = build_sol_values(var[key])
        sol[key] = val_r
    end

    return sol
end

""
function build_sol_values(var::Dict)

    sol = Dict{Int, Float64}()

    for (key, val) in var
        val_r = build_sol_values(val)
        sol[key] = val_r
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
    return dual(var)
end

""
function build_sol_values(var::Any)
    @warn("build_solution_values found unknown type $(typeof(var))")
    return var
end
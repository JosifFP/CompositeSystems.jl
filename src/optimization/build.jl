"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
"""

"Load Minimization version of DCOPF"
function build_method!(pm::Union{AbstractDCMPPModel, AbstractDCPModel}, system::SystemModel, t)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system)
    var_branch_power(pm, system)
    var_load_curtailment(pm, system, t)
    var_storage_power_mi(pm, system)

    #objective_min_load_curtailment(pm, system)
    objective_min_fuel_and_flow_cost(pm, system)

    # Add Constraints
    # ---------------
    for i in field(system, :ref_buses)
        constraint_theta_ref(pm, i)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        constraint_power_balance(pm, system, i, t)
    end

    for i in assetgrouplist(topology(pm, :storages_idxs))
        constraint_storage_state(pm, system, i) # Model only considers initial stored energy (1 period).
        constraint_storage_complementarity_mi(pm, system, i)
        constraint_storage_losses(pm, system, i)
        constraint_storage_thermal_limit(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        constraint_ohms_yt(pm, system, i)
        constraint_voltage_angle_diff(pm, system, i)
    end

    return

end

""
function build_opf!(pm::Union{AbstractDCMPPModel, AbstractDCPModel}, system::SystemModel, t)

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
        constraint_theta_ref(pm, i)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        constraint_power_balance(pm, system, i, t)
    end

    for i in assetgrouplist(topology(pm, :storages_idxs))
        constraint_storage_state(pm, system, i) # Model only considers initial stored energy (1 period).
        constraint_storage_complementarity_mi(pm, system, i)
        constraint_storage_losses(pm, system, i)
        constraint_storage_thermal_limit(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        constraint_ohms_yt(pm, system, i)
        constraint_voltage_angle_diff(pm, system, i)
    end

    return

end

"Load Minimization version of DCOPF"
function build_method!(pm::Union{AbstractDCMPPModel, AbstractDCPModel}, system::SystemModel, states::SystemStates, t)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system, states, t)
    var_branch_power(pm, system, states, t)
    var_load_curtailment(pm, system, t)
    var_storage_power_mi(pm, system, states, t)
    #var_storage_power_mi(pm, system)

    objective_min_load_curtailment(pm, system, states, t)
    #objective_min_load_curtailment(pm, system)
    #objective_min_fuel_and_flow_cost(pm, system)

    # Add Constraints
    # ---------------
    for i in field(system, :ref_buses)
        constraint_theta_ref(pm, i)
    end

    for i in field(system, :buses, :keys)
        constraint_power_balance(pm, system, i, t)
    end

    for i in field(system, :storages, :keys)
        if field(states, :storages)[i,t] ≠ 0
            constraint_storage_state(pm, system, states, i, t)
            constraint_storage_complementarity_mi(pm, system, i)
            constraint_storage_losses(pm, system, i)
            constraint_storage_thermal_limit(pm, system, i)
        end
    end

    for i in field(system, :branches, :keys)
        if field(states, :branches)[i,t] ≠ 0
            constraint_ohms_yt(pm, system, i)
            constraint_voltage_angle_diff(pm, system, i)
        end
    end

    return

end

"Load Minimization version of DCOPF"
function update_method!(pm::Union{AbstractDCMPPModel, AbstractDCPModel}, system::SystemModel, states::SystemStates, t::Int)

    update_var_gen_power(pm, system, states, t)
    update_var_branch_power(pm, system, states, t)
    update_var_load_curtailment(pm, system, states, t)
    update_var_storage_complementary_indicator(pm, system, states, t)
    
    update_constraint_power_balance(pm, system, states, t)
    update_constraint_voltage_angle_diff(pm, system, states, t)
    update_constraint_storage(pm, system, states, t)

    if all(view(states.branches,:,t)) ≠ true

        JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
        add_con_container!(pm.con, :ohms_yt_from, assetgrouplist(topology(pm, :branches_idxs)))

        for i in assetgrouplist(topology(pm, :branches_idxs))
            constraint_ohms_yt(pm, system, i)
        end
        
    end

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
    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))

    return JuMP.@objective(pm.model, MIN_SENSE, fd+fg)
    
end

""
function objective_min_load_curtailment(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1)

    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))
    return @objective(pm.model, MIN_SENSE, fd)
    
end

""
function objective_min_load_curtailment(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1)

    #fd = @expression(pm.model, sum(field(system, :loads, :cost)[field(system, :storages, :buses)i](-var(pm, :sc, nw)[i]/(1.001-sum(system.loads.pd[:,t])/topology(pm, :Peak)[t])) for i in field(system, :storages, :keys)))
    
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
    fe = @expression(pm.model, 3000*sum(field(system, :storages, :energy_rating)[i] - var(pm, :se, nw)[i] for i in field(system, :storages, :keys)))
    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))

    return @objective(pm.model, MIN_SENSE, fd+fg+fe)
    
end

function optimize_method!(pm::AbstractDCPowerModel)

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
        #println("solved, t=$(t), PLC=$(sum(sol(pm, :plc)[:,t]))")  
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
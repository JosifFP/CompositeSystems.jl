#***************************************************** VARIABLES *************************************************************************
""
function update_var_gen_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    update_var_gen_power_real(pm, system, states, t)
    update_var_gen_power_imaginary(pm, system, states, t)
end

""
function update_var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)

    pg = var(pm, :pg, 1)

    for l in eachindex(field(system, :generators, :keys))
        JuMP.set_upper_bound(pg[l], field(system, :generators, :pmax)[l]*field(states, :generators)[l,t])
        JuMP.set_lower_bound(pg[l], 0.0)
    end

end

"Model ignores reactive power flows"
function update_var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function update_var_branch_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    update_var_branch_power_real(pm, system, states, t)
    update_var_branch_power_imaginary(pm, system, states, t)
end

""
function update_var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)


    p = var(pm, :p, 1)

    for (l,i,j) in topology(pm, :arcs)

        if typeof(p[(l,i,j)]) ==JuMP.AffExpr
            p_var = first(keys(p[(l,i,j)].terms))
        elseif typeof(p[(l,i,j)]) ==JuMP.VariableRef
            p_var = p[(l,i,j)]
        else
            @error("Expression $(typeof(p[(l,i,j)])) not supported")
        end

        JuMP.set_lower_bound(p_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
        JuMP.set_upper_bound(p_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])

    end


end

"DC models ignore reactive power flows"
function update_var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function update_var_load_curtailment(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    update_var_load_curtailment_real(pm, system, states, t)
    update_var_load_curtailment_imaginary(pm, system, states, t)
end


""
function update_var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    plc = var(pm, :plc, 1)
    for l in eachindex(field(system, :loads, :keys))
        JuMP.set_upper_bound(plc[l], field(system, :loads, :pd)[l,t]*field(states, :loads)[l,t])
        JuMP.set_lower_bound(plc[l],0.0)
    end

end

"Model ignores reactive power flows"
function update_var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
end



#***************************************************** CONSTRAINTS *************************************************************************
""
function update_constraint_power_balance(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)

    for i in field(system, :buses, :keys)
        loads_nodes = topology(pm, :loads_nodes)[i]
        shunts_nodes = topology(pm, :shunts_nodes)[i]

        JuMP.set_normalized_rhs(con(pm, :power_balance, 1)[i], 
            sum(pd for pd in Float16.([field(system, :loads, :pd)[k,t] for k in loads_nodes]))
            + sum(gs for gs in Float16.([field(system, :shunts, :gs)[k]*field(states, :branches)[k,t] for k in shunts_nodes]))*1.0^2
        )
    end

    return

end

""
function update_constraint_voltage_angle_diff(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)

    for l in field(system, :branches, :keys)

        f_bus = field(system, :branches, :f_bus)[l]
        t_bus = field(system, :branches, :t_bus)[l]    
        buspair = topology(pm, :buspairs)[(f_bus, t_bus)]
        if field(states, :branches)[l,t] ≠ 0
            JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, 1)[l], buspair[3])
            JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, 1)[l], buspair[2])
        else
            JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, 1)[l], Inf)
            JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, 1)[l],-Inf)
        end

    end

    return

end
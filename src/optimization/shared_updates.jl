#***************************************************** VARIABLES *************************************************************************

""
function update_var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    if field(system, :buses, :bus_type)[i] != 3
        if field(states, :buses)[i,t] == 4
            JuMP.set_upper_bound(var(pm, :va, 1)[i], 0)
            JuMP.set_lower_bound(var(pm, :va, 1)[i], 0.0)
        else
            if JuMP.has_upper_bound(var(pm, :va, 1)[i]) && JuMP.has_lower_bound(var(pm, :va, 1)[i]) 
                JuMP.delete_upper_bound(var(pm, :va, 1)[i])
                JuMP.delete_lower_bound(var(pm, :va, 1)[i])
            end
        end
    end

end

""
function update_var_gen_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; force_pmin=false)

    JuMP.set_upper_bound(var(pm, :pg, 1)[i], field(system, :generators, :pmax)[i]*field(states, :generators_de)[i,t])
    
    if force_pmin
        JuMP.set_lower_bound(var(pm, :pg, 1)[i], field(system, :generators, :pmin)[i]*field(states, :generators_de)[i,t])
    else
        JuMP.set_lower_bound(var(pm, :pg, 1)[i], 0.0)
    end

end

""
function update_var_gen_power_imaginary(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    JuMP.set_upper_bound(var(pm, :qg, 1)[i], field(system, :generators, :qmax)[i]*field(states, :generators_de)[i,t])
    JuMP.set_lower_bound(var(pm, :qg, 1)[i], field(system, :generators, :qmin)[i]*field(states, :generators_de)[i,t])
end

""
function update_var_branch_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, arc::Tuple{Int, Int, Int}, t::Int)
    
    l,i,j = arc

    if typeof(var(pm, :p, 1)[arc]) == JuMP.AffExpr
        p_var = first(keys(var(pm, :p, 1)[arc].terms))
    elseif typeof(var(pm, :p, 1)[arc]) == JuMP.VariableRef
        p_var = var(pm, :p, 1)[arc]
    else
        @error("Expression $(typeof(var(pm, :p, 1)[arc])) not supported")
    end

    JuMP.set_lower_bound(p_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    JuMP.set_upper_bound(p_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])

end

""
function update_var_branch_power_imaginary(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, arc::Tuple{Int, Int, Int}, t::Int)

    l,i,j = arc

    if typeof(var(pm, :q, 1)[arc]) == JuMP.AffExpr
        q_var = first(keys(var(pm, :q, 1)[arc].terms))
    elseif typeof(var(pm, :q, 1)[arc]) == JuMP.VariableRef
        q_var = var(pm, :q, 1)[arc]
    else
        @error("Expression $(typeof(var(pm, :q, 1)[arc])) not supported")
    end

    JuMP.set_lower_bound(q_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    JuMP.set_upper_bound(q_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])

end

""
function update_var_buspair_cosine(pm::AbstractPowerModel, bp::Tuple{Int,Int})
end

"Defines load power factor variables to represent curtailed load in objective function"
function update_var_load_power_factor(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    if isempty(topology(pm, :loads_nodes)[i])
        JuMP.set_upper_bound(var(pm, :z_demand, 1)[i], 0)
    else
        JuMP.set_upper_bound(var(pm, :z_demand, 1)[i], 1)
    end
    
end

#***************************************************** STORAGE VAR UPDATES *************************************************************************
""
function update_con_storage(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    se_1 = field(states, :se)[i,t-1]
    JuMP.set_normalized_rhs(con(pm, :storage_state, 1)[i], se_1)
end

"Not needed"
function update_var_storage_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    ps = var(pm, :ps, 1)
    JuMP.set_lower_bound(ps[i], max(-Inf, -field(system, :storages, :thermal_rating)[i])*field(states, :storages)[i,t])
    JuMP.set_upper_bound(ps[i], min(Inf,  field(system, :storages, :thermal_rating)[i])*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_energy(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    se = var(pm, :se, 1)
    JuMP.set_lower_bound(se[i], 0)
    JuMP.set_upper_bound(se[i], field(system, :storages, :energy_rating)[i]*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_charge(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    sc = var(pm, :sc, 1)
    JuMP.set_lower_bound(sc[i], 0)
    JuMP.set_upper_bound(sc[i], field(system, :storages, :charge_rating)[i]*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_discharge(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    sd = var(pm, :sc, 1)
    for i in eachindex(field(system, :storages, :keys))
        JuMP.set_lower_bound(sd[i], 0)
        JuMP.set_upper_bound(sd[i], field(system, :storages, :discharge_rating)[i]*field(states, :storages)[i,t])
    end

end


#***************************************************UPDATES CONSTRAINTS ****************************************************************

function update_con_thermal_limits(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    if hasfield(Branches, :rate_a)
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, 1)[i], (field(system, :branches, :rate_a)[i]^2)*field(states, :branches)[i,t])
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, 1)[i], (field(system, :branches, :rate_a)[i]^2)*field(states, :branches)[i,t])
    end
    
end

""
function update_con_voltage_angle_difference(pm::AbstractPolarModels, bp::Tuple{Int,Int}; nw::Int=1)

    f_bus,t_bus = bp
    buspair = topology(pm, :buspairs)[bp]
    if !ismissing(buspair)
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, 1)[(f_bus, t_bus)], buspair[3])
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, 1)[(f_bus, t_bus)], buspair[2])
    else
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, 1)[(f_bus, t_bus)], Inf)
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, 1)[(f_bus, t_bus)],-Inf)
    end

end

""
function reset_con_voltage_angle_difference(pm::AbstractPolarModels, buspair::Vector{Tuple{Int, Int}})

    JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
    JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)
    add_con_container!(pm.con, :voltage_angle_diff_upper, buspair)
    add_con_container!(pm.con, :voltage_angle_diff_lower, buspair)

end

""
function reset_con_model_voltage(pm::AbstractPowerModel, buspair::Vector{Tuple{Int, Int}})
end
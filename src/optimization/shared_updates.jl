#***************************************************** VARIABLES *************************************************************************

""
function update_var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    
    va = var(pm, :va, nw)[i]
    if field(system, :buses, :bus_type)[i] != 3
        if field(states, :buses)[i,t] == 4
            JuMP.set_upper_bound(va, 0)
            JuMP.set_lower_bound(va, 0)
        else
            if JuMP.has_upper_bound(va) && JuMP.has_lower_bound(va) 
                JuMP.delete_upper_bound(va)
                JuMP.delete_lower_bound(va)
            end
        end
    end
end

""
function update_var_gen_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1, force_pmin=false)

    JuMP.set_upper_bound(var(pm, :pg, nw)[i], field(system, :generators, :pmax)[i]*field(states, :generators)[i,t])
    if force_pmin
        JuMP.set_lower_bound(var(pm, :pg, nw)[i], field(system, :generators, :pmin)[i]*field(states, :generators)[i,t])
    else
        JuMP.set_lower_bound(var(pm, :pg, nw)[i], 0.0)
    end

end

""
function update_var_gen_power_imaginary(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)

    JuMP.set_upper_bound(var(pm, :qg, nw)[i], field(system, :generators, :qmax)[i]*field(states, :generators)[i,t])
    JuMP.set_lower_bound(var(pm, :qg, nw)[i], field(system, :generators, :qmin)[i]*field(states, :generators)[i,t])
    
end

"Defines load power factor variables to represent curtailed load in objective function"
function update_var_load_power_factor(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)

    z_demand = var(pm, :z_demand, nw)[i]
    if field(states, :buses)[i,t] == 4
        if isempty(topology(pm, :bus_loads)[i])
            #JuMP.fix(z_demand, 0, force=true)
            JuMP.set_upper_bound(z_demand, 0)
            JuMP.set_lower_bound(z_demand, 0)
        else
            JuMP.set_upper_bound(z_demand, 1)
            JuMP.set_lower_bound(z_demand, 0)
        end
    else
        JuMP.set_upper_bound(z_demand, 1)
        JuMP.set_lower_bound(z_demand, 0)
    end
end

""
function update_var_branch_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, arc::Tuple{Int, Int, Int}, t::Int; nw::Int=1)
    
    l,_,_ = arc

    if typeof(var(pm, :p, nw)[arc]) == JuMP.AffExpr
        p_var = first(keys(var(pm, :p, nw)[arc].terms))
    elseif typeof(var(pm, :p, nw)[arc]) == JuMP.VariableRef
        p_var = var(pm, :p, nw)[arc]
    else
        @error("Expression $(typeof(var(pm, :p, 1)[arc])) not supported")
    end

    JuMP.set_lower_bound(p_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    JuMP.set_upper_bound(p_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])

end

""
function update_var_branch_power_imaginary(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, arc::Tuple{Int, Int, Int}, t::Int; nw::Int=1)

    l,_,_ = arc

    if typeof(var(pm, :q, nw)[arc]) == JuMP.AffExpr
        q_var = first(keys(var(pm, :q, 1)[arc].terms))
    elseif typeof(var(pm, :q, nw)[arc]) == JuMP.VariableRef
        q_var = var(pm, :q, nw)[arc]
    else
        @error("Expression $(typeof(var(pm, :q, 1)[arc])) not supported")
    end

    JuMP.set_lower_bound(q_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    JuMP.set_upper_bound(q_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])

end

#***************************************************** STORAGE VAR UPDATES *************************************************************************
""
function update_con_storage(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    se_1 = @view states.se[i,t-1]
    JuMP.set_normalized_rhs(con(pm, :storage_state, nw)[i], se_1)
end

"Not needed"
function update_var_storage_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    
    ps = var(pm, :ps, nw)[i]
    JuMP.set_lower_bound(ps, max(-Inf, -field(system, :storages, :thermal_rating)[i])*field(states, :storages)[i,t])
    JuMP.set_upper_bound(ps, min(Inf,  field(system, :storages, :thermal_rating)[i])*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_energy(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    
    se = var(pm, :se, nw)[i]
    JuMP.set_lower_bound(se, 0)
    JuMP.set_upper_bound(se, field(system, :storages, :energy_rating)[i]*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_charge(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    
    sc = var(pm, :sc, nw)[i]
    JuMP.set_lower_bound(sc, 0)
    JuMP.set_upper_bound(sc, field(system, :storages, :charge_rating)[i]*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_discharge(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    
    sd = var(pm, :sc, nw)[i]
    for i in eachindex(field(system, :storages, :keys))
        JuMP.set_lower_bound(sd, 0)
        JuMP.set_upper_bound(sd, field(system, :storages, :discharge_rating)[i]*field(states, :storages)[i,t])
    end

end


#***************************************************UPDATES CONSTRAINTS ****************************************************************

"Branch - Ohm's Law Constraints"
function update_con_ohms_yt(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[i]
    t_bus = field(system, :branches, :t_bus)[i]
    g, b = calc_branch_y(field(system, :branches), i)
    tr, ti = calc_branch_t(field(system, :branches), i)
    tm = field(system, :branches, :tap)[i]

    va_fr  = var(pm, :va, nw)[f_bus]
    va_to  = var(pm, :va, nw)[t_bus]

    g_fr = field(system, :branches, :g_fr)[i]
    b_fr = field(system, :branches, :b_fr)[i]
    g_to = field(system, :branches, :g_to)[i]
    b_to = field(system, :branches, :b_to)[i]

    _update_con_ohms_yt_from(pm, states, i, t, nw, f_bus, t_bus, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    _update_con_ohms_yt_to(pm, states, i, t, nw, f_bus, t_bus, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)

end

""
function update_con_thermal_limits(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)
    JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, nw)[l], (field(system, :branches, :rate_a)[l]^2)*field(states, :branches)[l,t])
    JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, nw)[l], (field(system, :branches, :rate_a)[l]^2)*field(states, :branches)[l,t])
end
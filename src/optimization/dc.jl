
#***************************************************** VARIABLES *************************************************************************
""
function var_branch_indicator(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

""
function var_bus_voltage_on_off(pm::AbstractDCPowerModel, system::SystemModel; kwargs...)
    var_bus_voltage_angle(pm, system; kwargs...)
end

"nothing to do, no voltage angle variables"
function var_bus_voltage_on_off(pm::AbstractNFAModel, system::SystemModel; kwargs...)
end

"do nothing, this model does not have voltage magnitude variables"
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, force_pmin::Bool=false)
end

""
function var_branch_power_real(pm::AbstractAPLossLessModels, system::SystemModel; nw::Int=1, bounded::Bool=true)

    arcs_from = filter(!ismissing, skipmissing(topology(pm, :arcs_from)))
    p = var(pm, :p)[nw] = @variable(pm.model, p[arcs_from], container = Dict)

    if bounded
        for (l,i,j) in arcs_from
        #for (l,i,j) in topology(pm, :arcs)
            JuMP.set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l])
            JuMP.set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l])
        end
    end

    # this explicit type erasure is necessary
    p_expr = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in arcs_from), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in arcs_from)
    )
    var(pm, :p)[nw] = p_expr
end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"DC models ignore reactive power flows"
function var_load_power_factor_range(pm::AbstractDCPowerModel, system::SystemModel, t::Int; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_storage_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"do nothing by default but some formulations require this"
function var_storage_power_control_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"do nothing"
function update_var_shunt_admittance_factor(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)
end

#***************************************************** CONSTRAINTS *************************************************************************
"Nothing to do, no voltage angle variables"
function con_theta_ref(pm::AbstractNFAModel, system::SystemModel, i::Int; nw::Int=1)
end

"Nothing to do, no Ohm's Law Constraints"
function update_con_ohms_yt(pm::AbstractNFAModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
end

"Nothing to do, no Phase Angle Difference Constraints "
function update_con_voltage_angle_difference(pm::AbstractNFAModel, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)
end

""
function con_model_voltage_on_off(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1)
end

"""
This function is defining a constraint for the power balance at a specific bus, indexed by the input variable "i", 
in the power system modeled by the input "pm" and "system" objects. The constraint is defined as the sum of the active power 
flowing into the bus through all incoming branches, plus the active power flowing out of the bus through all outgoing branches, 
plus the active power generated by all generators connected to the bus, minus the active power consumed by all loads connected to the bus, 
plus the active power stored in all storage units connected to the bus should be equal to zero. This constraint is created using 
the JuMP package and is stored in the pm.model object with the key "power_balance_p" and indexed by the input variable "nw".
"""
function _con_power_balance(
    pm::AbstractDCPowerModel, system::SystemModel, i::Int, nw::Int, bus_arcs::Vector{Tuple{Int, Int, Int}}, 
    bus_gens::Vector{Int}, bus_loads::Vector{Int}, bus_shunts::Vector{Int}, bus_storage::Vector{Int},
    bus_pd, bus_qd, bus_gs, bus_bs)

    p    = var(pm, :p, nw)
    pg   = var(pm, :pg, nw)
    z_demand   = var(pm, :z_demand, nw)
    z_shunt   = var(pm, :z_shunt, nw)
    ps   = var(pm, :ps, nw)

    exp_p = @expression(pm.model,
    sum(p[a] for a in bus_arcs)
    + sum(ps[s] for s in bus_storage)
    - sum(pg[g] for g in bus_gens)
    + sum(pd for pd in bus_pd)*z_demand[i]
    + sum(gs*z_shunt[v] for (v,gs) in bus_gs)*1.0^2    
    )#JuMP.drop_zeros!(exp_p)

    con(pm, :power_balance_p, nw)[i] = @constraint(pm.model, exp_p == 0.0)
    
end

""
function _con_power_balance_nolc(
    pm::AbstractDCPowerModel, system::SystemModel, i::Int, nw::Int, bus_arcs::Vector{Tuple{Int, Int, Int}}, 
    bus_gens::Vector{Int}, bus_loads::Vector{Int}, bus_shunts::Vector{Int}, bus_storage::Vector{Int},
    bus_pd, bus_qd, bus_gs, bus_bs)

    p    = var(pm, :p, nw)
    pg   = var(pm, :pg, nw)
    ps   = var(pm, :ps, nw)
   
    exp_p = @expression(pm.model,
    sum(p[a] for a in bus_arcs)
    + sum(ps[s] for s in bus_storage)
    - sum(pg[g] for g in bus_gens)
    )

    con(pm, :power_balance_p, nw)[i] = @constraint(pm.model, exp_p == -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*1.0^2)
    
end

""
function _con_ohms_yt_from_on_off(pm::AbstractDCPowerModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    z = var(pm, :z_branch, nw)[l]
    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]

    if b <= 0
        con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= -b*(va_fr - va_to + vad_max*(1-z)))
        con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= -b*(va_fr - va_to + vad_min*(1-z)))    
    else # account for bound reversal when b is positive
        con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= -b*(va_fr - va_to + vad_min*(1-z)))
        con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= -b*(va_fr - va_to + vad_max*(1-z))) 
    end

end

""
function _con_ohms_yt_from_on_off(pm::AbstractDCMPPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    z = var(pm, :z_branch, nw)[l]
    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]

    con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= (va_fr - va_to - ta + vad_max*(1-z)) / (x*tm))
    con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= (va_fr - va_to - ta + vad_min*(1-z)) / (x*tm)) 
end

""
function _con_ohms_yt_to_on_off(pm::AbstractAPLossLessModels, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
end

"`p[f_idx]^2 + q[f_idx]^2 <= rate_a^2`"
function _con_thermal_limit_from_on_off(pm::AbstractAPLossLessModels, n::Int, l::Int, f_idx, rate_a)

    p_fr = var(pm, :p, n)[f_idx]
    z = var(pm, :z_branch, n)[l]
    con(pm, :thermal_limit_from_upper, n)[l] = @constraint(pm.model, p_fr <= rate_a*z)
    con(pm, :thermal_limit_from_lower, n)[l] = @constraint(pm.model, p_fr >= -rate_a*z)
end

"`p[t_idx]^2 + q[t_idx]^2 <= rate_a^2`"
function _con_thermal_limit_to_on_off(pm::AbstractAPLossLessModels, n::Int, l::Int, t_idx, rate_a)
    
    p_to = var(pm, :p, n)[t_idx]
    z = var(pm, :z_branch, n)[l]
    con(pm, :thermal_limit_to_upper, n)[l] = @constraint(pm.model, p_to <= rate_a*z)
    con(pm, :thermal_limit_to_lower, n)[l] = @constraint(pm.model, p_to >= -rate_a*z)

end

""
function _con_thermal_limit_from(pm::AbstractAPLossLessModels, n::Int, l::Int, f_idx, rate_a)

    p_fr = var(pm, :p, n)[f_idx]
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
        JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)
        if JuMP.has_upper_bound(p_fr) 
            JuMP.upper_bound(p_fr) > rate_a && JuMP.set_upper_bound(p_fr, rate_a)
        end
        con(pm, :thermal_limit_from, n)[l] = JuMP.LowerBoundRef(p_fr)
    else
        con(pm, :thermal_limit_from, n)[l] = @constraint(pm.model, p_fr <= rate_a)
    end
end

"nothing to do, this model is symetric"
function _con_thermal_limit_to(pm::AbstractAPLossLessModels, n::Int, l::Int, t_idx, rate_a)
    
    l,i,j = t_idx
    p_fr = var(pm, :p, n)[l,j,i]
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_upper_bound(p_fr)
        con(pm, :thermal_limit_to, n)[l] = JuMP.UpperBoundRef(p_fr)
    else
        p_to = var(pm, :p, n)[t_idx]
        con(pm, :thermal_limit_to, n)[l] = JuMP.@constraint(pm.model, p_to <= rate_a)
    end
end

"Nothing to do, no voltage angle variables"
function con_ohms_yt(pm::AbstractNFAModel, system::SystemModel, i::Int; nw::Int=1)
end

"DC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractDCPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    #con(pm, :ohms_yt_from_p, nw)[i] = @constraint(pm.model, p_fr == -b*(va_fr - va_to))
    if b <= 0
        con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= -b*(va_fr - va_to))
        con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= -b*(va_fr - va_to))    
    else # account for bound reversal when b is positive
        con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= -b*(va_fr - va_to))
        con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= -b*(va_fr - va_to)) 
    end
end

"DC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractDCMPPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    # get b only based on br_x (b = -1 / br_x) and take tap + shift into account
    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= (va_fr - va_to - ta) / (x*tm))
    con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= (va_fr - va_to - ta) / (x*tm)) 
end

"Nothing to do, this model is symetric"
function _con_ohms_yt_to(pm::AbstractAPLossLessModels, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
end

#************************************************** CONSTRAINTS STORAGE **********************************************************************
""
function _con_storage_losses(pm::AbstractAPLossLessModels, n::Int, i, bus, r, x, p_loss, q_loss)

    ps = var(pm, :ps, n)[i]
    sc = var(pm, :sc, n)[i]
    sd = var(pm, :sd, n)[i]

    con(pm, :storage_losses, n)[i] = @constraint(pm.model, ps + (sd - sc) == p_loss)
end

""
function _con_storage_losses(pm::AbstractDCPowerModel, n::Int, i, bus, r, x, p_loss, q_loss)

    ps = var(pm, :ps, n)[i]
    sc = var(pm, :sc, n)[i]
    sd = var(pm, :sd, n)[i]
    
    con(pm, :storage_losses, n)[i] = @constraint(pm.model, ps + (sd - sc) == p_loss + r*ps^2)

end

""
function _con_storage_thermal_limit(pm::AbstractDCPowerModel, n::Int, i, rating)
    
    ps = var(pm, :ps, n)[i]
    JuMP.lower_bound(ps) < -rating && JuMP.set_lower_bound(ps, -rating)
    JuMP.upper_bound(ps) >  rating && JuMP.set_upper_bound(ps,  rating)
end


#***************************************************** UPDATES *************************************************************************
""
function update_var_branch_indicator(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
end

""
function update_var_bus_voltage_angle(pm::AbstractNFAModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
end

"Do nothing"
function update_var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
end

"Model ignores reactive power flows"
function update_var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
end

"DC models ignore reactive power flows"
function update_var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, arc::Tuple{Int, Int, Int}, t::Int)
end

#************************************************** STORAGE VAR UPDATES ****************************************************************


#***************************************************UPDATES CONSTRAINTS ****************************************************************
""
function update_con_power_balance_shunts(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
end

""
function update_con_power_balance(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)

    z_demand   = var(pm, :z_demand, nw)
    bus_loads = topology(pm, :bus_loads)[i]
    #bus_loads = [k for k in field(system, :loads, :keys) if field(system, :loads, :buses)[k] == i]
    bus_pd = [field(system, :loads, :pd)[k,t] for k in bus_loads]
    JuMP.set_normalized_coefficient(con(pm, :power_balance_p, nw)[i], z_demand[i], sum(pd for pd in bus_pd))
end

""
function update_con_power_balance_nolc(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    bus_loads = topology(pm, :bus_loads)[i]
    bus_shunts = topology(pm, :bus_shunts)[i]
    bus_pd = [field(system, :loads, :pd)[k,t] for k in bus_loads]
    bus_gs = [field(system, :shunts, :gs)[k] for k in bus_shunts]
    JuMP.set_normalized_rhs(con(pm, :power_balance_p, 1)[i], -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*1.0^2)
end

""
function update_con_thermal_limits(pm::AbstractAPLossLessModels, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)

    #p_fr = con(pm, :thermal_limit_from, nw)[l]
    #p_to = con(pm, :thermal_limit_from, nw)[l]
    f_bus = field(system, :branches, :f_bus)[l] 
    t_bus = field(system, :branches, :t_bus)[l]
    rate_a = field(system, :branches, :rate_a)[l]
    f_idx = (l, f_bus, t_bus)
    p_fr = var(pm, :p, nw)[f_idx]

    if field(states, :branches)[l,t] == false
        if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
            JuMP.set_lower_bound(p_fr, 0.0)
            if JuMP.has_upper_bound(p_fr) JuMP.set_upper_bound(p_fr, 0.0) end
        else
            JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, nw)[l], 0.0)
            JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, nw)[l], 0.0)
        end
    else
        if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
            JuMP.set_lower_bound(p_fr, -rate_a)
            if JuMP.has_upper_bound(p_fr) JuMP.set_upper_bound(p_fr, rate_a) end
        else
            JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, nw)[l], rate_a)
            JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, nw)[l], rate_a)
        end
    end
end


"Nothing to do, no voltage angle variables"
function _update_con_ohms_yt_from(pm::AbstractNFAModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
end

"DC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractDCPModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]

    if b <= 0
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], vad_max*(1-field(states, :branches)[l,t]))
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], vad_min*(1-field(states, :branches)[l,t]))
    else # account for bound reversal when b is positive
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], vad_min*(1-field(states, :branches)[l,t]))
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], vad_max*(1-field(states, :branches)[l,t]))
    end
end

"DC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractDCMPPModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]
    JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], (-ta + vad_max*(1-field(states, :branches)[l,t]))/(x*tm))
    JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], (-ta + vad_min*(1-field(states, :branches)[l,t]))/(x*tm))
end

"Nothing to do, this model is symetric"
function _update_con_ohms_yt_to(pm::AbstractAPLossLessModels, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
end

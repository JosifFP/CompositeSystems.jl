"Fix the voltage angle to zero at the reference bus"
function constraint_theta_ref(pm::AbstractPowerModel, i::Int; nw::Int=1)
    fix(var(pm, :va, nw)[i], 0, force = true)
end

"nothing to do, no voltage angle variables"
function constraint_theta_ref(pm::AbstractNFAModel, i::Int; nw::Int=1)
end

"Nodal power balance constraints"
function constraint_power_balance(pm::AbstractDCPowerModel, system::SystemModel, i::Int, t::Int; nw::Int=1)

    bus_arcs = filter(!ismissing, skipmissing(topology(pm, :busarcs)[i,:]))
    bus_gens = topology(pm, :generators_nodes)[i]
    loads_nodes = topology(pm, :loads_nodes)[i]
    shunts_nodes = topology(pm, :shunts_nodes)[i]
    _constraint_power_balance(pm, system, i, t, nw, bus_arcs, bus_gens, loads_nodes, shunts_nodes)
end

""
function _constraint_power_balance(pm::LoadCurtailment, system::SystemModel, i::Int, t::Int, nw::Int, bus_arcs, bus_gens, loads_nodes, shunts_nodes)

    p    = var(pm, :p, nw)
    pg   = var(pm, :pg, nw)
    plc   = var(pm, :plc, nw)

    exp = @expression(pm.model,
        sum(pg[g] for g in bus_gens)
        + sum(plc[m] for m in loads_nodes)
        - sum(p[a] for a in bus_arcs)
    )

    JuMP.drop_zeros!(exp)

    con(pm, :power_balance, nw)[i] = @constraint(pm.model,
        exp
        ==
        sum(pd for pd in Float16.([field(system, :loads, :pd)[k,t] for k in loads_nodes]))
        + sum(gs for gs in Float16.([field(system, :shunts, :gs)[k] for k in shunts_nodes]))*1.0^2
    )
end


"Branch - Ohm's Law Constraints"
function constraint_ohms_yt(pm::AbstractDCPowerModel, system::SystemModel, i::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[i]
    t_bus = field(system, :branches, :t_bus)[i]
    g, b = calc_branch_y(field(system, :branches), i)
    tr, ti = calc_branch_t(field(system, :branches), i)
    tm = field(system, :branches, :tap)[i]
    va_fr_to = @expression(pm.model, var(pm, :va, nw)[f_bus] - var(pm, :va, nw)[t_bus])

    _constraint_ohms_yt_from(pm, i, nw, f_bus, t_bus, g, b, tr, ti, tm, va_fr_to)
    _constraint_ohms_yt_to(pm, i, nw, f_bus, t_bus, g, b, tr, ti, tm, va_fr_to)

end

"DC Line Flow Constraints"
function _constraint_ohms_yt_from(pm::AbstractDCMPPModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, tr, ti, tm, va_fr_to)

    # get b only based on br_x (b = -1 / br_x) and take tap + shift into account
    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    con(pm, :ohms_yt_from, nw)[i] = @constraint(pm.model, p_fr == (va_fr_to - ta)/(x*tm))

end

"DC Line Flow Constraints"
function _constraint_ohms_yt_from(pm::AbstractDCPowerModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, tr, ti, tm, va_fr_to)

    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    con(pm, :ohms_yt_from, nw)[i] = @constraint(pm.model, p_fr == -b*(va_fr_to))

end

"nothing to do, this model is symetric"
function _constraint_ohms_yt_to(pm::AbstractDCPowerModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, tr, ti, tm, va_fr_to)
end

"Branch - Phase Angle Difference Constraints "
function constraint_voltage_angle_diff(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    f_bus = field(system, :branches, :f_bus)[i]
    t_bus = field(system, :branches, :t_bus)[i]
    buspair = topology(pm, :buspairs)[(f_bus, t_bus)]
    
    if !ismissing(buspair)
    #if !ismissing(buspair) && Int(buspair[1]) == i
        _constraint_voltage_angle_diff(pm, i, nw, f_bus, t_bus, buspair[2], buspair[3])
    end

end

"nothing to do, no voltage angle variables"
function _constraint_voltage_angle_diff(pm::AbstractNFAModel, nw::Int, f_bus::Int, t_bus::Int, angmin, angmax)
end

"Polar Form"
function _constraint_voltage_angle_diff(pm::AbstractDCPowerModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, angmin, angmax)
    
    va_fr = var(pm, :va, nw)[f_bus]
    va_to = var(pm, :va, nw)[t_bus]
    con(pm, :voltage_angle_diff_upper, nw)[i] = @constraint(pm.model, va_fr - va_to <= angmax)
    con(pm, :voltage_angle_diff_lower, nw)[i] = @constraint(pm.model, va_fr - va_to >= angmin)

end

"""
constraint_thermal_limit_from(pm::AbstractDCPowerModel, n::Int, i::Int)
Adds the (upper and lower) thermal limit constraints for the desired branch to the PowerModel.
"""
function constraint_thermal_limits(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    f_bus = field(system, :branches, :f_bus)[i] 
    t_bus = field(system, :branches, :t_bus)[i]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    p_fr = var(pm, :p, nw)[f_idx]

    if hasfield(Branches, :rate_a)
        _constraint_thermal_limit_from(pm, nw, f_idx, p_fr, field(system, :branches, :rate_a)[i])
        _constraint_thermal_limit_to(pm, nw, t_idx, p_fr, field(system, :branches, :rate_a)[i])
    end

end

"""
Generic thermal limit constraint
`p[f_idx]^2 + q[f_idx]^2 <= rate_a^2`
"""
function _constraint_thermal_limit_from(pm::AbstractDCPowerModel, nw::Int, f_idx, p_fr, rate_a)

    if isa(p_fr, VariableRef) && has_lower_bound(p_fr)
        
        LowerBoundRef(p_fr)
        lower_bound(p_fr) < -rate_a && set_lower_bound(p_fr, -rate_a)

        if has_upper_bound(p_fr)
            upper_bound(p_fr) > rate_a && set_upper_bound(p_fr, rate_a)
        end

    else
        @constraint(pm.model, p_fr <= rate_a)
    end

end

"`p[t_idx]^2 + q[t_idx]^2 <= rate_a^2`"
function _constraint_thermal_limit_to(pm::AbstractDCPowerModel, nw::Int, t_idx, p_fr, rate_a)
    
    if isa(p_fr, VariableRef) && has_upper_bound(p_fr)
        UpperBoundRef(p_fr)
    else
        #p_to = var(pm, :p, t_idx)
        @constraint(pm.model, var(pm, :p, nw)[t_idx] <= rate_a)
    end
end

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
        if field(states, :branches)[l,t] != 0
            JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, 1)[l], buspair[3])
            JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, 1)[l], buspair[2])
        else
            JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, 1)[l], Inf)
            JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, 1)[l],-Inf)
        end

    end

    return

end

""
function calc_branch_y(branches::Branches, i::Int)
    y = pinv(field(branches, :r)[i] + im * field(branches, :x)[i])
    g, b = real(y), imag(y)
    return g, b
end

""
function calc_branch_t(branches::Branches, i::Int)
    tr = field(branches, :tap)[i] .* cos.(field(branches, :shift)[i])
    ti = field(branches, :tap)[i] .* sin.(field(branches, :shift)[i])
    return tr, ti
end

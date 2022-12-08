
#***************************************************** VARIABLES *************************************************************************
"nothing to do, no voltage angle variables"
function var_bus_voltage(pm::AbstractNFAModel, system::SystemModel; kwargs...)
end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)
end

""
function var_branch_power_real(pm::AbstractAPLossLessModels, system::SystemModel; nw::Int=1, bounded::Bool=true)

    arcs_from = filter(!ismissing, skipmissing(topology(pm, :arcs_from)))
    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))
    p = @variable(pm.model, [arcs])

    if bounded
        for (l,i,j) in arcs
        #for (l,i,j) in topology(pm, :arcs)
            JuMP.set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l])
            JuMP.set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l])
        end
    end

    # this explicit type erasure is necessary
    var(pm, :p)[nw] = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in arcs_from), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in arcs_from)
    )
end

""
function var_branch_power_real(pm::AbstractAPLossLessModels, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)

    p = @variable(pm.model, [topology(pm, :arcs)])

    if bounded
        for (l,i,j) in  topology(pm, :arcs)
            JuMP.set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
            JuMP.set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
        end
    end

    # this explicit type erasure is necessary
    var(pm, :p)[nw] = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from)), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from))
    )
end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)
end

"DC models ignore reactive power flows"
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel, t::Int; nw::Int=1, bounded::Bool=true)
end

"DC models ignore reactive power flows"
function var_load_power_factor_range(pm::AbstractDCPowerModel, system::SystemModel, t::Int; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_storage_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_storage_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)
end

"do nothing by default but some formulations require this"
function var_storage_power_control_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"do nothing by default but some formulations require this"
function var_storage_power_control_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)
end


#***************************************************** CONSTRAINTS *************************************************************************

"nothing to do, no voltage angle variables"
function con_theta_ref(pm::AbstractNFAModel, system::SystemModel, i::Int; nw::Int=1)
end

"Model ignores reactive power flows"
function con_power_factor(pm::AbstractDCPowerModel, system::SystemModel, i::Int; nw::Int=1)
end

"do nothing."
function _con_model_voltage(pm::AbstractDCPowerModel, n::Int)
end

""
function _con_power_balance(
    pm::AbstractDCPowerModel, system::SystemModel, i::Int, t::Int, nw::Int, bus_arcs::Vector{Tuple{Int, Int, Int}}, 
    generators_nodes::Vector{Int}, loads_nodes::Vector{Int}, shunts_nodes::Vector{Int}, storages_nodes::Vector{Int},
    bus_pd::Vector{Float16}, bus_qd::Vector{Float16}, bus_gs::Vector{Float16}, bus_bs::Vector{Float16})

    p    = var(pm, :p, nw)
    pg   = var(pm, :pg, nw)
    plc   = var(pm, :plc, nw)
    ps   = var(pm, :ps, nw)

    exp_p = @expression(pm.model,
        sum(pg[g] for g in generators_nodes)
        + sum(plc[m] for m in loads_nodes)
        - sum(p[a] for a in bus_arcs)
        - sum(ps[s] for s in storages_nodes)
    )

    JuMP.drop_zeros!(exp_p)
    con(pm, :power_balance_p, nw)[i] = @constraint(pm.model, exp_p == sum(pd for pd in bus_pd) + sum(gs for gs in bus_gs)*1.0^2)
    
end

"nothing to do, no voltage angle variables"
function con_ohms_yt(pm::AbstractNFAModel, system::SystemModel, i::Int; nw::Int=1)
end

"nothing to do, no voltage angle variables"
function _con_ohms_yt_from(pm::AbstractNFAModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr_to)
end

"DC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractDCPModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr_to)

    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    con(pm, :ohms_yt_from_p, nw)[i] = @constraint(pm.model, p_fr == -b*(va_fr_to))

end

"DC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractDCMPPModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr_to)

    # get b only based on br_x (b = -1 / br_x) and take tap + shift into account
    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    con(pm, :ohms_yt_from_p, nw)[i] = @constraint(pm.model, p_fr == (va_fr_to - ta)/(x*tm))

end

"nothing to do, this model is symetric"
function _con_ohms_yt_to(pm::AbstractAPLossLessModels, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr_to)
end

"""
Creates Ohms constraints (yt post fix indicates that Y and T values are in rectangular form)
"""
function _con_ohms_yt_to(pm::AbstractDCPLLModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr_to)

    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    p_to  = var(pm, :p, nw)[i, t_bus, f_bus]

    r = g/(g^2 + b^2)
    con(pm, :ohms_yt_to_p, nw)[i] = @constraint(pm.model, p_fr + p_to >= r*(p_fr^2))
end

"nothing to do, no voltage angle variables"
function con_voltage_angle_difference(pm::AbstractNFAModel, system::SystemModel, i::Int; nw::Int=1)
end

"nothing to do, no voltage angle variables"
function _con_voltage_angle_differenceerence(pm::AbstractNFAModel, nw::Int, f_bus::Int, t_bus::Int, angmin, angmax)
end

"""
Generic thermal limit constraint
`p[f_idx]^2 + q[f_idx]^2 <= rate_a^2`
"""
function _con_thermal_limit_from(pm::AbstractDCPowerModel, nw::Int, f_idx, p_fr, rate_a)

    if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
        
        JuMP.LowerBoundRef(p_fr)
        JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)

        if JuMP.has_upper_bound(p_fr)
            JuMP.upper_bound(p_fr) > rate_a && JuMP.set_upper_bound(p_fr, rate_a)
        end

    else
        @constraint(pm.model, p_fr <= rate_a)
    end

end

"`p[t_idx]^2 + q[t_idx]^2 <= rate_a^2`"
function _con_thermal_limit_to(pm::AbstractDCPowerModel, nw::Int, t_idx, p_fr, rate_a)
    
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_upper_bound(p_fr)
        JuMP.UpperBoundRef(p_fr)
    else
        #p_to = var(pm, :p, t_idx)
        @constraint(pm.model, var(pm, :p, nw)[t_idx] <= rate_a)
    end
end

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

"Model ignores reactive power flows"
function update_var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
end

"DC models ignore reactive power flows"
function update_var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
end

"Model ignores reactive power flows"
function update_var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
end

#************************************************** STORAGE VAR UPDATES ****************************************************************


#***************************************************UPDATES CONSTRAINTS ****************************************************************
""
function update_con_power_balance(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)

    for i in field(system, :buses, :keys)
        loads_nodes = topology(pm, :loads_nodes)[i]
        shunts_nodes = topology(pm, :shunts_nodes)[i]

        JuMP.set_normalized_rhs(con(pm, :power_balance_p, 1)[i], 
            sum(pd for pd in Float16.([field(system, :loads, :pd)[k,t] for k in loads_nodes]))
            + sum(gs for gs in Float16.([field(system, :shunts, :gs)[k]*field(states, :branches)[k,t] for k in shunts_nodes]))*1.0^2
        )
    end

    return

end

""
function update_con_voltage_angle_differenceerence(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)

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
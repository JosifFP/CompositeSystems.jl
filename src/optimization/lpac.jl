#***************************************************** VARIABLES *************************************************************************
""
function var_branch_indicator(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
    var(pm, :z_branch)[nw] = @variable(pm.model, z_branch[assetgrouplist(topology(pm, :branches_idxs))], binary = true, start =1.0)   
end

""
function var_bus_voltage_on_off(pm::AbstractLPACModel, system::SystemModel; kwargs...)
    var_bus_voltage_angle(pm, system; kwargs...)
    var_bus_voltage_magnitude(pm, system; kwargs...)
    var_branch_voltage_magnitude_fr_on_off(pm, system; kwargs...)
    var_branch_voltage_magnitude_to_on_off(pm, system; kwargs...)
    var_branch_voltage_product_angle_on_off(pm, system; kwargs...)
    var_branch_cosine_on_off(pm, system; kwargs...)
end


""
function var_bus_voltage_magnitude(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    phi = var(pm, :phi)[nw] = @variable(pm.model, phi[assetgrouplist(topology(pm, :buses_idxs))])
    if bounded
        for i in assetgrouplist(topology(pm, :buses_idxs))
            JuMP.set_lower_bound(phi[i], field(system, :buses, :vmin)[i] - 1.0)
            JuMP.set_upper_bound(phi[i], field(system, :buses, :vmax)[i] - 1.0)
        end
    end

end

""
function var_branch_voltage_magnitude_fr_on_off(pm::AbstractLPACModel, system::SystemModel; nw::Int=1)

    var(pm, :phi_fr)[nw] = @variable(pm.model, phi_fr[l in assetgrouplist(topology(pm, :branches_idxs))],
    lower_bound = min(0, field(system, :buses, :vmin)[field(system, :branches, :f_bus)[l]] - 1.0),
    upper_bound = max(0, field(system, :buses, :vmax)[field(system, :branches, :f_bus)[l]] - 1.0)
    )
end

""
function var_branch_voltage_magnitude_to_on_off(pm::AbstractLPACModel, system::SystemModel; nw::Int=1)

    var(pm, :phi_to)[nw] = @variable(pm.model, phi_to[l in assetgrouplist(topology(pm, :branches_idxs))],
    lower_bound = min(0, field(system, :buses, :vmin)[field(system, :branches, :t_bus)[l]] - 1.0),
    upper_bound = max(0, field(system, :buses, :vmax)[field(system, :branches, :t_bus)[l]] - 1.0)
    )
end

""
function var_branch_voltage_product_angle_on_off(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    var(pm, :td)[nw] = @variable(pm.model, td[l in assetgrouplist(topology(pm, :branches_idxs))],
    lower_bound = min(0, field(system, :branches, :angmin)[l]),
    upper_bound = max(0, field(system, :branches, :angmax)[l])
    )
end

""
function var_branch_cosine_on_off(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    branches = assetgrouplist(topology(pm, :branches_idxs))
    cos_min = Dict((l, -Inf) for l in branches)
    cos_max = Dict((l,  Inf) for l in branches)

    for l in branches
        angmin = field(system, :branches, :angmin)[l]
        angmax = field(system, :branches, :angmax)[l]
        if angmin >= 0
            cos_max[l] = cos(angmin)
            cos_min[l] = cos(angmax)
        end
        if angmax <= 0
            cos_max[l] = cos(angmax)
            cos_min[l] = cos(angmin)
        end
        if angmin < 0 && angmax > 0
            cos_max[l] = 1.0
            cos_min[l] = min(cos(angmin), cos(angmax))
        end
    end
    #var(pm, :cs)[nw] = @variable(pm.model, cs[l in branches], lower_bound = cos_min[l], upper_bound = max(0, cos_max[l]), start=1.0)
    var(pm, :cs)[nw] = @variable(pm.model, cs[l in branches], lower_bound = min(0, cos_min[l]), upper_bound = max(0, cos_max[l]), start=1.0)
end

#***************************************************** CONSTRAINTS ************************************************************************
""
function _con_power_balance(
    pm::AbstractLPACModel, system::SystemModel, i::Int, nw::Int, bus_arcs::Vector{Tuple{Int, Int, Int}}, 
    bus_gens::Vector{Int}, bus_loads::Vector{Int}, bus_shunts::Vector{Int}, bus_storage::Vector{Int},
    bus_pd, bus_qd, bus_gs, bus_bs)

    phi  = var(pm, :phi, nw)
    p    = var(pm, :p, nw)
    q    = var(pm, :q, nw)
    pg   = var(pm, :pg, nw)
    qg   = var(pm, :qg, nw)
    z_demand   = var(pm, :z_demand, nw)
    z_shunt   = var(pm, :z_shunt, nw)
    ps   = var(pm, :ps, nw)
    qs   = var(pm, :qs, nw)

    exp_p = @expression(pm.model,
    sum(p[a] for a in bus_arcs)
    - sum(pg[g] for g in bus_gens)
    + sum(ps[s] for s in bus_storage)
    + sum(pd for pd in bus_pd)*z_demand[i]
    + sum(gs*z_shunt[v] for (v,gs) in bus_gs)*(1.0 + 2*phi[i])
    )

    exp_q = @expression(pm.model,
    sum(q[a] for a in bus_arcs)
    - sum(qg[g] for g in bus_gens)
    + sum(qs[s] for s in bus_storage)
    + sum(qd for qd in bus_qd)*z_demand[i]
    - sum(bs*z_shunt[w] for (w,bs) in bus_bs)*(1.0 + 2*phi[i])
    )

    con(pm, :power_balance_p, nw)[i] = @constraint(pm.model, exp_p == 0.0)
    con(pm, :power_balance_q, nw)[i] = @constraint(pm.model, exp_q == 0.0)

end

""
function _con_power_balance_nolc(
    pm::AbstractLPACModel, system::SystemModel, i::Int, nw::Int, bus_arcs::Vector{Tuple{Int, Int, Int}}, 
    bus_gens::Vector{Int}, bus_loads::Vector{Int}, bus_shunts::Vector{Int}, bus_storage::Vector{Int},
    bus_pd, bus_qd, bus_gs, bus_bs)

    phi  = var(pm, :phi, nw)
    p    = var(pm, :p, nw)
    q    = var(pm, :q, nw)
    pg   = var(pm, :pg, nw)
    qg   = var(pm, :qg, nw)
    ps   = var(pm, :ps, nw)
    qs   = var(pm, :qs, nw)

    exp_p = @expression(pm.model,
    sum(p[a] for a in bus_arcs)
    + sum(ps[s] for s in bus_storage)
    - sum(pg[g] for g in bus_gens)
    )

    exp_q = @expression(pm.model,
    sum(q[a] for a in bus_arcs)
    + sum(qs[s] for s in bus_storage)
    - sum(qg[g] for g in bus_gens)
    )

    con(pm, :power_balance_p, nw)[i] = @constraint(pm.model, exp_p == -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*(1.0 + 2*phi[i]))
    con(pm, :power_balance_q, nw)[i] = @constraint(pm.model, exp_q == -sum(qd for qd in bus_qd) + sum(bs for bs in bus_bs)*(1.0 + 2*phi[i]))

end

"""
This constraint captures problem agnostic constraints that are used to link
the model's voltage variables together, in addition to the standard problem
formulation constraints.
"""
function con_model_voltage_on_off(pm::AbstractLPACModel, system::SystemModel; nw::Int=1)
    
    t = var(pm, :va, nw)
    td = var(pm, :td, nw)
    cs = var(pm, :cs, nw)
    z = var(pm, :z_branch, nw)
    phi = var(pm, :phi, nw)
    phi_fr = var(pm, :phi_fr, nw)
    phi_to = var(pm, :phi_to, nw)
    td_lb = topology(pm, :delta_bounds)[1]
    td_ub = topology(pm, :delta_bounds)[2]
    
    td_max = max(abs(td_lb), abs(td_ub))

    for l in assetgrouplist(topology(pm, :branches_idxs))
        f_bus = field(system, :branches, :f_bus)[l]
        t_bus = field(system, :branches, :t_bus)[l]
        con(pm, :model_voltage_upper, nw)[l] = JuMP.@constraint(pm.model, t[f_bus] - t[t_bus] <= td[l] + td_ub*(1-z[l]))
        con(pm, :model_voltage_lower, nw)[l] = JuMP.@constraint(pm.model, t[f_bus] - t[t_bus] >= td[l] + td_lb*(1-z[l]))
        con_relaxation_cos_on_off(pm, l, td[l], cs[l], z[l], td_max)
        _IM.constraint_bounds_on_off(pm.model, td[l], z[l])
        _IM.constraint_bounds_on_off(pm.model, phi_fr[l], z[l])
        _IM.constraint_bounds_on_off(pm.model, phi_to[l], z[l])
        _IM.relaxation_equality_on_off(pm.model, phi[f_bus], phi_fr[l], z[l])
        _IM.relaxation_equality_on_off(pm.model, phi[t_bus], phi_to[l], z[l])
    end
end


"general relaxation of a cosine term, in -pi/2 to pi/2"
function con_relaxation_cos_on_off(pm::AbstractLPACModel, l::Int, td, cs, z, td_max; nw::Int=1)

    lb, ub = _IM.variable_domain(td)
    @assert lb >= -pi/2 && ub <= pi/2
    max_ad = max(abs(lb),abs(ub))

    con(pm, :relaxation_cos_upper, nw)[l] = JuMP.@constraint(pm.model, cs <= z)
    con(pm, :relaxation_cos_lower, nw)[l] = JuMP.@constraint(pm.model, cs >= z*cos(max_ad))
    con(pm, :relaxation_cos, nw)[l] = JuMP.@constraint(pm.model, cs <= z - (1-cos(max_ad))/(max_ad^2)*(td^2) + (1-z)*((1-cos(max_ad))/(max_ad^2)*(td_max^2)))
end

""
function _con_ohms_yt_from_on_off(pm::AbstractLPACModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    q_fr  = var(pm, :q, nw)[l, f_bus, t_bus]
    phi_fr = var(pm, :phi_fr, nw)[l]
    phi_to = var(pm, :phi_to, nw)[l]
    td = var(pm, :td, nw)[l]
    cs = var(pm, :cs, nw)[l]
    z = var(pm, :z_branch, nw)[l]
    con(pm, :ohms_yt_from_p, nw)[l] = @constraint(pm.model, p_fr ==  (g+g_fr)/tm^2*(z + 2*phi_fr) + (-g*tr+b*ti)/tm^2*(cs + phi_fr + phi_to) + (-b*tr-g*ti)/tm^2*(td))
    con(pm, :ohms_yt_from_q, nw)[l] = @constraint(pm.model, q_fr == -(b+b_fr)/tm^2*(z + 2*phi_fr) - (-b*tr-g*ti)/tm^2*(cs + phi_fr + phi_to) + (-g*tr+b*ti)/tm^2*(td))

end

"""
Creates Ohms constraints (yt post fix indicates that Y and T values are in rectangular form)
"""
function _con_ohms_yt_to_on_off(pm::AbstractLPACModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)

    p_to  = var(pm, :p, nw)[l, t_bus, f_bus]
    q_to  = var(pm, :q, nw)[l, t_bus, f_bus]
    phi_fr = var(pm, :phi_fr, nw)[l]
    phi_to = var(pm, :phi_to, nw)[l]
    td = var(pm, :td, nw)[l]
    cs = var(pm, :cs, nw)[l]
    z = var(pm, :z_branch, nw)[l]
    con(pm, :ohms_yt_to_p, nw)[l] = @constraint(pm.model, p_to ==  (g+g_to)*(z + 2*phi_to) + (-g*tr-b*ti)/tm^2*(cs + phi_fr + phi_to) + (-b*tr+g*ti)/tm^2*-(td))
    con(pm, :ohms_yt_to_q, nw)[l] = @constraint(pm.model, q_to == -(b+b_to)*(z + 2*phi_to) - (-b*tr+g*ti)/tm^2*(cs + phi_fr + phi_to) + (-g*tr-b*ti)/tm^2*-(td))

end

""
function _con_ohms_yt_from(pm::AbstractLPACModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    q_fr  = var(pm, :q, nw)[l, f_bus, t_bus]
    phi_fr = var(pm, :phi_fr, nw)[l]
    phi_to = var(pm, :phi_to, nw)[l]
    td = var(pm, :td, nw)[l]
    cs = var(pm, :cs, nw)[l]
    con(pm, :ohms_yt_from_p, nw)[l] = @constraint(pm.model, p_fr ==  (g+g_fr)/tm^2*(1.0 + 2*phi_fr) + (-g*tr+b*ti)/tm^2*(cs + phi_fr + phi_to) + (-b*tr-g*ti)/tm^2*(td))
    con(pm, :ohms_yt_from_q, nw)[l] = @constraint(pm.model, q_fr == -(b+b_fr)/tm^2*(1.0 + 2*phi_fr) - (-b*tr-g*ti)/tm^2*(cs + phi_fr + phi_to) + (-g*tr+b*ti)/tm^2*(td))

end

""
function _con_ohms_yt_to(pm::AbstractLPACModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)

    p_to  = var(pm, :p, nw)[l, t_bus, f_bus]
    q_to  = var(pm, :q, nw)[l, t_bus, f_bus]
    phi_fr = var(pm, :phi_fr, nw)[l]
    phi_to = var(pm, :phi_to, nw)[l]
    td = var(pm, :td, nw)[l]
    cs = var(pm, :cs, nw)[l]
    con(pm, :ohms_yt_to_p, nw)[l] = @constraint(pm.model, p_to ==  (g+g_to)*(1.0 + 2*phi_to) + (-g*tr-b*ti)/tm^2*(cs + phi_fr + phi_to) + (-b*tr+g*ti)/tm^2*-(td))
    con(pm, :ohms_yt_to_q, nw)[l] = @constraint(pm.model, q_to == -(b+b_to)*(1.0 + 2*phi_to) - (-b*tr+g*ti)/tm^2*(cs + phi_fr + phi_to) + (-g*tr-b*ti)/tm^2*-(td))
end

""
function _con_storage_losses(pm::AbstractLPACModel, n::Int, i::Int, bus::Int, r::Float32, x::Float32, p_loss::Float32, q_loss::Float32, vmin::Float32, vmax::Float32)
    ps = var(pm, :ps, n)[i]
    qs = var(pm, :qs, n)[i]
    sc = var(pm, :sc, n)[i]
    sd = var(pm, :sd, n)[i]
    ccms = var(pm, :ccms, n)[i]
    qsc = var(pm, :qsc, n)[i]
    #phi = var(pm, :phi, n)[bus]
    con(pm, :storage_losses_p, n)[i] = @constraint(pm.model, ps + (sd - sc) == p_loss + r*ccms)
    con(pm, :storage_losses_q, n)[i] = @constraint(pm.model, qs == qsc + q_loss + x*ccms)
    con(pm, :storage_losses, n)[i] = @constraint(pm.model, ps^2 + qs^2 <= vmax*ccms)
end


#***************************************************** UPDATES *************************************************************************

""
function update_branch_voltage_magnitude_fr_on_off(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)

    phi_fr = var(pm, :phi_fr, nw)[l]

    if states.branches[l,t] == 0
        JuMP.set_upper_bound(phi_fr, 0)
        JuMP.set_lower_bound(phi_fr, 0)
    else
        JuMP.set_lower_bound(phi_fr, min(0, field(system, :buses, :vmin)[field(system, :branches, :f_bus)[l]] - 1.0))
        JuMP.set_upper_bound(phi_fr, max(0, field(system, :buses, :vmax)[field(system, :branches, :f_bus)[l]] - 1.0))
    end

end

""
function update_branch_voltage_magnitude_to_on_off(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)

    phi_to = var(pm, :phi_to, nw)[l]

    if states.branches[l,t] == 0
        JuMP.set_upper_bound(phi_to, 0)
        JuMP.set_lower_bound(phi_to, 0)
    else
        JuMP.set_lower_bound(phi_to, min(0, field(system, :buses, :vmin)[field(system, :branches, :t_bus)[l]] - 1.0))
        JuMP.set_upper_bound(phi_to, max(0, field(system, :buses, :vmax)[field(system, :branches, :t_bus)[l]] - 1.0))
    end

end

""
function update_var_branch_voltage_product_angle_on_off(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)

    td = var(pm, :td, nw)[l]

    if states.branches[l,t] == 0
        JuMP.set_upper_bound(td, 0)
        JuMP.set_lower_bound(td, 0)
    else
        JuMP.set_lower_bound(td, min(0, field(system, :branches, :angmin)[l]))
        JuMP.set_upper_bound(td, max(0, field(system, :branches, :angmax)[l]))
    end
end

""
function update_var_shunt_admittance_factor(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)
    
    z_shunt = var(pm, :z_shunt, nw)[l]
    @views t_now_view_shunts = states.shunts[:, t]
    @views t_now_view_branches = states.branches[:, t]
    
    if any(t_now_view_shunts .== 0) || any(t_now_view_branches .== 0)
        if JuMP.is_fixed(z_shunt) JuMP.unfix(z_shunt) end
    else
        if !JuMP.is_fixed(z_shunt) JuMP.fix(z_shunt, 1.0) end
    end
end

""
function update_con_power_balance(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    #phi  = var(pm, :phi, nw)[i]
    z_demand   = var(pm, :z_demand, nw)[i]
    bus_loads = topology(pm, :bus_loads)[i]
    #bus_shunts = topology(pm, :bus_shunts)[i]

    bus_pd = [field(system, :loads, :pd)[k,t] for k in bus_loads]
    bus_qd = [field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in bus_loads]
    #bus_gs = Float32.([field(system, :shunts, :gs)[k] for k in bus_shunts])
    #bus_bs = Float32.([field(system, :shunts, :bs)[k] for k in bus_shunts])
    if states.buses[i,t] == 4
        JuMP.set_normalized_coefficient(con(pm, :power_balance_p, nw)[i], z_demand, 0)
        JuMP.set_normalized_coefficient(con(pm, :power_balance_q, nw)[i], z_demand, 0)
    else
        JuMP.set_normalized_coefficient(con(pm, :power_balance_p, nw)[i], z_demand, sum(pd for pd in bus_pd))
        JuMP.set_normalized_coefficient(con(pm, :power_balance_q, nw)[i], z_demand, sum(qd for qd in bus_qd))
    end
end

""
function update_con_power_balance_nolc(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)

    phi  = var(pm, :phi, nw)
    bus_loads = topology(pm, :bus_loads)[i]
    bus_shunts = topology(pm, :bus_shunts)[i]

    bus_pd = [field(system, :loads, :pd)[k,t] for k in bus_loads]
    bus_qd = [field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in bus_loads]
    bus_gs = [field(system, :shunts, :gs)[k] for k in bus_shunts]
    bus_bs = [field(system, :shunts, :bs)[k] for k in bus_shunts]

    JuMP.set_normalized_coefficient(con(pm, :power_balance_p, nw)[i], phi[i], -sum(gs for gs in bus_gs)*2)
    JuMP.set_normalized_coefficient(con(pm, :power_balance_q, nw)[i], phi[i], +sum(bs for bs in bus_bs)*2)

    JuMP.set_normalized_rhs(con(pm, :power_balance_p, nw)[i], -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*(1.0))
    JuMP.set_normalized_rhs(con(pm, :power_balance_q, nw)[i], -sum(qd for qd in bus_qd) + sum(bs for bs in bus_bs)*(1.0))

end

function _update_con_ohms_yt_from(pm::AbstractLPACModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    if states.branches[l,t] == false
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_p, nw)[l], 0.0)
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_q, nw)[l], 0.0)
    else
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_p, nw)[l], (g+g_fr)/tm^2)
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_q, nw)[l], -(b+b_fr)/tm^2)
    end
end

"AC Line Flow Constraints"
function _update_con_ohms_yt_to(pm::AbstractLPACModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
    if states.branches[l,t] == false
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_to_p, nw)[l], 0.0)
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_to_q, nw)[l], 0.0)
    else
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_to_p, nw)[l], (g+g_to))
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_to_q, nw)[l], -(b+b_to))
    end
end

""
function update_var_branch_indicator(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)

    z_branch = var(pm, :z_branch, nw)[i]
    if states.branches[i,t] == 0
        JuMP.fix(z_branch, 0)
    else
        JuMP.fix(z_branch, 1)
    end
end
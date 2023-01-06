
#***************************************************** VARIABLES *************************************************************************
"Nothing to do, no voltage angle variables"
function var_bus_voltage(pm::AbstractNFAModel, system::SystemModel; kwargs...)
end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, force_pmin::Bool=false)
end

""
function var_branch_power_real(pm::AbstractAPLossLessModels, system::SystemModel; nw::Int=1, bounded::Bool=true)

    arcs_from = filter(!ismissing, skipmissing(topology(pm, :arcs_from)))
    p = @variable(pm.model, p[arcs_from])

    if bounded
        for (l,i,j) in arcs_from
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

#***************************************************** CONSTRAINTS *************************************************************************
"do nothing, most models to not require any model-specific voltage constraint"
function _con_model_voltage(pm::AbstractDCPowerModel, bp::Tuple{Int,Int}, n::Int)
end

"Nothing to do, no voltage angle variables"
function con_theta_ref(pm::AbstractNFAModel, system::SystemModel, i::Int; nw::Int=1)
end

""
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

"Nothing to do, no voltage angle variables"
function con_ohms_yt(pm::AbstractNFAModel, system::SystemModel, i::Int; nw::Int=1)
end

"Nothing to do, no voltage angle variables"
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

"Nothing to do, this model is symetric"
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

"Nothing to do, no voltage angle variables"
function con_voltage_angle_difference(pm::AbstractNFAModel, bp::Tuple{Int,Int}; nw::Int=1)
end

"Nothing to do, no voltage angle variables"
function _con_voltage_angle_difference(pm::AbstractNFAModel, nw::Int, f_bus::Int, t_bus::Int, angmin, angmax)
end

"`-rate_a <= p[f_idx] <= rate_a`"
function _con_thermal_limit_from(pm::AbstractDCPowerModel, n::Int, i::Int, f_idx, rate_a)

    p_fr = var(pm, :p, n)[f_idx]

    if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
        con(pm, :thermal_limit_from, n)[i] = JuMP.LowerBoundRef(p_fr)
        JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)
        if JuMP.has_upper_bound(p_fr)
            JuMP.upper_bound(p_fr) > rate_a && JuMP.set_upper_bound(p_fr, rate_a)
        end
    else
        con(pm, :thermal_limit_from, n)[i] = JuMP.@constraint(pm.model, p_fr <= rate_a)
    end

end

"Nothing to do, this model is symetric"
function _con_thermal_limit_to(pm::AbstractAPLossLessModels, n::Int, i::Int, t_idx, rate_a)

    l,u,v = t_idx
    p_fr = var(pm, :p, n)[(l,v,u)]
    
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_upper_bound(p_fr)
        con(pm, :thermal_limit_to, n)[i] = JuMP.UpperBoundRef(p_fr)
    else
        p_to = var(pm, :p, n)[t_idx]
        con(pm, :thermal_limit_to, n)[i] = @constraint(pm.model, p_to <= rate_a)
    end

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
function update_con_power_balance(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    z_demand   = var(pm, :z_demand, 1)
    z_shunt   = var(pm, :z_shunt, 1)
    bus_loads = topology(pm, :loads_nodes)[i]
    bus_shunts = topology(pm, :shunts_nodes)[i]

    bus_pd = Float32.([field(system, :loads, :pd)[k,t] for k in bus_loads])
    bus_gs = Dict{Int, Float32}(k => field(system, :shunts, :gs)[k] for k in bus_shunts)

    JuMP.set_normalized_coefficient(con(pm, :power_balance_p, 1)[i], z_demand[i], sum(pd for pd in bus_pd))
    #JuMP.set_normalized_rhs(con(pm, :power_balance_p, 1)[i], -sum(gs for gs in bus_gs)*1.0^2)
    
    return

end

""
function update_con_power_balance_nolc(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    loads_nodes = topology(pm, :loads_nodes)[i]
    shunts_nodes = topology(pm, :shunts_nodes)[i]
    bus_pd = Float32.([field(system, :loads, :pd)[k,t] for k in loads_nodes])
    bus_gs = Float32.([field(system, :shunts, :gs)[k] for k in shunts_nodes])

    JuMP.set_normalized_rhs(con(pm, :power_balance_p, 1)[i], -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*1.0^2)
    return

end

"Nothing to do, this model is symetric"
function update_con_thermal_limits(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
end

""
function update_con_voltage_angle_difference(pm::AbstractNFAModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
end

""
function reset_con_ohms_yt(pm::AbstractNFAModel, active_branches::Vector{Int})
end

""
function reset_con_ohms_yt(pm::AbstractDCPModel, active_branches::Vector{Int})
    JuMP.delete(pm.model, con(pm, :ohms_yt_from_p, 1).data)
    add_con_container!(pm.con, :ohms_yt_from_p, active_branches)
end

""
function reset_con_ohms_yt(pm::AbstractDCPLLModel, active_branches::Vector{Int})
    JuMP.delete(pm.model, con(pm, :ohms_yt_from_p, 1).data)
    JuMP.delete(pm.model, con(pm, :ohms_yt_to_p, 1).data)
    add_con_container!(pm.con, :ohms_yt_from_p, active_branches)
    add_con_container!(pm.con, :ohms_yt_to_p, active_branches)
end

""
function reset_con_voltage_angle_difference(pm::AbstractNFAModel, buspair::Vector{Tuple{Int, Int}})
end
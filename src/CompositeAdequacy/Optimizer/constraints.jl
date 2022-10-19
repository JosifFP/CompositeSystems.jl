"Fix the voltage angle to zero at the reference bus"
function constraint_theta_ref(pm::AbstractPowerModel, i::Int; t::Int=0)
    @constraint(pm.model, var(pm, :va, t)[i] == 0, container = Array)
    #fix(var(pm, :va)[i], 0, force = true)
end

"nothing to do, no voltage angle variables"
function constraint_theta_ref(pm::AbstractNFAModel, i::Int; t::Int=0)
end

"Nodal power balance constraints"
function constraint_power_balance(pm::AbstractDCPowerModel, system::SystemModel, i::Int; t::Int=0)

    bus_arcs = field(pm, Topology, :bus_arcs)[i]
    bus_gens = field(pm, Topology, :bus_generators)[i]
    bus_loads = field(pm, Topology, :bus_loads)[i]
    bus_shunts = field(pm, Topology, :bus_shunts)[i]
    #bus_storage = assetgrouplist(field(pm, Topology, :bus_storage))[i]

#    bus_pd = Float16.([field(system, Loads, :pd)[k,t] for k in bus_loads])
#    bus_qd = Float16.([field(system, Loads, :qd)[k] for k in bus_loads])
#    bus_gs = Float16.([field(system, Shunts, :gs)[k] for k in bus_shunts])
#    bus_bs = Float16.([field(system, Shunts, :bs)[k] for k in bus_shunts])

    _constraint_power_balance(pm, system, t, bus_arcs, bus_gens, bus_loads, bus_shunts)
end

""
function _constraint_power_balance(pm::AbstractDCPowerModel, system::SystemModel, t::Int, bus_arcs, bus_gens, bus_loads, bus_shunts)

    p    = var(pm, :p, t)
    pg   = var(pm, :pg, t)
    plc   = var(pm, :plc, t)
    #ps   = get(var(pm), :ps, Dict()); _check_var_keys(ps, bus_storage, "active power", "storage")
    #psw  = get(var(pm), :psw, Dict()); _check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    #p_dc = get(var(pm), :p_dc, Dict()); _check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")

    @constraint(pm.model,
        sum(pg[g] for g in bus_gens)
        + sum(plc[m] for m in bus_loads)
        - sum(p[a] for a in bus_arcs)
        #- sum(ps[s] for s in bus_storage)
        #- sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        #- sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pd for pd in Float16.([field(system, Loads, :pd)[k,t] for k in bus_loads]))
        + sum(gs for gs in Float16.([field(system, Shunts, :gs)[k] for k in bus_shunts]))*1.0^2
    )
end

"Branch - Ohm's Law Constraints"
function constraint_ohms_yt(pm::AbstractPowerModel, system::SystemModel, i::Int; t::Int=0)
    
    f_bus = field(system, Branches, :f_bus)[i]
    t_bus = field(system, Branches, :t_bus)[i]
    #f_idx = (i, f_bus, t_bus) #t_idx = (i, t_bus, f_bus)
    g, b = calc_branch_y(field(system, :branches), i)
    tr, ti = calc_branch_t(field(system, :branches), i)
    tm = field(system, Branches, :tap)[i]
    #g_fr = field(system, Branches, :g_fr)[i]
    #b_fr = field(system, Branches, :b_fr)[i]
    #g_to = field(system, Branches, :g_to)[i]
    #b_to = field(system, Branches, :b_to)[i]

    va_fr_to = @expression(pm.model, var(pm, :va, t)[f_bus] - var(pm, :va, t)[t_bus])

    _constraint_ohms_yt_from(pm, i, t, f_bus, t_bus, g, b, tr, ti, tm, va_fr_to)
    _constraint_ohms_yt_to(pm, i, t, f_bus, t_bus, g, b, tr, ti, tm, va_fr_to)

end

"DC Line Flow Constraints"
function _constraint_ohms_yt_from(pm::AbstractDCMPPModel, i::Int, t::Int, f_bus::Int, t_bus::Int, g, b, tr, ti, tm, va_fr_to)

    # get b only based on br_x (b = -1 / br_x) and take tap + shift into account
    x = -b / (g^2 + b^2)
    @constraint(pm.model, var(pm, :p, t)[i, f_bus, t_bus] == (va_fr_to - atan(ti, tr))/(x*tm))

end

"DC Line Flow Constraints"
function _constraint_ohms_yt_from(pm::AbstractDCPowerModel, i::Int, t::Int, f_bus::Int, t_bus::Int, g, b, tr, ti, tm, va_fr_to)

    @constraint(pm.model, var(pm, :p, t)[i, f_bus, t_bus] == -b*(va_fr_to))

end

"nothing to do, this model is symetric"
function _constraint_ohms_yt_to(pm::AbstractDCPowerModel, i::Int, t::Int, f_bus::Int, t_bus::Int, g, b, tr, ti, tm, va_fr_to)
end

"Branch - Phase Angle Difference Constraints "
function constraint_voltage_angle_diff(pm::AbstractPowerModel, system::SystemModel, i::Int; t::Int=0)

    f_bus = field(system, Branches, :f_bus)[i]
    t_bus = field(system, Branches, :t_bus)[i]
    buspair = field(pm, Topology, :buspairs)[(f_bus, t_bus)]
    
    _constraint_voltage_angle_diff(pm, t, f_bus, t_bus, buspair["angmin"], buspair["angmax"])

end

"nothing to do, no voltage angle variables"
function constraint_voltage_angle_difference(pm::AbstractNFAModel, t::Int, f_bus::Int, t_bus::Int, angmin, angmax)
end

"Polar Form"
function _constraint_voltage_angle_diff(pm::AbstractDCPowerModel, t::Int, f_bus::Int, t_bus::Int, angmin, angmax)
    
    #va_fr = var(pm, :va, f_bus) va_to = var(pm, :va, t_bus)
    @constraint(pm.model, var(pm, :va, t)[f_bus] - var(pm, :va, t)[t_bus] <= angmax)
    @constraint(pm.model, var(pm, :va, t)[f_bus] - var(pm, :va, t)[t_bus] >= angmin)
end

"""
constraint_thermal_limit_from(pm::AbstractDCPowerModel, n::Int, i::Int)
Adds the (upper and lower) thermal limit constraints for the desired branch to the PowerModel.
"""
function constraint_thermal_limits(pm::AbstractPowerModel, system::SystemModel, i::Int; t::Int=0)

    f_bus = field(system, Branches, :f_bus)[i] 
    t_bus = field(system, Branches, :t_bus)[i]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    p_fr = var(pm, :p, t)[f_idx]

    if hasfield(Branches, :rate_a)
        _constraint_thermal_limit_from(pm, t, f_idx, p_fr, field(system, Branches, :rate_a)[i])
        _constraint_thermal_limit_to(pm, t, t_idx, p_fr, field(system, Branches, :rate_a)[i])
    end

end

"""
Generic thermal limit constraint
`p[f_idx]^2 + q[f_idx]^2 <= rate_a^2`
"""
function _constraint_thermal_limit_from(pm::AbstractDCPowerModel, t::Int, f_idx, p_fr, rate_a)

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
function _constraint_thermal_limit_to(pm::AbstractDCPowerModel, t::Int, t_idx, p_fr, rate_a)
    
    if isa(p_fr, VariableRef) && has_upper_bound(p_fr)
        UpperBoundRef(p_fr)
    else
        #p_to = var(pm, :p, t_idx)
        @constraint(pm.model, var(pm, :p, t)[t_idx] <= rate_a)
    end
end



#"***************************************************************************************************************************"
#"Needs to be fixed/updated"

#"DC LINES "
# function constraint_dcline_power_losses(pm::AbstractDCPowerModel, i::Int)
#     dcline = ref(pm, :dcline, i)
#     f_bus = dcline["f_bus"]
#     t_bus = dcline["t_bus"]
#     f_idx = (i, f_bus, t_bus)
#     t_idx = (i, t_bus, f_bus)
#     loss0 = dcline["loss0"]
#     loss1 = dcline["loss1"]

#     _constraint_dcline_power_losses(pm, f_bus, t_bus, f_idx, t_idx, loss0, loss1)
# end

# """
# Creates Line Flow constraint for DC Lines (Matpower Formulation)

# ```
# p_fr + p_to == loss0 + p_fr * loss1
# ```
# """
# function _constraint_dcline_power_losses(pm::AbstractDCPowerModel, f_bus, t_bus, f_idx, t_idx, loss0, loss1)
#     p_fr = var(pm, :p_dc, f_idx)
#     p_to = var(pm, :p_dc, t_idx)

#     @constraint(pm.model, (1-loss1) * p_fr + (p_to - loss0) == 0)
# end

# "Fixed Power Factor"
# function constraint_power_factor(pm::AbstractACPowerModel)

#     z_demand = var(pm, :z_demand)
#     plc = var(pm, :plc)
#     q_lc = var(pm, :q_lc)
    
#     for (l,_) in ref(pm, :load)
#         @constraint(pm.model, z_demand[i]*plc[i] - q_lc[i] == 0.0)      
#     end
# end

# ""
# function constraint_voltage_magnitude_diff(pm::AbstractDCPowerModel, i::Int)

#     branch = ref(pm, :branch, i)
#     f_bus = branch["f_bus"]
#     t_bus = branch["t_bus"]
#     f_idx = (i, f_bus, t_bus)
#     t_idx = (i, t_bus, f_bus)

#     r = branch["br_r"]
#     x = branch["br_x"]
#     g_sh_fr = branch["g_fr"]
#     b_sh_fr = branch["b_fr"]
#     tm = branch["tap"]

#     _constraint_voltage_magnitude_difference(pm, i, f_bus, t_bus, f_idx, t_idx, r, x, g_sh_fr, b_sh_fr, tm)
# end

# """
# Defines voltage drop over a branch, linking from and to side voltage magnitude
# """
# function _constraint_voltage_magnitude_difference(pm::AbstractDCPowerModel, i, f_bus, t_bus, f_idx, t_idx, r, x, g_sh_fr, b_sh_fr, tm)
#     p_fr = var(pm, :p, f_idx)
#     #q_fr = var(pm, n, :q, f_idx)
#     q_fr = 0
#     w_fr = var(pm, :w, f_bus)
#     w_to = var(pm, :w, t_bus)
#     ccm =  var(pm, :ccm, i)

#     ym_sh_sqr = g_sh_fr^2 + b_sh_fr^2

#     @constraint(pm.model, (1+2*(r*g_sh_fr - x*b_sh_fr))*(w_fr/tm^2) - w_to ==  2*(r*p_fr + x*q_fr) - (r^2 + x^2)*(ccm + ym_sh_sqr*(w_fr/tm^2) - 2*(g_sh_fr*p_fr - b_sh_fr*q_fr)))
# end

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

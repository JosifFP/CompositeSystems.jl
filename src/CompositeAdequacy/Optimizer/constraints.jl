###############################################################################
# This file defines commonly used constraints for power flow models

###############################################################################

"Fix the voltage angle to zero at the reference bus"
function constraint_theta_ref(pm::AbstractDCPowerModel, i::Int)
    JuMP.@constraint(pm.model, var(pm, :va)[i] == 0)

end

"Nodal power balance constraints"
function constraint_power_balance(pm::AbstractPowerModel, system::SystemModel, i::Int)

    bus = field(system, Buses, :keys)[i]
    bus_arcs = field(system, Topology, :bus_arcs)[i]
    #bus_arcs_dc = field(system, Topology, :bus_arcs_dc)[i]
    #bus_arcs_sw = field(system, Topology, :bus_arcs_sw)[i]
    bus_gens = field(system, Topology, :bus_gens)[i]
    bus_loads = field(system, Topology, :bus_loads)[i]
    bus_shunts = field(system, Topology, :bus_shunts)[i]
    bus_storage = field(system, Topology, :bus_storage)[i]

    bus_pd = Dict(k => field(system, Loads, :pd)[k] for k in bus_loads)
    bus_qd = Dict(k => field(system, Loads, :qd)[k] for k in bus_loads)
    bus_gs = Dict(k => field(system, Shunts, :gs)[k] for k in bus_shunts)
    bus_bs = Dict(k => field(system, Shunts, :bs)[k] for k in bus_shunts)

    type = sol(pm, :type)

    _constraint_power_balance(pm, i, bus_arcs, bus_gens, bus_storage, bus_loads, bus_pd, bus_qd, bus_gs, bus_bs, type)
end

""
function _constraint_power_balance(pm::AbstractDCPowerModel, i::Int, bus_arcs, bus_gens, bus_storage, bus_loads, bus_pd, bus_qd, bus_gs, bus_bs, type::Type{DCMPPowerModel})
    p    = get(var(pm),    :p, Dict()); _check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = get(var(pm),   :pg, Dict()); _check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = get(var(pm),   :ps, Dict()); _check_var_keys(ps, bus_storage, "active power", "storage")
    #psw  = get(var(pm),  :psw, Dict()); _check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    #p_dc = get(var(pm), :p_dc, Dict()); _check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")

    cstr = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        #+ sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        #+ sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*1.0^2
    )
end

""
function _constraint_power_balance(pm::AbstractDCPowerModel, i::Int, bus_arcs, bus_gens, bus_storage, bus_loads, bus_pd, bus_qd, bus_gs, bus_bs, type::Type{<:LCDCMethod})

    p    = get(var(pm),    :p, Dict()); _check_var_keys(p, bus_arcs, "active power", "branch")
    p_lc = get(var(pm), :p_lc, Dict()); _check_var_keys(p, bus_loads, "active power", "loads")
    pg   = get(var(pm),   :pg, Dict()); _check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = get(var(pm),   :ps, Dict()); _check_var_keys(ps, bus_storage, "active power", "storage")
    #psw  = get(var(pm),  :psw, Dict()); _check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    #p_dc = get(var(pm), :p_dc, Dict()); _check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")


    cstr = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        #+ sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        #+ sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        + sum(p_lc[m] for m in bus_loads)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*1.0^2
    )
end

"checks if a sufficient number of variables exist for the given keys collection"
function _check_var_keys(vars, keys, var_name, comp_name)
    if length(vars) < length(keys)
        error(_LOGGER, "$(var_name) decision variables appear to be missing for $(comp_name) components")
    end
end

### Branch - Ohm's Law Constraints ###
""
function constraint_ohms_yt_from(pm::AbstractPowerModel, i::Int)
    branch = ref(pm, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_y(branch)
    tr, ti = calc_branch_t(branch)
    g_fr = branch["g_fr"]
    b_fr = branch["b_fr"]
    tm = branch["tap"]

    _constraint_ohms_yt_from(pm, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm)
end

""
function _constraint_ohms_yt_from(pm::AbstractDCPowerModel, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm)
    va_fr = var(pm, :va, f_bus)
    va_to = var(pm, :va, t_bus)

    var(pm, :p)[f_idx] = -b*(va_fr - va_to)
end

#  ""
# function _constraint_ohms_yt_from(pm::AbstractDCPowerModel, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm)
#     p_fr  = var(pm, :p, f_idx)
#     va_fr = var(pm, :va, f_bus)
#     va_to = var(pm, :va, t_bus)

#     # get b only based on br_x (b = -1 / br_x) and take tap + shift into account
#     x = -b / (g^2 + b^2)
#     ta = atan(ti, tr)
#     JuMP.@constraint(pm.model, p_fr == (va_fr - va_to - ta)/(x*tm))
# end

""
function constraint_ohms_yt_to(pm::AbstractPowerModel, i::Int)
    branch = ref(pm, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_y(branch)
    tr, ti = calc_branch_t(branch)
    g_to = branch["g_to"]
    b_to = branch["b_to"]
    tm = branch["tap"]

    _constraint_ohms_yt_to(pm, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm)
end

"nothing to do, this model is symetric"
function _constraint_ohms_yt_to(pm::AbstractDCPowerModel, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm)
end

### Branch - Phase Angle Difference Constraints ###
""
function constraint_voltage_angle_difference(pm::AbstractPowerModel, i::Int)
    branch = ref(pm, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    pair = (f_bus, t_bus)
    buspair = ref(pm, :buspairs, pair)

    if buspair["branch"] == i
        _constraint_voltage_angle_difference(pm, f_idx, buspair["angmin"], buspair["angmax"])
    end
end

"Polar Form"
function _constraint_voltage_angle_difference(pm::AbstractDCPowerModel, f_idx, angmin, angmax)
    i, f_bus, t_bus = f_idx

    va_fr = var(pm, :va, f_bus)
    va_to = var(pm, :va, t_bus)

    JuMP.@constraint(pm.model, angmin <= va_fr - va_to <= angmax)

end

"""

    constraint_thermal_limit_from(pm::AbstractDCPowerModel, n::Int, i::Int)

Adds the (upper and lower) thermal limit constraints for the desired branch to the PowerModel.

"""
function constraint_thermal_limit_from(pm::AbstractPowerModel, i::Int)
    branch = ref(pm, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if haskey(branch, "rate_a")
        _constraint_thermal_limit_from(pm, f_idx, branch["rate_a"])
    end
end

# Generic thermal limit constraint
"`p[f_idx]^2 + q[f_idx]^2 <= rate_a^2`"
function _constraint_thermal_limit_from(pm::AbstractDCPowerModel, f_idx, rate_a)
    p_fr = var(pm, :p, f_idx)
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
        cstr = JuMP.LowerBoundRef(p_fr)
        JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)
        if JuMP.has_upper_bound(p_fr)
            JuMP.upper_bound(p_fr) > rate_a && JuMP.set_upper_bound(p_fr, rate_a)
        end
    else
        cstr = JuMP.@constraint(pm.model, p_fr <= rate_a)
    end
end

""
function constraint_thermal_limit_to(pm::AbstractPowerModel, i::Int)
    branch = ref(pm, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    t_idx = (i, t_bus, f_bus)

    if haskey(branch, "rate_a")
        _constraint_thermal_limit_to(pm, t_idx, branch["rate_a"])
    end
end

"`p[t_idx]^2 + q[t_idx]^2 <= rate_a^2`"
function _constraint_thermal_limit_to(pm::AbstractDCPowerModel, t_idx, rate_a)
    l,i,j = t_idx
    p_fr = var(pm, :p, (l,j,i))
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_upper_bound(p_fr)
        cstr = JuMP.UpperBoundRef(p_fr)
    else
        p_to = var(pm, :p, t_idx)
        cstr = JuMP.@constraint(pm.model, p_to <= rate_a)
    end
end

### DC LINES ###
""
function constraint_dcline_power_losses(pm::AbstractDCPowerModel, i::Int)
    dcline = ref(pm, :dcline, i)
    f_bus = dcline["f_bus"]
    t_bus = dcline["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    loss0 = dcline["loss0"]
    loss1 = dcline["loss1"]

    _constraint_dcline_power_losses(pm, f_bus, t_bus, f_idx, t_idx, loss0, loss1)
end

"""
Creates Line Flow constraint for DC Lines (Matpower Formulation)

```
p_fr + p_to == loss0 + p_fr * loss1
```
"""
function _constraint_dcline_power_losses(pm::AbstractDCPowerModel, f_bus, t_bus, f_idx, t_idx, loss0, loss1)
    p_fr = var(pm, :p_dc, f_idx)
    p_to = var(pm, :p_dc, t_idx)

    JuMP.@constraint(pm.model, (1-loss1) * p_fr + (p_to - loss0) == 0)
end

"Fixed Power Factor"
function constraint_power_factor(pm::AbstractACPowerModel)

    z_demand = var(pm, :z_demand)
    p_lc = var(pm, :p_lc)
    q_lc = var(pm, :q_lc)
    
    for (l,_) in ref(pm, :load)
        JuMP.@constraint(pm.model, z_demand[i]*p_lc[i] - q_lc[i] == 0.0)      
    end
end

""
function constraint_voltage_magnitude_diff(pm::AbstractDCPowerModel, i::Int)

    branch = ref(pm, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    r = branch["br_r"]
    x = branch["br_x"]
    g_sh_fr = branch["g_fr"]
    b_sh_fr = branch["b_fr"]
    tm = branch["tap"]

    _constraint_voltage_magnitude_difference(pm, i, f_bus, t_bus, f_idx, t_idx, r, x, g_sh_fr, b_sh_fr, tm)
end

"""
Defines voltage drop over a branch, linking from and to side voltage magnitude
"""
function _constraint_voltage_magnitude_difference(pm::AbstractDCPowerModel, i, f_bus, t_bus, f_idx, t_idx, r, x, g_sh_fr, b_sh_fr, tm)
    p_fr = var(pm, :p, f_idx)
    #q_fr = var(pm, n, :q, f_idx)
    q_fr = 0
    w_fr = var(pm, :w, f_bus)
    w_to = var(pm, :w, t_bus)
    ccm =  var(pm, :ccm, i)

    ym_sh_sqr = g_sh_fr^2 + b_sh_fr^2

    JuMP.@constraint(pm.model, (1+2*(r*g_sh_fr - x*b_sh_fr))*(w_fr/tm^2) - w_to ==  2*(r*p_fr + x*q_fr) - (r^2 + x^2)*(ccm + ym_sh_sqr*(w_fr/tm^2) - 2*(g_sh_fr*p_fr - b_sh_fr*q_fr)))
end
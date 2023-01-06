
#***************************************************** CONSTRAINTS *************************************************************************
"Fix the voltage angle to zero at the reference bus"
function con_theta_ref(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    JuMP.fix(var(pm, :va, nw)[i], 0, force = true)
    #@constraint(pm.model, var(pm, :va, nw)[i] == 0)
end

"""
This constraint captures problem agnostic constraints that are used to link
the model's voltage variables together, in addition to the standard problem
formulation constraints.
"""
function con_model_voltage(pm::AbstractPowerModel, bp::Tuple{Int,Int}; nw::Int=1)
    _con_model_voltage(pm, bp, nw)
end

"Nodal power balance constraints"
function con_power_balance(pm::AbstractPowerModel, system::SystemModel, i::Int, t::Int; nw::Int=1)

    #bus_arcs = filter(!ismissing, skipmissing(topology(pm, :busarcs)[i]))
    bus_arcs = topology(pm, :busarcs)[i]
    bus_gens = topology(pm, :generators_nodes)[i]
    bus_loads = topology(pm, :loads_nodes)[i]
    bus_shunts = topology(pm, :shunts_nodes)[i]
    bus_storage = topology(pm, :storages_nodes)[i]

    bus_pd = Float32.([field(system, :loads, :pd)[k,t] for k in bus_loads])
    bus_qd = Float32.([field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in bus_loads])

    bus_gs = Dict{Int, Float32}(k => field(system, :shunts, :gs)[k] for k in bus_shunts)
    bus_bs = Dict{Int, Float32}(k => field(system, :shunts, :bs)[k] for k in bus_shunts)

    _con_power_balance(pm, system, i, nw, bus_arcs, bus_gens, bus_loads, bus_shunts, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

end

"Nodal power balance constraints without load curtailment variables"
function con_power_balance_nolc(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    bus_arcs = topology(pm, :busarcs)[i]
    generators_nodes = topology(pm, :generators_nodes)[i]
    loads_nodes = topology(pm, :loads_nodes)[i]
    shunts_nodes = topology(pm, :shunts_nodes)[i]
    storages_nodes = topology(pm, :storages_nodes)[i]

    bus_pd = Float32.([field(system, :loads, :pd)[k] for k in loads_nodes])
    bus_qd = Float32.([field(system, :loads, :qd)[k] for k in loads_nodes])
    bus_gs = Float32.([field(system, :shunts, :gs)[k] for k in shunts_nodes])
    bus_bs = Float32.([field(system, :shunts, :bs)[k] for k in shunts_nodes])

    _con_power_balance_nolc(pm, system, i, nw, bus_arcs, generators_nodes, loads_nodes, shunts_nodes, storages_nodes, bus_pd, bus_qd, bus_gs, bus_bs)

end

"Branch - Ohm's Law Constraints"
function con_ohms_yt(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[i]
    t_bus = field(system, :branches, :t_bus)[i]
    g, b = calc_branch_y(field(system, :branches), i)
    tr, ti = calc_branch_t(field(system, :branches), i)
    tm = field(system, :branches, :tap)[i]
    va_fr_to = @expression(pm.model, var(pm, :va, nw)[f_bus] - var(pm, :va, nw)[t_bus])

    g_fr = field(system, :branches, :g_fr)[i]
    b_fr = field(system, :branches, :b_fr)[i]
    g_to = field(system, :branches, :g_to)[i]
    b_to = field(system, :branches, :b_to)[i]

    _con_ohms_yt_from(pm, i, nw, f_bus, t_bus, g, b, g_fr, b_fr, tr, ti, tm, va_fr_to)
    _con_ohms_yt_to(pm, i, nw, f_bus, t_bus, g, b, g_to, b_to, tr, ti, tm, va_fr_to)

end

"Branch - Phase Angle Difference Constraints "
function con_voltage_angle_difference(pm::AbstractPowerModel, bp::Tuple{Int,Int}; nw::Int=1)

    f_bus,t_bus = bp
    buspair = topology(pm, :buspairs)[bp]
    _con_voltage_angle_difference(pm, nw, f_bus, t_bus, buspair[2], buspair[3])

end

"Polar Form"
function _con_voltage_angle_difference(pm::AbstractPolarModels, nw::Int, f_bus::Int, t_bus::Int, angmin, angmax)
    
    va_fr = var(pm, :va, nw)[f_bus]
    va_to = var(pm, :va, nw)[t_bus]
    con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)] = @constraint(pm.model, va_fr - va_to <= angmax)
    con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)] = @constraint(pm.model, va_fr - va_to >= angmin)

end

"Adds the (upper and lower) thermal limit constraints for the desired branch to the PowerModel."
function con_thermal_limits(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    f_bus = field(system, :branches, :f_bus)[i] 
    t_bus = field(system, :branches, :t_bus)[i]
    rate_a = field(system, :branches, :rate_a)[i]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    _con_thermal_limit_from(pm, nw, i, f_idx, rate_a)
    _con_thermal_limit_to(pm, nw, i, t_idx, rate_a)

end

# Generic thermal limit constraint
"`p[f_idx]^2 + q[f_idx]^2 <= rate_a^2`"
function _con_thermal_limit_from(pm::AbstractPowerModel, n::Int, i::Int, f_idx, rate_a)

    p_fr = var(pm, :p, n)[f_idx]
    q_fr = var(pm, :q, n)[f_idx]
    con(pm, :thermal_limit_from, n)[i] = @constraint(pm.model, p_fr^2 + q_fr^2 <= rate_a^2)
    
end

"`p[t_idx]^2 + q[t_idx]^2 <= rate_a^2`"
function _con_thermal_limit_to(pm::AbstractPowerModel, n::Int, i::Int, t_idx, rate_a)
    
    p_to = var(pm, :p, n)[t_idx]
    q_to = var(pm, :q, n)[t_idx]
    con(pm, :thermal_limit_to, n)[i] = @constraint(pm.model, p_to^2 + q_to^2 <= rate_a^2)

end


#***************************************************** STORAGE CONSTRAINTS ************************************************************************
""
function con_storage_state(pm::AbstractPowerModel, system::SystemModel{N,L,T}, i::Int; nw::Int=1) where {N,L,T<:Period}

    energy = field(system, :storages, :energy)[i]
    charge_eff = field(system, :storages, :charge_efficiency)[i]
    discharge_eff = field(system, :storages, :discharge_efficiency)[i]

    if L==1 && T ≠ Hour
        @error("Parameters L=$(L) and T=$(T) must be 1 and Hour respectively. More options available soon")
    end

    _con_storage_state_initial(pm, nw, i, energy, charge_eff, discharge_eff, L)
end

""
function _con_storage_state_initial(pm::AbstractPowerModel, n::Int, i::Int, energy, charge_eff, discharge_eff, time_elapsed)

    sc = var(pm, :sc, n)[i]
    sd = var(pm, :sd, n)[i]
    se = var(pm, :se, n)[i]

    con(pm, :storage_state, n)[i] = @constraint(pm.model, se - time_elapsed*(charge_eff*sc - sd/discharge_eff) == energy)
end

""
function con_storage_complementarity_mi(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    charge_ub = field(system, :storages, :charge_rating)[i]
    discharge_ub = field(system, :storages, :discharge_rating)[i]

    sc = var(pm, :sc, nw)[i]
    sd = var(pm, :sd, nw)[i]
    sc_on = var(pm, :sc_on, nw)[i]
    sd_on = var(pm, :sd_on, nw)[i]

    con(pm, :storage_complementarity_mi_1, nw)[i] = @constraint(pm.model, sc_on + sd_on == 1)
    con(pm, :storage_complementarity_mi_2, nw)[i] = @constraint(pm.model, sc_on*charge_ub >= sc)
    con(pm, :storage_complementarity_mi_3, nw)[i] = @constraint(pm.model, sd_on*discharge_ub >= sd)

end

""
function con_storage_losses(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    storage_bus = field(system, :storages, :buses)[i]
    storage_r = field(system, :storages, :r)[i]
    storage_x = field(system, :storages, :x)[i]
    p_loss = field(system, :storages, :ploss)[i]
    q_loss = field(system, :storages, :qloss)[i]

    _con_storage_losses(pm, nw, i, storage_bus, storage_r, storage_x, p_loss, q_loss)
end

""
function con_storage_thermal_limit(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    thermal_rating = field(system, :storages, :thermal_rating)[i]
    _con_storage_thermal_limit(pm, nw, i, thermal_rating)
end
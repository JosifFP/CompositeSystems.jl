
#***************************************************** CONSTRAINTS *************************************************************************
"Fix the voltage angle to zero at the reference bus"
function con_theta_ref(
    pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    @constraint(pm.model, var(pm, :va, nw)[i] == 0)
end

"Nodal power balance constraints"
function con_power_balance(
    pm::AbstractPowerModel, system::SystemModel, i::Int, t::Int; nw::Int=1)

    bus_arcs = topology(pm, :busarcs_available)[i]
    bus_gens = topology(pm, :buses_generators_available)[i]
    buses_loads_available = topology(pm, :buses_loads_available)[i]
    buses_shunts_available = topology(pm, :buses_shunts_available)[i]
    buses_storages_available = topology(pm, :buses_storages_available)[i]

    bus_pd = Dict{Int, Float32}(k => field(system, :loads, :pd)[k,t] for k in buses_loads_available)
    bus_qd = Dict{Int, Float32}(k => field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in buses_loads_available)
    bus_gs = Dict{Int, Float32}(k => field(system, :shunts, :gs)[k] for k in buses_shunts_available)
    bus_bs = Dict{Int, Float32}(k => field(system, :shunts, :bs)[k] for k in buses_shunts_available)

    _con_power_balance(pm, i, nw, bus_arcs, bus_gens, buses_storages_available, bus_pd, bus_qd, bus_gs, bus_bs)
end

"Nodal power balance constraints without load curtailment variables"
function con_power_balance_nolc(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)

    bus_arcs = topology(pm, :busarcs_available)[i]
    buses_generators = topology(pm, :buses_generators_available)[i]
    buses_loads = topology(pm, :buses_loads_available)[i]
    buses_shunts = topology(pm, :buses_shunts_available)[i]
    buses_storages = topology(pm, :buses_storages_available)[i]

    bus_pd = Float32[field(system, :loads, :pd)[k] for k in buses_loads]
    bus_qd = Float32[field(system, :loads, :qd)[k] for k in buses_loads]
    bus_gs = Float32[field(system, :shunts, :gs)[k] for k in buses_shunts]
    bus_bs = Float32[field(system, :shunts, :bs)[k] for k in buses_shunts]

    _con_power_balance_nolc(
        pm, i, nw, bus_arcs, buses_generators, buses_storages, bus_pd, bus_qd, bus_gs, bus_bs)
end

"Branch - Phase Angle Difference Constraints (per branch)"
function con_voltage_angle_difference_on_off(pm::AbstractPolarModels, system::SystemModel, l::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[l]
    t_bus = field(system, :branches, :t_bus)[l]
    angmin = field(system, :branches, :angmin)[l]
    angmax = field(system, :branches, :angmax)[l]
    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]
    _con_voltage_angle_difference_on_off(pm, nw, l, f_bus, t_bus, angmin, angmax, vad_min, vad_max)

end

""
function _con_voltage_angle_difference_on_off(
    pm::AbstractPolarModels, nw::Int, l::Int, f_bus::Int, t_bus::Int, angmin, angmax, vad_min, vad_max)

    va_fr = var(pm, :va, nw)[f_bus]
    va_to = var(pm, :va, nw)[t_bus]
    z = var(pm, :z_branch, nw)[l]
    con(pm, :voltage_angle_diff_upper, nw)[l] = @constraint(pm.model, va_fr - va_to <= angmax*z + vad_max*(1-z))
    con(pm, :voltage_angle_diff_lower, nw)[l] = @constraint(pm.model, va_fr - va_to >= angmin*z + vad_min*(1-z))

end

"Branch - Phase Angle Difference Constraints (per branch)"
function con_voltage_angle_difference(pm::AbstractPolarModels, system::SystemModel, l::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[l]
    t_bus = field(system, :branches, :t_bus)[l]
    angmin = field(system, :branches, :angmin)[l]
    angmax = field(system, :branches, :angmax)[l]
    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]
    _con_voltage_angle_difference(pm, nw, l, f_bus, t_bus, angmin, angmax, vad_min, vad_max)

end

"nothing to do, no voltage angle variables"
function con_voltage_angle_difference(pm::AbstractNFAModel, system::SystemModel, l::Int; nw::Int=1)
end

""
function _con_voltage_angle_difference(
    pm::AbstractPolarModels, nw::Int, l::Int, f_bus::Int, t_bus::Int, angmin, angmax, vad_min, vad_max)

    va_fr = var(pm, :va, nw)[f_bus]
    va_to = var(pm, :va, nw)[t_bus]
    con(pm, :voltage_angle_diff_upper, nw)[l] = @constraint(pm.model, va_fr - va_to <= angmax)
    con(pm, :voltage_angle_diff_lower, nw)[l] = @constraint(pm.model, va_fr - va_to >= angmin)
end

""
function con_thermal_limits_on_off(pm::AbstractPowerModel, system::SystemModel, l::Int; nw::Int=1)

    f_bus = field(system, :branches, :f_bus)[l] 
    t_bus = field(system, :branches, :t_bus)[l]
    rate_a = field(system, :branches, :rate_a)[l]
    f_idx = (l, f_bus, t_bus)
    t_idx = (l, t_bus, f_bus)
    _con_thermal_limit_from_on_off(pm, nw, l, f_idx, rate_a)
    _con_thermal_limit_to_on_off(pm, nw, l, t_idx, rate_a)

end

# Generic thermal limit constraint
"`p[f_idx]^2 + q[f_idx]^2 <= rate_a^2`"
function _con_thermal_limit_from_on_off(pm::AbstractPowerModel, n::Int, l::Int, f_idx, rate_a)

    p_fr = var(pm, :p, n)[f_idx]
    q_fr = var(pm, :q, n)[f_idx]
    z = var(pm, :z_branch, n)[l]
    con(pm, :thermal_limit_from, n)[l] = @constraint(pm.model, p_fr^2 + q_fr^2 <= rate_a^2*z^2)
end

"`p[t_idx]^2 + q[t_idx]^2 <= rate_a^2`"
function _con_thermal_limit_to_on_off(pm::AbstractPowerModel, n::Int, l::Int, t_idx, rate_a)
    
    p_to = var(pm, :p, n)[t_idx]
    q_to = var(pm, :q, n)[t_idx]
    z = var(pm, :z_branch, n)[l]
    con(pm, :thermal_limit_to, n)[l] = @constraint(pm.model, p_to^2 + q_to^2 <= rate_a^2*z^2)
end

"Adds the (upper and lower) thermal limit constraints for the desired branch to the PowerModel."
function con_thermal_limits(pm::AbstractPowerModel, system::SystemModel, l::Int; nw::Int=1)

    f_bus = field(system, :branches, :f_bus)[l] 
    t_bus = field(system, :branches, :t_bus)[l]
    rate_a = field(system, :branches, :rate_a)[l]
    f_idx = (l, f_bus, t_bus)
    t_idx = (l, t_bus, f_bus)
    _con_thermal_limit_from(pm, nw, l, f_idx, rate_a)
    _con_thermal_limit_to(pm, nw, l, t_idx, rate_a)
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

""
function con_ohms_yt_on_off(pm::AbstractPowerModel, system::SystemModel, l::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[l]
    t_bus = field(system, :branches, :t_bus)[l]
    g, b = calc_branch_y(system.branches, l)
    tr, ti = calc_branch_t(system.branches, l)
    tm = field(system, :branches, :tap)[l]

    va_fr  = var(pm, :va, nw)[f_bus]
    va_to  = var(pm, :va, nw)[t_bus]
    g_fr = field(system, :branches, :g_fr)[l]
    b_fr = field(system, :branches, :b_fr)[l]
    g_to = field(system, :branches, :g_to)[l]
    b_to = field(system, :branches, :b_to)[l]
    _con_ohms_yt_from_on_off(pm, l, nw, f_bus, t_bus, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    _con_ohms_yt_to_on_off(pm, l, nw, f_bus, t_bus, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
end

""
function con_ohms_yt(pm::AbstractPowerModel, system::SystemModel, l::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[l]
    t_bus = field(system, :branches, :t_bus)[l]
    g, b = calc_branch_y(system.branches, l)
    tr, ti = calc_branch_t(system.branches, l)
    tm = field(system, :branches, :tap)[l]
    va_fr  = var(pm, :va, nw)[f_bus]
    va_to  = var(pm, :va, nw)[t_bus]
    g_fr = field(system, :branches, :g_fr)[l]
    b_fr = field(system, :branches, :b_fr)[l]
    g_to = field(system, :branches, :g_to)[l]
    b_to = field(system, :branches, :b_to)[l]
    
    _con_ohms_yt_from(pm, l, nw, f_bus, t_bus, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    _con_ohms_yt_to(pm, l, nw, f_bus, t_bus, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
end

#***************************************************** STORAGE CONSTRAINTS ************************************************************************
""
function con_storage_state(pm::AbstractPowerModel, system::SystemModel{N,L,T}, i::Int; nw::Int=1) where {N,L,T<:Period}

    energy = field(system, :storages, :energy)[i]
    charge_eff = field(system, :storages, :charge_efficiency)[i]
    discharge_eff = field(system, :storages, :discharge_efficiency)[i]
    @assert L == 1 && T == Hour "Parameters L=$(L) and T=$(T) must be 1 and Hour respectively. More options available soon"
    _con_storage_state_initial(pm, nw, i, energy, charge_eff, discharge_eff, L)
end

""
function _con_storage_state_initial(pm::AbstractPowerModel, n::Int, i::Int, energy, charge_eff, discharge_eff, time_elapsed)

    sc = var(pm, :sc, n)[i]
    sd = var(pm, :sd, n)[i]
    stored_energy = var(pm, :stored_energy, n)[i]
    
    con(pm, :storage_state, n)[i] = @constraint(pm.model, stored_energy - time_elapsed*(charge_eff*sc - sd/discharge_eff) == energy)
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
    vmin = field(system, :buses, :vmin)[i]
    vmax = field(system, :buses, :vmax)[i]
    _con_storage_losses(pm, nw, i, storage_bus, storage_r, storage_x, p_loss, q_loss, vmin, vmax)
end

""
function con_storage_thermal_limit(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    thermal_rating = field(system, :storages, :thermal_rating)[i]
    _con_storage_thermal_limit(pm, nw, i, thermal_rating)
end

""
function _con_storage_thermal_limit(pm::AbstractPowerModel, n::Int, i::Int, rating::Float32)
    ps = var(pm, :ps, n)[i]
    qs = var(pm, :qs, n)[i]
    con(pm, :storage_thermal_limit, n)[i] = @constraint(pm.model, ps^2 + qs^2 <= rating^2)
end
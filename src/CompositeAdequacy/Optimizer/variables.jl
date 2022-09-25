
""
function comp_start_value(comp::Dict{String,<:Any}, key::String, default=0.0)
    return get(comp, key, default)
end

""
function var_bus_voltage(pm::AbstractDCPModel; kwargs...)
    var_bus_voltage_angle(pm; kwargs...)
end

# ""
# function var_bus_voltage(pm::AbstractACPModel; kwargs...)
#     var_bus_voltage_angle(pm; kwargs...)
#     var_bus_voltage_magnitude(pm; kwargs...)
# end

""
function var_bus_voltage_angle(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)

    va = var(pm, nw)[:va] = JuMP.@variable(pm.model, [i in ids(pm, nw, :bus)], base_name="$(nw)_va", start = comp_start_value(ref(pm, nw, :bus, i), "va_start"))

end

""
function var_gen_power(pm::AbstractDCPModel; kwargs...)
    var_gen_power_real(pm; kwargs...)
end

""
function var_gen_power(pm::AbstractACPModel; kwargs...)
    var_gen_power_real(pm; kwargs...)
    var_gen_power_imaginary(pm; kwargs...)
end

""
function var_gen_power_real(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)

    pg = var(pm, nw)[:pg] = JuMP.@variable(pm.model, [i in ids(pm, nw, :gen)], base_name="$(nw)_pg", start = comp_start_value(ref(pm, nw, :gen, i), "pg_start"))    

    if bounded
        for (i, gen) in ref(pm, nw, :gen)
            JuMP.set_upper_bound(pg[i], gen["pmax"])
            JuMP.set_lower_bound(pg[i], 0.0)
            # if gen["pmin"]>=0.0
            #     JuMP.set_lower_bound(pg[i], gen["pmin"])
            # else
            #     JuMP.set_lower_bound(pg[i], 0.0)
            # end
        end
    end

end

""
function var_gen_power_imaginary(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)

    qg = var(pm, nw)[:qg] = JuMP.@variable(pm.model, [i in ids(pm, nw, :gen)], base_name="$(nw)_qg", start = comp_start_value(ref(pm, nw, :gen, i), "qg_start"))

    if bounded
        for (i, gen) in ref(pm, nw, :gen)
            JuMP.set_lower_bound(qg[i], gen["qmin"])
            JuMP.set_upper_bound(qg[i], gen["qmax"])
        end
    end
end

"""
Defines DC power flow variables p to represent the active power flow for each branch
"""
function var_branch_power(pm::AbstractDCPModel; kwargs...)
    var_branch_power_real(pm; kwargs...)
end

"""
Defines AC power flow variables p to represent the active power flow for each branch
"""
function var_branch_power(pm::AbstractACPModel; kwargs...)
    var_branch_power_real(pm; kwargs...)
    var_branch_power_imaginary(pm; kwargs...)
end

""
function var_branch_power_real(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)

    p = var(pm, nw)[:p] = JuMP.@variable(pm.model, [(l,i,j) in ref(pm, nw, :arcs)], base_name="$(nw)_p", start = comp_start_value(ref(pm, nw, :branch, l), "p_start"))

    if bounded
        flow_lb, flow_ub = ref_calc_branch_flow_bounds(ref(pm, nw, :branch), ref(pm, nw, :bus))

        for arc in ref(pm, nw, :arcs)
            l,i,j = arc
            if !isinf(flow_lb[l])
                JuMP.set_lower_bound(p[arc], flow_lb[l])
            end
            if !isinf(flow_ub[l])
                JuMP.set_upper_bound(p[arc], flow_ub[l])
            end
        end
    end

    for (l,branch) in ref(pm, nw, :branch)
        if haskey(branch, "pf_start")
            f_idx = (l, branch["f_bus"], branch["t_bus"])
            JuMP.set_start_value(p[f_idx], branch["pf_start"])
        end
        if haskey(branch, "pt_start")
            t_idx = (l, branch["t_bus"], branch["f_bus"])
            JuMP.set_start_value(p[t_idx], branch["pt_start"])
        end
    end

end

""
function var_branch_power_imaginary(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)
    
    #@variable(pm.model, q[(l,i,j) in pm.ref[:arcs]])
    q = var(pm, nw)[:q] = JuMP.@variable(pm.model, [(l,i,j) in ref(pm, nw, :arcs)], base_name="$(nw)_q", start = comp_start_value(ref(pm, nw, :branch, l), "q_start"))

    if bounded
        flow_lb, flow_ub = ref_calc_branch_flow_bounds(ref(pm, nw, :branch), ref(pm, nw, :bus))

        for arc in ref(pm, nw, :arcs)
            l,i,j = arc
            if !isinf(flow_lb[l])
                JuMP.set_lower_bound(q[arc], flow_lb[l])
            end
            if !isinf(flow_ub[l])
                JuMP.set_upper_bound(q[arc], flow_ub[l])
            end
        end
    end

    for (l,branch) in ref(pm, nw, :branch)
        if haskey(branch, "qf_start")
            f_idx = (l, branch["f_bus"], branch["t_bus"])
            JuMP.set_start_value(q[f_idx], branch["qf_start"])
        end
        if haskey(branch, "qt_start")
            t_idx = (l, branch["t_bus"], branch["f_bus"])
            JuMP.set_start_value(q[t_idx], branch["qt_start"])
        end
    end

end

""
function var_dcline_power(pm::AbstractDCPModel; kwargs...)
    var_dcline_power_real(pm; kwargs...)
end

""
function var_dcline_power(pm::AbstractACPModel; kwargs...)
    var_dcline_power_real(pm; kwargs...)
    var_dcline_power_imaginary(pm; kwargs...)
end

"variable: `p_dc[l,i,j]` for `(l,i,j)` in `arcs_dc`"
function var_dcline_power_real(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)

    p_dc = var(pm, nw)[:p_dc] = JuMP.@variable(pm.model, [arc in ref(pm, nw, :arcs_dc)], base_name="$(nw)_p_dc")

    if bounded
        for (l,dcline) in ref(pm, nw, :dcline)
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])

            JuMP.set_lower_bound(p_dc[f_idx], dcline["pminf"])
            JuMP.set_upper_bound(p_dc[f_idx], dcline["pmaxf"])

            JuMP.set_lower_bound(p_dc[t_idx], dcline["pmint"])
            JuMP.set_upper_bound(p_dc[t_idx], dcline["pmaxt"])
        end
    end

    for (l,dcline) in ref(pm, nw, :dcline)
        if haskey(dcline, "pf")
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            JuMP.set_start_value(p_dc[f_idx], dcline["pf"])
        end

        if haskey(dcline, "pt")
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])
            JuMP.set_start_value(p_dc[t_idx], dcline["pt"])
        end
    end

end

"variable: `q_dc[l,i,j]` for `(l,i,j)` in `arcs_dc`"
function var_dcline_power_imaginary(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)

    q_dc = var(pm, nw)[:q_dc] = JuMP.@variable(pm.model, [arc in ref(pm, nw, :arcs_dc)], base_name="$(nw)_q_dc",)

    if bounded
        for (l,dcline) in ref(pm, nw, :dcline)
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])

            JuMP.set_lower_bound(q_dc[f_idx], dcline["qminf"])
            JuMP.set_upper_bound(q_dc[f_idx], dcline["qmaxf"])

            JuMP.set_lower_bound(q_dc[t_idx], dcline["qmint"])
            JuMP.set_upper_bound(q_dc[t_idx], dcline["qmaxt"])
        end
    end

    for (l,dcline) in ref(pm, nw, :dcline)
        if haskey(dcline, "qf")
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            JuMP.set_start_value(q_dc[f_idx], dcline["qf"])
        end

        if haskey(dcline, "qt")
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])
            JuMP.set_start_value(q_dc[t_idx], dcline["qt"])
        end
    end

end

"variables for modeling storage units, includes grid injection and internal variables, with mixed int variables for charge/discharge"
function variable_storage_power_mi(pm::AbstractPowerModel; kwargs...)
    PowerModels.variable_storage_power_real(pm; kwargs...)
    PowerModels.variable_storage_power_imaginary(pm; kwargs...)
    PowerModels.variable_storage_power_control_imaginary(pm; kwargs...)
    PowerModels.variable_storage_current(pm; kwargs...)
    PowerModels.variable_storage_energy(pm; kwargs...)
    PowerModels.variable_storage_charge(pm; kwargs...)
    PowerModels.variable_storage_discharge(pm; kwargs...)
    PowerModels.variable_storage_complementary_indicator(pm; kwargs...)
end

"""
Defines load curtailment variables p to represent the active power flow for each branch
"""

function var_load_curtailment(pm::AbstractDCPModel; kwargs...)
    var_load_curtailment_real(pm; kwargs...)
end

""
function var_load_curtailment(pm::AbstractACPModel; kwargs...)
    var_load_curtailment_real(pm; kwargs...)
    var_load_curtailment_imaginary(pm; kwargs...)
end

function var_load_curtailment_real(pm::AbstractPowerModel; nw::Int=0)

    p_lc = var(pm, nw)[:p_lc] = JuMP.@variable(pm.model, [i in ids(pm, nw, :load)], base_name="$(nw)_p_lc")

    for (l,load) in ref(pm, nw, :load)
        JuMP.set_upper_bound(p_lc[i],load["pd"])
        JuMP.set_lower_bound(p_lc[i],0.0)
    end
end

"""
Defines load curtailment variables q to represent the active power flow for each branch
"""
function var_load_curtailment_imaginary(pm::AbstractPowerModel; nw::Int=0)
    
    q_lc = var(pm, nw)[:q_lc] = JuMP.@variable(pm.model, [i in ids(pm, nw, :load)], base_name="$(nw)_q_lc")

    for (l,load) in ref(pm, nw, :load)
        JuMP.set_upper_bound(q_lc[i],load["qd"])
        JuMP.set_lower_bound(q_lc[i],0.0)
    end
end

""
function var_load_power_factor_range(pm::AbstractPowerModel; nw::Int=0)

    z_demand = var(pm, nw)[:z_demand] = JuMP.@variable(pm.model, [i in ids(pm, nw, :load)], base_name="$(nw)_z_demand")

    for (l,load) in ref(pm, nw, :load)
        JuMP.set_lower_bound(z_demand[i], -Float32(load["qd"]/load["pd"]))
        JuMP.set_upper_bound(z_demand[i], Float32(load["qd"]/load["pd"]))
    end
end

function var_buspair_current_magnitude_sqr(pm::AbstractPowerModel; nw::Int=0)
    
    ccm = var(pm, nw)[:ccm] = JuMP.@variable(pm.model, [i in ids(pm, nw, :ccm)], base_name="$(nw)_ccm")

    for (i, b) in ref(pm, nw, :branch)
        rate_a = Inf
        if haskey(b, "rate_a")
            rate_a = b["rate_a"]
        end
        ub = ((rate_a*b["tap"])/(ref(pm, nw, :bus)[b["f_bus"]]["vmin"]))^2
        JuMP.set_lower_bound(ccm[i], 0.0)
        if !isinf(ub)
            JuMP.set_upper_bound(ccm[i], ub)
        end
    end

end


""
function var_bus_voltage_magnitude(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)

    vm = var(pm, nw)[:vm] = JuMP.@variable(pm.model, [i in ids(pm, nw, :bus)], base_name="$(nw)_vm", start=1.0)

    if bounded
        for (i, bus) in ref(pm, nw, :bus)
            JuMP.set_lower_bound(vm[i], bus["vmin"])
            JuMP.set_upper_bound(vm[i], bus["vmax"])
        end
    end

end

""
function var_bus_voltage_magnitude_sqr(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)
    
    w = var(pm, nw)[:w] = JuMP.@variable(pm.model, [i in ids(pm, nw, :bus)], base_name="$(nw)_w",start=1.001)

    if bounded
        for (i, bus) in ref(pm, nw, :bus)
            JuMP.set_lower_bound(w[i], bus["vmin"]^2)
            JuMP.set_upper_bound(w[i], bus["vmax"]^2)
        end
    end
end

""
function var_buspair_voltage_product(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)

    wr_min, wr_max, wi_min, wi_max = calc_voltage_product_bounds(pm.ref[:buspairs])

    wr = var(pm, nw)[:wr] = JuMP.@variable(pm.model, [i in ids(pm, nw, :buspairs)], base_name="$(nw)_wr",start=1.00)
    wi = var(pm, nw)[:wi] = JuMP.@variable(pm.model, [i in ids(pm, nw, :buspairs)], base_name="$(nw)_wi")

    if bounded
        for (i, _) in ref(pm, nw, :buspairs)
            JuMP.set_lower_bound(wr[i], wr_min[i])
            JuMP.set_lower_bound(wi[i], wr_min[i])
            JuMP.set_upper_bound(wr[i], wr_max[i])
            JuMP.set_upper_bound(wi[i], wr_max[i])
        end
    end


end
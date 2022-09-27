
""
function comp_start_value(comp::Dict{String,<:Any}, key::String, default=0.0)
    return get(comp, key, default)
end

""
function var_bus_voltage(pm::AbstractPowerModel; kwargs...)
    var_bus_voltage_angle(pm; kwargs...)
    var_bus_voltage_magnitude(pm; kwargs...)
end

""
function var_bus_voltage_angle(pm::AbstractPowerModel; nw::Int=0, bounded::Bool=true)
    va = var(pm, nw)[:va] = JuMP.@variable(pm.model, [i in ids(pm, nw, :bus)], base_name="$(nw)_va", start = comp_start_value(ref(pm, nw, :bus, i), "va_start"))
    #sol_component_value(pm, nw, :bus, :va, ids(pm, nw, :bus), va)
end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel; nw::Int=0, bounded::Bool=true)
    #sol_component_fixed(pm, nw, :bus, :vm, ids(pm, nw, :bus), 1.0)
end

"variable: `v[i]` for `i` in `bus`es"
function var_bus_voltage_magnitude(pm::AbstractACPowerModel; nw::Int=0, bounded::Bool=true)

    vm = var(pm, nw)[:vm] = JuMP.@variable(pm.model, [i in ids(pm, nw, :bus)], base_name="$(nw)_vm", start = comp_start_value(ref(pm, nw, :bus, i), "vm_start", 1.0))
    if bounded
        for (i, bus) in ref(pm, nw, :bus)
            JuMP.set_lower_bound(vm[i], bus["vmin"])
            JuMP.set_upper_bound(vm[i], bus["vmax"])
        end
    end
    #sol_component_value(pm, nw, :bus, :vm, ids(pm, nw, :bus), vm)
end

""
function var_gen_power(pm::AbstractPowerModel; kwargs...)
    var_gen_power_real(pm; kwargs...)
    var_gen_power_imaginary(pm; kwargs...)
end

""
function var_gen_power_real(pm::AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

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

    sol_component_value(pm, nw, :gen, :pg, ids(pm, nw, :gen), pg)

end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel; nw::Int=0, kwargs...)
    #sol_component_fixed(pm, nw, :gen, :qg, ids(pm, nw, :gen), NaN)
end

""
function var_gen_power_imaginary(pm::AbstractACPowerModel; nw::Int=0, bounded::Bool=true)

    qg = var(pm, nw)[:qg] = JuMP.@variable(pm.model, [i in ids(pm, nw, :gen)], base_name="$(nw)_qg", start = comp_start_value(ref(pm, nw, :gen, i), "qg_start"))

    if bounded
        for (i, gen) in ref(pm, nw, :gen)
            JuMP.set_lower_bound(qg[i], gen["qmin"])
            JuMP.set_upper_bound(qg[i], gen["qmax"])
        end
    end
    #sol_component_fixed(pm, nw, :gen, :qg, ids(pm, nw, :gen), qg)
end

"""
Defines DC or AC power flow variables p to represent the active power flow for each branch
"""
function var_branch_power(pm::AbstractPowerModel; kwargs...)
    var_branch_power_real(pm; kwargs...)
    var_branch_power_imaginary(pm; kwargs...)
end

""
function var_branch_power_real(pm::AbstractDCPowerModel; nw::Int=0, bounded::Bool=true)

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
    end

    # this explicit type erasure is necessary
    p_expr = Dict{Any,Any}( ((l,i,j), p[(l,i,j)]) for (l,i,j) in ref(pm, nw, :arcs_from) )
    p_expr = merge(p_expr, Dict( ((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in ref(pm, nw, :arcs_from)))
    var(pm, nw)[:p] = p_expr

    #sol_component_value_edge(pm, nw, :branch, :pf, :pt, ref(pm, nw, :arcs_from), ref(pm, nw, :arcs_to), p_expr)

end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel; nw::Int=0, kwargs...)
    #sol_component_fixed(pm, nw, :branch, :qf, ids(pm, nw, :branch), NaN)
    #sol_component_fixed(pm, nw, :branch, :qt, ids(pm, nw, :branch), NaN)
end

# ""
# function var_branch_power_real(pm::AbstractACPowerModel; nw::Int=0, bounded::Bool=true)

#     p = var(pm, nw)[:p] = JuMP.@variable(pm.model, [(l,i,j) in ref(pm, nw, :arcs)], base_name="$(nw)_p", start = comp_start_value(ref(pm, nw, :branch, l), "p_start"))

#     if bounded
#         flow_lb, flow_ub = ref_calc_branch_flow_bounds(ref(pm, nw, :branch), ref(pm, nw, :bus))

#         for arc in ref(pm, nw, :arcs)
#             l,i,j = arc
#             if !isinf(flow_lb[l])
#                 JuMP.set_lower_bound(p[arc], flow_lb[l])
#             end
#             if !isinf(flow_ub[l])
#                 JuMP.set_upper_bound(p[arc], flow_ub[l])
#             end
#         end
#     end

#     for (l,branch) in ref(pm, nw, :branch)
#         if haskey(branch, "pf_start")
#             f_idx = (l, branch["f_bus"], branch["t_bus"])
#             JuMP.set_start_value(p[f_idx], branch["pf_start"])
#         end
#         if haskey(branch, "pt_start")
#             t_idx = (l, branch["t_bus"], branch["f_bus"])
#             JuMP.set_start_value(p[t_idx], branch["pt_start"])
#         end
#     end

# end

# ""
# function var_branch_power_imaginary(pm::AbstractACPowerModel; nw::Int=0, bounded::Bool=true)
    
#     #@variable(pm.model, q[(l,i,j) in pm.ref[:arcs]])
#     q = var(pm, nw)[:q] = JuMP.@variable(pm.model, [(l,i,j) in ref(pm, nw, :arcs)], base_name="$(nw)_q", start = comp_start_value(ref(pm, nw, :branch, l), "q_start"))

#     if bounded
#         flow_lb, flow_ub = ref_calc_branch_flow_bounds(ref(pm, nw, :branch), ref(pm, nw, :bus))

#         for arc in ref(pm, nw, :arcs)
#             l,i,j = arc
#             if !isinf(flow_lb[l])
#                 JuMP.set_lower_bound(q[arc], flow_lb[l])
#             end
#             if !isinf(flow_ub[l])
#                 JuMP.set_upper_bound(q[arc], flow_ub[l])
#             end
#         end
#     end

#     for (l,branch) in ref(pm, nw, :branch)
#         if haskey(branch, "qf_start")
#             f_idx = (l, branch["f_bus"], branch["t_bus"])
#             JuMP.set_start_value(q[f_idx], branch["qf_start"])
#         end
#         if haskey(branch, "qt_start")
#             t_idx = (l, branch["t_bus"], branch["f_bus"])
#             JuMP.set_start_value(q[t_idx], branch["qt_start"])
#         end
#     end

# end

""
function var_dcline_power(pm::AbstractPowerModel; kwargs...)
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

    #sol_component_value_edge(pm, nw, :dcline, :pf, :pt, ref(pm, nw, :arcs_from_dc), ref(pm, nw, :arcs_to_dc), p_dc)
 
end

"DC models ignore reactive power flows"
function var_dcline_power_imaginary(pm::AbstractDCPowerModel; nw::Int=0, kwargs...)
    #sol_component_fixed(pm, nw, :dcline, :qf, ids(pm, nw, :dcline), NaN)
    #sol_component_fixed(pm, nw, :dcline, :qt, ids(pm, nw, :dcline), NaN)
end

"variable: `q_dc[l,i,j]` for `(l,i,j)` in `arcs_dc`"
function var_dcline_power_imaginary(pm::AbstractACPowerModel; nw::Int=0, bounded::Bool=true)

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
    #sol_component_value_edge(pm, nw, :dcline, :qf, :qt, ref(pm, nw, :arcs_from_dc), ref(pm, nw, :arcs_to_dc), q_dc)
end

# "variables for modeling storage units, includes grid injection and internal variables, with mixed int variables for charge/discharge"
# function variable_storage_power_mi(pm::AbstractDCPowerModel; kwargs...)
#     PowerModels.variable_storage_power_real(pm; kwargs...)
#     PowerModels.variable_storage_power_imaginary(pm; kwargs...)
#     PowerModels.variable_storage_power_control_imaginary(pm; kwargs...)
#     PowerModels.variable_storage_current(pm; kwargs...)
#     PowerModels.variable_storage_energy(pm; kwargs...)
#     PowerModels.variable_storage_charge(pm; kwargs...)
#     PowerModels.variable_storage_discharge(pm; kwargs...)
#     PowerModels.variable_storage_complementary_indicator(pm; kwargs...)
# end

"""
Defines load curtailment variables p to represent the active power flow for each branch
"""
function var_load_curtailment(pm::AbstractPowerModel; kwargs...)
    var_load_curtailment_real(pm; kwargs...)
    var_load_curtailment_imaginary(pm; kwargs...)
end

function var_load_curtailment_real(pm::AbstractPowerModel; nw::Int=0)

    p_lc = var(pm, nw)[:p_lc] = JuMP.@variable(pm.model, [i in ids(pm, nw, :load)], base_name="$(nw)_p_lc")

    for (l,load) in ref(pm, nw, :load)
        JuMP.set_upper_bound(p_lc[l],load["pd"])
        JuMP.set_lower_bound(p_lc[l],0.0)
    end

    sol_component_value(pm, nw, :load_curtailment, :p_lc, ids(pm, nw, :load), p_lc)
end

"""
Defines load curtailment variables q to represent the active power flow for each branch
"""
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel; nw::Int=0)
    #sol_component_fixed(pm, nw, :load_curtailment, :q_lc, ids(pm, nw, :load), NaN)
end

""
function var_load_curtailment_imaginary(pm::AbstractACPowerModel; nw::Int=0)
    
    q_lc = var(pm, nw)[:q_lc] = JuMP.@variable(pm.model, [i in ids(pm, nw, :load)], base_name="$(nw)_q_lc")

    for (l,load) in ref(pm, nw, :load)
        JuMP.set_upper_bound(q_lc[l],load["qd"])
        JuMP.set_lower_bound(q_lc[l],0.0)
    end
    #sol_component_fixed(pm, nw, :load_curtailment, :q_lc, ids(pm, nw, :load), NaN)
end

""
function var_load_power_factor_range(pm::AbstractDCPowerModel; nw::Int=0)

    z_demand = var(pm, nw)[:z_demand] = JuMP.@variable(pm.model, [i in ids(pm, nw, :load)], base_name="$(nw)_z_demand")

    for (l,load) in ref(pm, nw, :load)
        JuMP.set_lower_bound(z_demand[l], -Float32(load["qd"]/load["pd"]))
        JuMP.set_upper_bound(z_demand[l], Float32(load["qd"]/load["pd"]))
    end

    #sol_component_value(pm, nw, :load, :z_demand, ids(pm, nw, :load), z_demand)
end

function var_buspair_current_magnitude_sqr(pm::AbstractDCPowerModel; nw::Int=0, bounded::Bool=true)
    
    branch = ref(pm, nw, :branch)
    ccm = var(pm, nw)[:ccm] = JuMP.@variable(pm.model, [i in ids(pm, nw, :branch)], base_name="$(nw)_ccm", start = comp_start_value(branch[i], "ccm_start"))

    if bounded
        bus = ref(pm, nw, :bus)
        for (i, b) in branch
            rate_a = Inf
            if haskey(b, "rate_a")
                rate_a = b["rate_a"]
            end
            ub = ((rate_a*b["tap"])/(bus[b["f_bus"]]["vmin"]))^2

            JuMP.set_lower_bound(ccm[i], 0.0)
            if !isinf(ub)
                JuMP.set_upper_bound(ccm[i], ub)
            end
        end
    end

    #sol_component_value(pm, nw, :branch, :ccm, ids(pm, nw, :branch), ccm)

end

""
function var_bus_voltage_magnitude_sqr(pm::AbstractDCPowerModel; nw::Int=0, bounded::Bool=true)
    
    w = var(pm, nw)[:w] = JuMP.@variable(pm.model, [i in ids(pm, nw, :bus)], base_name="$(nw)_w",start=1.001)

    if bounded
        for (i, bus) in ref(pm, nw, :bus)
            JuMP.set_lower_bound(w[i], bus["vmin"]^2)
            JuMP.set_upper_bound(w[i], bus["vmax"]^2)
        end
    end

    #sol_component_value(pm, nw, :bus, :w, ids(pm, nw, :bus), w)
end

""
function var_buspair_voltage_product(pm::AbstractDCPowerModel; nw::Int=0, bounded::Bool=true)

    wr = var(pm, nw)[:wr] = JuMP.@variable(pm.model, [bp in ids(pm, nw, :buspairs)], base_name="$(nw)_wr", start = comp_start_value(ref(pm, nw, :buspairs, bp), "wr_start", 1.0))
    wi = var(pm, nw)[:wi] = JuMP.@variable(pm.model, [bp in ids(pm, nw, :buspairs)], base_name="$(nw)_wi", start = comp_start_value(ref(pm, nw, :buspairs, bp), "wi_start"))

    if bounded
        wr_min, wr_max, wi_min, wi_max = calc_voltage_product_bounds(ref(pm, nw, :buspairs))

        for bp in ids(pm, nw, :buspairs)
            JuMP.set_lower_bound(wr[bp], wr_min[bp])
            JuMP.set_upper_bound(wr[bp], wr_max[bp])

            JuMP.set_lower_bound(wi[bp], wi_min[bp])
            JuMP.set_upper_bound(wi[bp], wi_max[bp])
        end
    end

    #sol_component_value_buspair(pm, nw, :buspairs, :wr, ids(pm, nw, :buspairs), wr)
    #sol_component_value_buspair(pm, nw, :buspairs, :wi, ids(pm, nw, :buspairs), wi)

end

""
function sol_component_value(pm::AbstractPowerModel, n::Int, comp_name::Symbol, field_name::Symbol, comp_ids, variables)
    for i in comp_ids
        @assert !haskey(sol(pm, n, comp_name, i), field_name)
        sol(pm, n, comp_name, i)[field_name] = variables[i]
    end
end

"given a constant value, builds the standard component-wise solution structure"
function sol_component_fixed(pm::AbstractPowerModel, n::Int, comp_name::Symbol, field_name::Symbol, comp_ids, constant)
    for i in comp_ids
        @assert !haskey(sol(pm, n, comp_name, i), field_name)
        sol(pm, n, comp_name, i)[field_name] = constant
    end
end

"maps asymmetric edge variables into components"
function sol_component_value_edge(pm::AbstractPowerModel, n::Int, comp_name::Symbol, field_name_fr::Symbol, field_name_to::Symbol, comp_ids_fr, comp_ids_to, variables)
    for (l, i, j) in comp_ids_fr
        @assert !haskey(sol(pm, n, comp_name, l), field_name_fr)
        sol(pm, n, comp_name, l)[field_name_fr] = variables[(l, i, j)]
    end

    for (l, i, j) in comp_ids_to
        @assert !haskey(sol(pm, n, comp_name, l), field_name_to)
        sol(pm, n, comp_name, l)[field_name_to] = variables[(l, i, j)]
    end
end

"map sparse buspair variables into components"
function sol_component_value_buspair(pm::AbstractPowerModel, n::Int, comp_name::Symbol, field_name::Symbol, variable_ids, variables)
    for bp in variable_ids
        buspair = ref(pm, n, comp_name, bp)
        l = buspair["branch"]
        @assert !haskey(sol(pm, n, :branch, l), field_name)
        sol(pm, n, :branch, l)[field_name] = variables[bp]
    end
end
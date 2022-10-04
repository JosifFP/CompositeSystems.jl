
""
function comp_start_value(comp::Dict{String,<:Any}, key::String, default=0.0)
    return get(comp, key, default)
end

""
function var_bus_voltage(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_bus_voltage_angle(pm, system; kwargs...)
    var_bus_voltage_magnitude(pm, system; kwargs...)
end

""
function var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel; bounded::Bool=true)

    JuMP.@variable(pm.model, va[i in field(system, Buses, :keys); field(system, Buses, :bus_type)[i] ≠ 4])
    #va = var(pm)[:va] = JuMP.@variable(pm.model, [i in ids(pm, :bus)], base_name="va", start = comp_start_value(ref(pm, :bus, i), "va_start"))
    #sol_component_value(pm, :bus, :va, ids(pm, :bus), va)
end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; bounded::Bool=true)
    #sol_component_fixed(pm, :bus, :vm, ids(pm, :bus), 1.0)
end

"variable: `v[i]` for `i` in `bus`es"
function var_bus_voltage_magnitude(pm::AbstractACPowerModel, system::SystemModel; bounded::Bool=true)

    JuMP.@variable(pm.model, vm[i in field(system, Buses, :keys); field(system, Buses, :bus_type)[i] ≠ 4], start =1.0)
    #vm = var(pm)[:vm] = JuMP.@variable(pm.model, [i in ids(pm, :bus)], base_name="vm", start = comp_start_value(ref(pm, :bus, i), "vm_start", 1.0))
    if bounded
        for (i, bus) in field(system, Buses, :keys)
            JuMP.set_lower_bound(vm[i], field(system, Buses, :vmin))
            JuMP.set_upper_bound(vm[i], field(system, Buses, :vmax))
        end
    end
    #sol_component_value(pm, :bus, :vm, ids(pm, :bus), vm)
end

""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel, t::Int; kwargs...)
    var_gen_power_real(pm, system, t; kwargs...)
    var_gen_power_imaginary(pm, system, t; kwargs...)
end

""
function var_gen_power_real(pm::AbstractPowerModel, system::SystemModel, t::Int; bounded::Bool=true)

    JuMP.@variable(pm.model, pg[i in field(system, Generators, :keys); field(system, Generators, :status)[i] ≠ 0])
    #pg = var(pm)[:pg] = JuMP.@variable(pm.model, [i in ids(pm, :gen)], base_name="pg", start = comp_start_value(ref(pm, :gen, i), "pg_start"))    

    if bounded
        for i in field(system, Generators, :keys)
            if field(system, Generators, :status)[i] ≠ 0
                JuMP.set_upper_bound(pg[i], field(system, Generators, :pmax)[i])
                JuMP.set_lower_bound(pg[i], 0.0)
                # if gen["pmin"]>=0.0
                #     JuMP.set_lower_bound(pg[i], gen["pmin"])
                # else
                #     JuMP.set_lower_bound(pg[i], 0.0)
                # end
            end
        end
    end
    #sol_component_value(pm, :gen, :pg, ids(pm, :gen), pg)
end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, t::Int; kwargs...)
    #sol_component_fixed(pm, :gen, :qg, ids(pm, :gen), NaN)
end

""
function var_gen_power_imaginary(pm::AbstractACPowerModel, system::SystemModel, t::Int; bounded::Bool=true)

    JuMP.@variable(pm.model, qg[i in field(system, Generators, :keys); field(system, Generators, :status)[i] ≠ 0])
    #qg = var(pm)[:qg] = JuMP.@variable(pm.model, [i in ids(pm, :gen)], base_name="qg", start = comp_start_value(ref(pm, :gen, i), "qg_start"))

    if bounded
        for i in field(system, Generators, :keys)
            if field(system, Generators, :status)[i] ≠ 0
                JuMP.set_lower_bound(qg[i], field(system, Generators, :qmin)[i])
                JuMP.set_upper_bound(qg[i], field(system, Generators, :qmax)[i])
            end
        end
    end
    #sol_component_fixed(pm, :gen, :qg, ids(pm, :gen), qg)
end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function var_branch_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_branch_power_real(pm, system; kwargs...)
    var_branch_power_imaginary(pm, system; kwargs...)
end

""
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel; bounded::Bool=true)

    JuMP.@variable(pm.model, p[(l,i,j) in field(system, Topology, :arcs); field(system, Branches, :status)[l] ≠ 0])
    #p = var(pm)[:p] = JuMP.@variable(pm.model, [(l,i,j) in ref(pm, :arcs)], base_name="p", start = comp_start_value(ref(pm, :branch, l), "p_start"))

    if bounded

        flow_lb, flow_ub = ref_calc_branch_flow_bounds(field(system, :branches))

        tmp_arcs = [(l,i,j) for (l,i,j) in field(system, Topology, :arcs) if field(system, Branches, :status)[l] ≠ 0]

        for arc in tmp_arcs
            l,i,j = arc
            if !isinf(flow_lb[l])
                JuMP.set_lower_bound(p[arc], flow_lb[l])
            end
            if !isinf(flow_ub[l])
                JuMP.set_upper_bound(p[arc], flow_ub[l])
            end
        end
    end

    for l in field(system, Branches, :keys)
        if hasfield(Branches, :pf_start)
            f_idx = (l, field(system, Branches, :f_bus)[l], field(system, Branches, :t_bus)[l])
            JuMP.set_start_value(p[f_idx], field(system, Branches, :pf_start)[l])
        end
    end

    # this explicit type erasure is necessary
    tmp_arcs_from = [(l,i,j) for (l,i,j) in field(system, Topology, :arcs_from) if field(system, Branches, :status)[l] ≠ 0]
    p_expr = Dict{Any,Any}( ((l,i,j), p[(l,i,j)]) for (l,i,j) in tmp_arcs_from )
    p_expr = merge(p_expr, Dict( ((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in tmp_arcs_from))
    #var(pm)[:p] = p_expr 
    pm.model[:p] = p_expr 
    #sol_component_value_edge(pm, :branch, :pf, :pt, ref(pm, :arcs_from), ref(pm, :arcs_to), p_expr)

end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; kwargs...)
    #sol_component_fixed(pm, :branch, :qf, ids(pm, :branch), NaN)
    #sol_component_fixed(pm, :branch, :qt, ids(pm, :branch), NaN)
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; kwargs...)
    var_load_curtailment_real(pm, system, t; kwargs...)
    var_load_curtailment_imaginary(pm, system; kwargs...)
end

function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, t::Int)

    JuMP.@variable(pm.model, p_lc[i in field(system, Loads, :keys); field(system, Loads, :status)[i] ≠ 0], base_name="p_lc")

    for l in field(system, Loads, :keys)
        JuMP.set_upper_bound(p_lc[l], field(system, Loads, :pd)[l,t])
        JuMP.set_lower_bound(p_lc[l],0.0)
    end

    sol_component_value(pm, :load_curtailment, :p_lc, field(system, Loads, :keys) , pm.model[:p_lc])
end

"Defines load curtailment variables q to represent the active power flow for each branch"
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel)
    #sol_component_fixed(pm, :load_curtailment, :q_lc, ids(pm, :load), NaN)
end

""
function var_load_curtailment_imaginary(pm::AbstractACPowerModel, system::SystemModel)
    
    JuMP.@variable(pm.model, q_lc[i in field(system, Loads, :keys); field(system, Loads, :status)[i] ≠ 0], base_name="q_lc")

    for l in field(system, Loads, :keys)
        JuMP.set_upper_bound(q_lc[l], field(system, Loads, :qd)[l])
        JuMP.set_lower_bound(q_lc[l],0.0)
    end
    #sol_component_fixed(pm, :load_curtailment, :q_lc, ids(pm, :load), NaN)
end

""
function sol_component_value(pm::AbstractPowerModel, comp_name::Symbol, field_name::Symbol, comp_ids, variables)
    for i in comp_ids
        @assert !haskey(sol(pm, comp_name, i), field_name)
        sol(pm, comp_name, i)[field_name] = variables[i]
    end
end

"given a constant value, builds the standard component-wise solution structure"
function sol_component_fixed(pm::AbstractPowerModel, comp_name::Symbol, field_name::Symbol, comp_ids, constant)
    for i in comp_ids
        @assert !haskey(sol(pm, comp_name, i), field_name)
        sol(pm, comp_name, i)[field_name] = constant
    end
end

"maps asymmetric edge variables into components"
function sol_component_value_edge(pm::AbstractPowerModel, comp_name::Symbol, field_name_fr::Symbol, field_name_to::Symbol, comp_ids_fr, comp_ids_to, variables)
    for (l, i, j) in comp_ids_fr
        @assert !haskey(sol(pm, comp_name, l), field_name_fr)
        sol(pm, comp_name, l)[field_name_fr] = variables[(l, i, j)]
    end

    for (l, i, j) in comp_ids_to
        @assert !haskey(sol(pm, comp_name, l), field_name_to)
        sol(pm, comp_name, l)[field_name_to] = variables[(l, i, j)]
    end
end

# ""
# function var_branch_power_real(pm::AbstractACPowerModel; bounded::Bool=true)

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
# function var_branch_power_imaginary(pm::AbstractACPowerModel; bounded::Bool=true)
    
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

# ""
# function var_dcline_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
#     var_dcline_power_real(pm, system::SystemModel; kwargs...)
#     var_dcline_power_imaginary(pm, system::SystemModel; kwargs...)
# end

# "variable: `p_dc[l,i,j]` for `(l,i,j)` in `arcs_dc`"
# function var_dcline_power_real(pm::AbstractPowerModel, system::SystemModel; bounded::Bool=true)

#     p_dc = JuMP.@variable(pm.model, [(l,i,j) in field(system, Topology, :arcs_dc); field(system, Shunts, :status)[l] ≠ 0])
#     #p_dc = var(pm)[:p_dc] = JuMP.@variable(pm.model, [arc in ref(pm, :arcs_dc)], base_name="p_dc")

#     if bounded
#         for (l,dcline) in ref(pm, :dcline)
#             f_idx = (l, dcline["f_bus"], dcline["t_bus"])
#             t_idx = (l, dcline["t_bus"], dcline["f_bus"])

#             JuMP.set_lower_bound(p_dc[f_idx], dcline["pminf"])
#             JuMP.set_upper_bound(p_dc[f_idx], dcline["pmaxf"])

#             JuMP.set_lower_bound(p_dc[t_idx], dcline["pmint"])
#             JuMP.set_upper_bound(p_dc[t_idx], dcline["pmaxt"])
#         end
#     end

#     for (l,dcline) in ref(pm, :dcline)
#         if haskey(dcline, "pf")
#             f_idx = (l, dcline["f_bus"], dcline["t_bus"])
#             JuMP.set_start_value(p_dc[f_idx], dcline["pf"])
#         end

#         if haskey(dcline, "pt")
#             t_idx = (l, dcline["t_bus"], dcline["f_bus"])
#             JuMP.set_start_value(p_dc[t_idx], dcline["pt"])
#         end
#     end

#     #sol_component_value_edge(pm, :dcline, :pf, :pt, ref(pm, :arcs_from_dc), ref(pm, :arcs_to_dc), p_dc)
 
# end

# "DC models ignore reactive power flows"
# function var_dcline_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; kwargs...)
#     #sol_component_fixed(pm, :dcline, :qf, ids(pm, :dcline), NaN)
#     #sol_component_fixed(pm, :dcline, :qt, ids(pm, :dcline), NaN)
# end


# "variable: `q_dc[l,i,j]` for `(l,i,j)` in `arcs_dc`"
# function var_dcline_power_imaginary(pm::AbstractACPowerModel, system::SystemModel; bounded::Bool=true)

#     q_dc = var(pm)[:q_dc] = JuMP.@variable(pm.model, [arc in ref(pm, :arcs_dc)])
#     #q_dc = var(pm)[:q_dc] = JuMP.@variable(pm.model, [arc in ref(pm, :arcs_dc)], base_name="q_dc")

#     if bounded
#         for (l,dcline) in ref(pm, :dcline)
#             f_idx = (l, dcline["f_bus"], dcline["t_bus"])
#             t_idx = (l, dcline["t_bus"], dcline["f_bus"])

#             JuMP.set_lower_bound(q_dc[f_idx], dcline["qminf"])
#             JuMP.set_upper_bound(q_dc[f_idx], dcline["qmaxf"])

#             JuMP.set_lower_bound(q_dc[t_idx], dcline["qmint"])
#             JuMP.set_upper_bound(q_dc[t_idx], dcline["qmaxt"])
#         end
#     end

#     for (l,dcline) in ref(pm, :dcline)
#         if haskey(dcline, "qf")
#             f_idx = (l, dcline["f_bus"], dcline["t_bus"])
#             JuMP.set_start_value(q_dc[f_idx], dcline["qf"])
#         end

#         if haskey(dcline, "qt")
#             t_idx = (l, dcline["t_bus"], dcline["f_bus"])
#             JuMP.set_start_value(q_dc[t_idx], dcline["qt"])
#         end
#     end
#     #sol_component_value_edge(pm, :dcline, :qf, :qt, ref(pm, :arcs_from_dc), ref(pm, :arcs_to_dc), q_dc)
# end

""
function var_load_power_factor_range(pm::AbstractDCPowerModel)

    z_demand = var(pm)[:z_demand] = JuMP.@variable(pm.model, [i in ids(pm, :load)])
    #z_demand = var(pm)[:z_demand] = JuMP.@variable(pm.model, [i in ids(pm, :load)], base_name="z_demand")

    for (l,load) in ref(pm, :load)
        JuMP.set_lower_bound(z_demand[l], -Float32(load["qd"]/load["pd"]))
        JuMP.set_upper_bound(z_demand[l], Float32(load["qd"]/load["pd"]))
    end

    #sol_component_value(pm, :load, :z_demand, ids(pm, :load), z_demand)
end

function var_buspair_current_magnitude_sqr(pm::AbstractDCPowerModel; bounded::Bool=true)
    
    branch = ref(pm, :branch)
    ccm = var(pm)[:ccm] = JuMP.@variable(pm.model, [i in ids(pm, :branch)])
    #ccm = var(pm)[:ccm] = JuMP.@variable(pm.model, [i in ids(pm, :branch)], base_name="ccm", start = comp_start_value(branch[i], "ccm_start"))

    if bounded
        bus = ref(pm, :bus)
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

    #sol_component_value(pm, :branch, :ccm, ids(pm, :branch), ccm)

end

""
function var_bus_voltage_magnitude_sqr(pm::AbstractDCPowerModel; bounded::Bool=true)
    
    w = var(pm)[:w] = JuMP.@variable(pm.model, [i in ids(pm, :bus)], start=1.001)
    #w = var(pm)[:w] = JuMP.@variable(pm.model, [i in ids(pm, :bus)], base_name="w", start=1.001)

    if bounded
        for (i, bus) in ref(pm, :bus)
            JuMP.set_lower_bound(w[i], bus["vmin"]^2)
            JuMP.set_upper_bound(w[i], bus["vmax"]^2)
        end
    end

    #sol_component_value(pm, :bus, :w, ids(pm, :bus), w)
end

""
function var_buspair_voltage_product(pm::AbstractDCPowerModel; bounded::Bool=true)

    wr = var(pm)[:wr] = JuMP.@variable(pm.model, [bp in ids(pm, :buspairs)], start =  1.0)
    wi = var(pm)[:wi] = JuMP.@variable(pm.model, [bp in ids(pm, :buspairs)])
    #wr = var(pm)[:wr] = JuMP.@variable(pm.model, [bp in ids(pm, :buspairs)], base_name="wr", start = comp_start_value(ref(pm, :buspairs, bp), "wr_start", 1.0))
    #wi = var(pm)[:wi] = JuMP.@variable(pm.model, [bp in ids(pm, :buspairs)], base_name="wi", start = comp_start_value(ref(pm, :buspairs, bp), "wi_start"))

    if bounded
        wr_min, wr_max, wi_min, wi_max = calc_voltage_product_bounds(ref(pm, :buspairs))

        for bp in ids(pm, :buspairs)
            JuMP.set_lower_bound(wr[bp], wr_min[bp])
            JuMP.set_upper_bound(wr[bp], wr_max[bp])

            JuMP.set_lower_bound(wi[bp], wi_min[bp])
            JuMP.set_upper_bound(wi[bp], wi_max[bp])
        end
    end

    #sol_component_value_buspair(pm, :buspairs, :wr, ids(pm, :buspairs), wr)
    #sol_component_value_buspair(pm, :buspairs, :wi, ids(pm, :buspairs), wi)
end

"map sparse buspair variables into components"
function sol_component_value_buspair(pm::AbstractPowerModel, comp_name::Symbol, field_name::Symbol, variable_ids, variables)
    for bp in variable_ids
        buspair = ref(pm, comp_name, bp)
        l = buspair["branch"]
        @assert !haskey(sol(pm, :branch, l), field_name)
        sol(pm, :branch, l)[field_name] = variables[bp]
    end
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

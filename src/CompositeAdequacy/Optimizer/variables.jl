""
function comp_start_value(comp::Dict{String,<:Any}, key::String, default=0.0)
    return get(comp, key, default)
end

""
function var_bus_voltage(pm::AbstractPowerModel, system::SystemModel, t::Int; kwargs...)
    var_bus_voltage_angle(pm, system, t::Int; kwargs...)
    var_bus_voltage_magnitude(pm, system, t::Int; kwargs...)
end

""
function var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)

    field(pm, CompositeAdequacy.Topology, :buspairs)
    JuMP.@variable(pm.model, va[i in assetgrouplist(field(pm, Topology, :buses_idxs))])
    #va = var(pm)[:va] = JuMP.@variable(pm.model, [i in ids(pm, :bus)], base_name="va", start = comp_start_value(ref(pm, :bus, i), "va_start"))
    #report && sol_component_value(pm, :bus, :va, field(system, Buses, :keys), pm.model[:va])
end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)
    #sol_component_fixed(pm, :bus, :vm, ids(pm, :bus), 1.0)
end

"variable: `v[i]` for `i` in `bus`es"
function var_bus_voltage_magnitude(pm::AbstractACPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)

    JuMP.@variable(pm.model, vm[i in assetgrouplist(field(pm, Topology, :buses_idxs))], start =1.0)
    #vm = var(pm)[:vm] = JuMP.@variable(pm.model, [i in ids(pm, :bus)], base_name="vm", start = comp_start_value(ref(pm, :bus, i), "vm_start", 1.0))
    if bounded
        for i in assetgrouplist(field(pm, Topology, :buses_idxs))
            JuMP.set_lower_bound(vm[i], field(system, Buses, :vmin)[i])
            JuMP.set_upper_bound(vm[i], field(system, Buses, :vmax)[i])
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

    JuMP.@variable(pm.model, pg[i in assetgrouplist(field(pm, Topology, :generators_idxs))])
    #JuMP.@variable(pm.model, pg[i in [i for i in field(system, Generators, :keys) if field(system, Generators, :status)[i] ≠ 0]])
    #JuMP.@variable(pm.model, qg[i in field(system, Generators, :keys); field(system, Generators, :status)[i] ≠ 0])

    if bounded
        for l in assetgrouplist(field(pm, Topology, :generators_idxs))
            JuMP.set_upper_bound(pg[l], field(system, Generators, :pmax)[l])
            JuMP.set_lower_bound(pg[l], 0.0)
        end
    end
    #report && sol_component_value(pm, :gen, :pg, field(system, Generators, :keys), pm.model[:pg])
end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)
    #sol_component_fixed(pm, :gen, :qg, ids(pm, :gen), NaN)
end

""
function var_gen_power_imaginary(pm::AbstractACPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)

    JuMP.@variable(pm.model, qg[i in assetgrouplist(field(pm, Topology, :buses_idxs))])
    #qg = var(pm)[:qg] = JuMP.@variable(pm.model, [i in ids(pm, :gen)], base_name="qg", start = comp_start_value(ref(pm, :gen, i), "qg_start"))

    if bounded
        for l in assetgrouplist(field(pm, Topology, :generators_idxs))
            JuMP.set_upper_bound(qg[l], field(system, Generators, :pmax)[l])
            JuMP.set_lower_bound(qg[l], 0.0)
        end
    end
    #sol_component_fixed(pm, :gen, :qg, ids(pm, :gen), qg)
end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function var_branch_power(pm::AbstractPowerModel, system::SystemModel, t::Int; kwargs...)
    var_branch_power_real(pm, system, t; kwargs...)
    var_branch_power_imaginary(pm, system, t; kwargs...)
end

""
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)

    JuMP.@variable(pm.model, p[(l,i,j) in field(system, :arcs); field(system, Branches, :status)[l] ≠ 0])
    #p = var(pm)[:p] = JuMP.@variable(pm.model, [(l,i,j) in ref(pm, :arcs)], base_name="p", start = comp_start_value(ref(pm, :branch, l), "p_start"))

    if bounded

        flow_lb, flow_ub = ref_calc_branch_flow_bounds(field(system, :branches))

        for (l,i,j) in field(system, :arcs)
            if field(system, Branches, :status)[l] ≠ 0
                l,i,j = arc
                if !isinf(flow_lb[l])
                    JuMP.set_lower_bound(p[(l,i,j)], flow_lb[l])
                end
                if !isinf(flow_ub[l])
                    JuMP.set_upper_bound(p[(l,i,j)], flow_ub[l])
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
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)
    #sol_component_fixed(pm, :branch, :qf, ids(pm, :branch), NaN)
    #sol_component_fixed(pm, :branch, :qt, ids(pm, :branch), NaN)
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; kwargs...)
    var_load_curtailment_real(pm, system, t; kwargs...)
    var_load_curtailment_imaginary(pm, system, t; kwargs...)
end

""
function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)

    JuMP.@variable(pm.model, plc[i in field(system, Loads, :keys); field(system, Loads, :status)[i] ≠ 0], base_name="plc")

    for l in field(system, Loads, :keys)
        if field(system, Loads, :status)[l] ≠ 0
            JuMP.set_upper_bound(plc[l], field(system, Loads, :pd)[l,t])
            JuMP.set_lower_bound(plc[l],0.0)
        end
    end

    sol_component_value(pm, :load_curtailment, :plc, field(system, Loads, :keys) , pm.model[:plc])
end

""
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)
end

""
function var_load_curtailment_imaginary(pm::AbstractACPowerModel, system::SystemModel, t::Int; bounded::Bool=true, report::Bool=false)
    
    JuMP.@variable(pm.model, qlc[i in field(system, Loads, :keys); field(system, Loads, :status)[i] ≠ 0], base_name="qlc")

    for l in field(system, Loads, :keys)
        JuMP.set_upper_bound(qlc[l], field(system, Loads, :qd)[l])
        JuMP.set_lower_bound(qlc[l],0.0)
    end

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

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
function var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)

    var(pm, :va)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :buses_idxs))])

end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)
end

"variable: `v[i]` for `i` in `bus`es"
function var_bus_voltage_magnitude(pm::AbstractACPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)

    vm = var(pm, :vm)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :buses_idxs))], start =1.0)
   
    if bounded
        for i in assetgrouplist(topology(pm, :buses_idxs))
            set_lower_bound(vm[i], field(system, :buses, :vmin)[i])
            set_upper_bound(vm[i], field(system, :buses, :vmax)[i])
        end
    end

end


""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_gen_power_real(pm, system; kwargs...)
    var_gen_power_imaginary(pm, system; kwargs...)
end

""
function var_gen_power_real(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)
    
    pg = var(pm, :pg)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :generators_idxs))])

    if bounded
        for l in assetgrouplist(topology(pm, :generators_idxs))
            set_upper_bound(pg[l], field(system, :generators, :pmax)[l])
            set_lower_bound(pg[l], 0.0)
        end
    end

end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)
end

""
function var_gen_power_imaginary(pm::AbstractACPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)

    qg = var(pm, :qg)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :generators_idxs))])
  
    if bounded
        for l in assetgrouplist(topology(pm, :generators_idxs))
            set_upper_bound(qg[l], field(system, :generators, :qmax)[l])
            set_lower_bound(qg[l], 0.0)
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
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)

    arcs_from = filter(!ismissing, skipmissing(topology(pm, :arcs, :arcs_from)))
    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs, :arcs)))
    p = @variable(pm.model, [arcs])
    #p = var(pm)[:p] = @variable(pm.model, [(l,i,j) in ref(pm, :arcs)], base_name="p", start = comp_start_value(ref(pm, :branch, l), "p_start"))

    if bounded
        for (l,i,j) in arcs
            set_lower_bound(p[(l,i,j)], max(-Inf, -field(system, :branches, :rate_a)[l]))
            set_upper_bound(p[(l,i,j)], min(Inf,  field(system, :branches, :rate_a)[l]))
        end
    end

    # this explicit type erasure is necessary
    var(pm, :p)[nw] = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in arcs_from), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in arcs_from))
    #sol_component_value_edge(pm, :branch, :pf, :pt, ref(pm, :arcs_from), ref(pm, :arcs_to), p_expr)
end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_load_curtailment_real(pm, system; kwargs...)
    var_load_curtailment_imaginary(pm, system; kwargs...)
end

""
function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)

    plc = var(pm, :plc)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :loads_idxs))], start =0.0)

    for l in assetgrouplist(topology(pm, :loads_idxs))
        set_upper_bound(plc[l], field(system, :loads, :pd)[l,nw])
        set_lower_bound(plc[l],0.0)
    end
    #report && sol_component_value(pm, :plc, assetgrouplist(topology(pm, :loads_idxs)), plc)
end

""
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)
end

""
function var_load_curtailment_imaginary(pm::AbstractACPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, report::Bool=false)
    
    qlc = var(pm, :qlc)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :loads_idxs))], start =0.0)

    for l in assetgrouplist(topology(pm, :loads_idxs))
        set_upper_bound(qlc[l], field(system, :loads, :qd)[l])
        set_lower_bound(qlc[l],0.0)
    end

end

# ""
# function sol_component_value(pm::AbstractPowerModel, field_name::Symbol, comp_ids, variables)
#     for i in comp_ids
#         @assert !haskey(sol(pm, field_name), i)
#         sol(pm, field_name)[i] = variables[i]
#     end
# end

# "given a constant value, builds the standard component-wise solution structure"
# function sol_component_fixed(pm::AbstractPowerModel, field_name::Symbol, comp_ids, constant)
#     for i in comp_ids
#         @assert !haskey(sol(pm, field_name), i)
#         sol(pm, field_name)[i] = constant
#     end
# end


# "maps asymmetric edge variables into components"
# function sol_component_value_edge(pm::AbstractPowerModel, comp_name::Symbol, field_name_fr::Symbol, field_name_to::Symbol, comp_ids_fr, comp_ids_to, variables)
#     for (l, i, j) in comp_ids_fr
#         @assert !haskey(sol(pm, comp_name, l), field_name_fr)
#         sol(pm, comp_name, l)[field_name_fr] = variables[(l, i, j)]
#     end

#     for (l, i, j) in comp_ids_to
#         @assert !haskey(sol(pm, comp_name, l), field_name_to)
#         sol(pm, comp_name, l)[field_name_to] = variables[(l, i, j)]
#     end
# end

# "map sparse buspair variables into components"
# function sol_component_value_buspair(pm::AbstractPowerModel, comp_name::Symbol, field_name::Symbol, variable_ids, variables)
#     for bp in variable_ids
#         buspair = ref(pm, comp_name, bp)
#         l = buspair["branch"]
#         @assert !haskey(sol(pm, :branch, l), field_name)
#         sol(pm, :branch, l)[field_name] = variables[bp]
#     end
# end

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

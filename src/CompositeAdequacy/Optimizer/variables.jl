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
function var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)

    var(pm, :va)[nw] = @variable(pm.model, [assetgrouplist(field(pm, Topology, :buses_idxs))])
    #var(pm)[:va] = @variable(pm.model, [i in field(system, Buses, :keys);  field(system, Buses, :bus_type)[i] != 4], container = Array)
    #va = var(pm)[:va] = @variable(pm.model, [i in ids(pm, :bus)], base_name="va", start = comp_start_value(ref(pm, :bus, i), "va_start"))

end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)
end

"variable: `v[i]` for `i` in `bus`es"
function var_bus_voltage_magnitude(pm::AbstractACPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)

    var(pm, :vm)[nw] = @variable(pm.model, [assetgrouplist(field(pm, Topology, :buses_idxs))], start =1.0)
    #vm = var(pm)[:vm] = @variable(pm.model, [i in ids(pm, :bus)], base_name="vm", start = comp_start_value(ref(pm, :bus, i), "vm_start", 1.0))
    if bounded
        for i in assetgrouplist(field(pm, Topology, :buses_idxs))
            set_lower_bound(var(pm, :vm, nw)[i], field(system, Buses, :vmin)[i])
            set_upper_bound(var(pm, :vm, nw)[i], field(system, Buses, :vmax)[i])
        end
    end

end

""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_gen_power_real(pm, system; kwargs...)
    var_gen_power_imaginary(pm, system; kwargs...)
end

""
function var_gen_power_real(pm::AbstractPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)
    
    var(pm, :pg)[nw] = @variable(pm.model, [assetgrouplist(field(pm, Topology, :generators_idxs))])
    #@variable(pm.model, qg[i in field(system, Generators, :keys); field(system, Generators, :status)[i] ≠ 0])

    if bounded
        for l in assetgrouplist(field(pm, Topology, :generators_idxs))
            set_upper_bound(var(pm, :pg, nw)[l], field(system, Generators, :pmax)[l])
            set_lower_bound(var(pm, :pg, nw)[l], 0.0)
        end
    end

end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)
end

""
function var_gen_power_imaginary(pm::AbstractACPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)

    var(pm, :qg)[nw] = @variable(pm.model, [assetgrouplist(field(pm, Topology, :generators_idxs))])
    #qg = var(pm)[:qg] = @variable(pm.model, [i in ids(pm, :gen)], base_name="qg", start = comp_start_value(ref(pm, :gen, i), "qg_start"))

    if bounded
        for l in assetgrouplist(field(pm, Topology, :generators_idxs))
            set_upper_bound(var(pm, :qg, t)[l], field(system, Generators, :qmax)[l])
            set_lower_bound(var(pm, :qg, t)[l], 0.0)
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
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)

    arcs_from = filter(!ismissing, skipmissing(field(pm.topology, :arcs, :arcs_from)))
    arcs = filter(!ismissing, skipmissing(field(pm.topology, :arcs, :arcs)))
    p = @variable(pm.model, [arcs])
    #p = var(pm)[:p] = @variable(pm.model, [(l,i,j) in ref(pm, :arcs)], base_name="p", start = comp_start_value(ref(pm, :branch, l), "p_start"))

    if bounded
        for (l,i,j) in arcs
            set_lower_bound(p[(l,i,j)], max(-Inf, -field(system, Branches, :rate_a)[l]))
            set_upper_bound(p[(l,i,j)], min(Inf,  field(system, Branches, :rate_a)[l]))
        end
    end

    # this explicit type erasure is necessary
    var(pm, :p)[nw] = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in arcs_from), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in arcs_from))
    #sol_component_value_edge(pm, :branch, :pf, :pt, ref(pm, :arcs_from), ref(pm, :arcs_to), p_expr)
end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; kwargs...)
    var_load_curtailment_real(pm, system, t; kwargs...)
    var_load_curtailment_imaginary(pm, system; kwargs...)
end

""
function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=0, bounded::Bool=true, report::Bool=false)

    var(pm, :plc)[nw] = @variable(pm.model, [assetgrouplist(field(pm, Topology, :loads_idxs))])

    for l in assetgrouplist(field(pm, Topology, :loads_idxs))
        set_upper_bound(var(pm, :plc, nw)[l], field(system, Loads, :pd)[l,t])
        set_lower_bound(var(pm, :plc, nw)[l],0.0)
    end
    #report && sol_component_value(pm, :plc, assetgrouplist(field(pm, Topology, :loads_idxs)), plc)
end

""
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)
end

""
function var_load_curtailment_imaginary(pm::AbstractACPowerModel, system::SystemModel; nw::Int=0, bounded::Bool=true, report::Bool=false)
    
    var(pm, :qlc)[nw] =@variable(pm.model, [assetgrouplist(field(pm, Topology, :loads_idxs))])

    for l in assetgrouplist(field(pm, Topology, :loads_idxs))
        set_upper_bound(var(pm, :qlc, nw)[l], field(system, Loads, :qd)[l])
        set_lower_bound(var(pm, :qlc, nw)[l],0.0)
    end

end

""
function sol_component_value(pm::AbstractPowerModel, field_name::Symbol, comp_ids, variables)
    for i in comp_ids
        @assert !haskey(sol(pm, field_name), i)
        sol(pm, field_name)[i] = variables[i]
    end
end

"given a constant value, builds the standard component-wise solution structure"
function sol_component_fixed(pm::AbstractPowerModel, field_name::Symbol, comp_ids, constant)
    for i in comp_ids
        @assert !haskey(sol(pm, field_name), i)
        sol(pm, field_name)[i] = constant
    end
end

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

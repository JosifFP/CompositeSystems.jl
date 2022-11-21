""
function var_bus_voltage(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_bus_voltage_angle(pm, system; kwargs...)
    var_bus_voltage_magnitude(pm, system; kwargs...)
end

""
function var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
    var(pm, :va)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :buses_idxs))])
    #var(pm, :va)[nw] = @variable(pm.model, [field(system, :buses, :keys)])
end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"variable: `v[i]` for `i` in `bus`es"
function var_bus_voltage_magnitude(pm::AbstractACPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    vm = var(pm, :vm)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :buses_idxs))], start =1.0)
    #vm = var(pm, :vm)[nw] = @variable(pm.model, [field(system, :buses, :keys)], start =1.0)

    if bounded
        #for i in field(system, :buses, :keys)
        for i in assetgrouplist(topology(pm, :buses_idxs))
            JuMP.set_lower_bound(vm[i], field(system, :buses, :vmin)[i])
            JuMP.set_upper_bound(vm[i], field(system, :buses, :vmax)[i])
        end
    end

end

""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_gen_power_real(pm, system; kwargs...)
    var_gen_power_imaginary(pm, system; kwargs...)
end

""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; kwargs...)
    var_gen_power_real(pm, system, states, t; kwargs...)
    var_gen_power_imaginary(pm, system, states, t; kwargs...)
end

""
function var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    pg = var(pm, :pg)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :generators_idxs))])

    if bounded
        for l in assetgrouplist(topology(pm, :generators_idxs))
            JuMP.set_upper_bound(pg[l], field(system, :generators, :pmax)[l])
            JuMP.set_lower_bound(pg[l], 0.0)
        end
    end

end

""
function var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)

    pg = var(pm, :pg)[nw] = @variable(pm.model, [field(system, :generators, :keys)])

    if bounded
        for l in field(system, :generators, :keys)
            JuMP.set_upper_bound(pg[l], field(system, :generators, :pmax)[l]*field(states, :generators)[l,t])
            JuMP.set_lower_bound(pg[l], 0.0)
        end
    end

end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)
end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function var_branch_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_branch_power_real(pm, system; kwargs...)
    var_branch_power_imaginary(pm, system; kwargs...)
end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function var_branch_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; kwargs...)
    var_branch_power_real(pm, system, states, t; kwargs...)
    var_branch_power_imaginary(pm, system, states, t; kwargs...)
end

""
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    #p = @variable(pm.model, [topology(pm, :arcs)])
    arcs_from = filter(!ismissing, skipmissing(topology(pm, :arcs_from)))
    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))
    p = @variable(pm.model, [arcs])

    if bounded
        for (l,i,j) in arcs
        #for (l,i,j) in topology(pm, :arcs)
            JuMP.set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l])
            JuMP.set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l])
        end
    end

    # this explicit type erasure is necessary
    var(pm, :p)[nw] = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in arcs_from), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in arcs_from)
        #Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from)), 
        #Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from))
    )

end

""
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)

    p = @variable(pm.model, [topology(pm, :arcs)])

    if bounded
        for (l,i,j) in  topology(pm, :arcs)
            JuMP.set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
            JuMP.set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
        end
    end

    # this explicit type erasure is necessary
    var(pm, :p)[nw] = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from)), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from))
    )

end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; kwargs...)
    var_load_curtailment_real(pm, system, t; kwargs...)
    var_load_curtailment_imaginary(pm, system, t; kwargs...)
end

""
function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1, bounded::Bool=true)

    plc = var(pm, :plc)[nw] = @variable(pm.model, [field(system, :loads, :keys)], start =0.0)
    #plc = var(pm, :plc)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :loads_idxs))], start =0.0)
    #for l in assetgrouplist(topology(pm, :loads_idxs))

    for l in field(system, :loads, :keys)
        JuMP.set_upper_bound(plc[l], field(system, :loads, :pd)[l,t])
        JuMP.set_lower_bound(plc[l],0.0)
    end

end

""
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel, t::Int; nw::Int=1, bounded::Bool=true)
end

"variables for modeling storage units, includes grid injection and internal variables, with mixed int variables for charge/discharge"
function var_storage_power_mi(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_storage_power_real(pm, system; kwargs...)
    var_storage_power_imaginary(pm, system; kwargs...)
    var_storage_power_control_imaginary(pm, system; kwargs...)
    var_storage_energy(pm, system; kwargs...)
    var_storage_charge(pm, system; kwargs...)
    var_storage_discharge(pm, system; kwargs...)
    var_storage_complementary_indicator(pm, system; kwargs...)
end

""
function var_storage_power_real(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
    
    ps = var(pm, :ps)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(ps[i], max(-Inf, -field(system, :storages, :thermal_rating)[i]))
            JuMP.set_upper_bound(ps[i], min(Inf,  field(system, :storages, :thermal_rating)[i]))
        end
    end

end

"Model ignores reactive power flows"
function var_storage_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"""
a reactive power slack variable that enables the storage device to inject or
consume reactive power at its connecting bus, subject to the injection limits
of the device.
"""
function var_storage_power_control_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"""
a reactive power slack variable that enables the storage device to inject or
consume reactive power at its connecting bus, subject to the injection limits
of the device.
"""
function var_storage_power_control_imaginary(pm::AbstractACPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    qsc = var(pm, :qsc)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(qsc[i], max(-Inf, -field(system, :storages, :qmin)[i]))
            JuMP.set_upper_bound(qsc[i], min(Inf,  field(system, :storages, :qmax)[i]))
        end
    end

end

""
function var_storage_energy(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    se = var(pm, :se)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(se[i], 0)
            JuMP.set_upper_bound(se[i], field(system, :storages, :energy_rating)[i])
        end

    end

end

""
function var_storage_charge(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    sc = var(pm, :sc)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(sc[i], 0)
            JuMP.set_upper_bound(sc[i], field(system, :storages, :charge_rating)[i])
        end
    end

end

""
function var_storage_discharge(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    sd = var(pm, :sd)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(sd[i], 0)
            JuMP.set_upper_bound(sd[i], field(system, :storages, :discharge_rating)[i])
        end
    end

end

""
function var_storage_complementary_indicator(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    if bounded

        sc_on = var(pm, :sc_on)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))], binary = true, start = 1)
        sd_on = var(pm, :sd_on)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))], binary = true)

    else

        sc_on = var(pm, :sc_on)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))], 
            lower_bound = 0,
            upper_bound = 1
        )

        sd_on = var(pm, :sd_on)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))],
            lower_bound = 0,
            upper_bound = 1
        )

    end

end
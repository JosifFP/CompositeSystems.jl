# Shared Formulation Definitions
""
function var_bus_voltage(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_bus_voltage_angle(pm, system; kwargs...)
    var_bus_voltage_magnitude(pm, system; kwargs...)
end

""
function var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
    var(pm, :va)[nw] = @variable(pm.model, va[assetgrouplist(topology(pm, :buses_idxs))])
end

""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_gen_power_real(pm, system; kwargs...)
    var_gen_power_imaginary(pm, system; kwargs...)
end

""
function var_gen_power_real(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, force_pmin::Bool=false)

    pg = var(pm, :pg)[nw] = @variable(pm.model, pg[assetgrouplist(topology(pm, :generators_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :generators_idxs))
            JuMP.set_upper_bound(pg[i], field(system, :generators, :pmax)[i])
            if force_pmin
                JuMP.set_lower_bound(pg[i], field(system, :generators, :pmin)[i])
            else
                JuMP.set_lower_bound(pg[i], 0.0)
            end
        end
    end

end

""
function var_gen_power_imaginary(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, force_pmin::Bool=false)

    qg = var(pm, :qg)[nw] = @variable(pm.model, qg[assetgrouplist(topology(pm, :generators_idxs))])
    if bounded
        for l in assetgrouplist(topology(pm, :generators_idxs))
            JuMP.set_upper_bound(qg[l], field(system, :generators, :qmax)[l])
            JuMP.set_lower_bound(qg[l], field(system, :generators, :qmin)[l])
        end
    end
end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function var_branch_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_branch_power_real(pm, system; kwargs...)
    var_branch_power_imaginary(pm, system; kwargs...)
end

""
function var_branch_power_real(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))
    p = var(pm, :p)[nw] = @variable(pm.model, p[arcs], container = Dict)
    if bounded
        for (l,i,j) in arcs
            JuMP.set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l])
            JuMP.set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l])
        end
    end
end

""
function var_branch_power_imaginary(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))
    q = var(pm, :q)[nw] = @variable(pm.model, q[arcs], container = Dict)

    if bounded
        for (l,i,j) in arcs
            JuMP.set_lower_bound(q[(l,i,j)], -field(system, :branches, :rate_a)[l])
            JuMP.set_upper_bound(q[(l,i,j)], field(system, :branches, :rate_a)[l])
        end
    end

end

"Defines load power factor variables to represent the active power flow for each branch"
function var_load_power_factor(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    z_demand = var(pm, :z_demand)[nw] = @variable(pm.model, z_demand[assetgrouplist(topology(pm, :buses_idxs))], start =1.0)

    for i in assetgrouplist(topology(pm, :buses_idxs))
        JuMP.set_lower_bound(z_demand[i], 0)
        if isempty(topology(pm, :bus_loads)[i])
            JuMP.set_upper_bound(z_demand[i], 0)
        else
            JuMP.set_upper_bound(z_demand[i], 1)
        end
    end
    
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function var_shunt_admittance_factor(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)
    var(pm, :z_shunt)[nw] = @variable(pm.model, z_shunt[assetgrouplist(topology(pm, :shunts_idxs))], binary = true, start =1.0)
end


#**************************************************** STORAGE VARIABLES ************************************************************************
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
    
    ps = var(pm, :ps)[nw] = @variable(pm.model, ps[assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(ps[i], max(-Inf, -field(system, :storages, :thermal_rating)[i]))
            JuMP.set_upper_bound(ps[i], min(Inf,  field(system, :storages, :thermal_rating)[i]))
        end
    end

end

""
function var_storage_power_imaginary(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    qs = var(pm, :qs)[nw] = @variable(pm.model, qs[assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(qs[i], max(-field(system, :storages, :thermal_rating)[i], field(system, :storages, :qmin)[i]))
            JuMP.set_upper_bound(qs[i], min(field(system, :storages, :thermal_rating)[i], field(system, :storages, :qmax)[i]))
        end
    end

end

"""
a reactive power slack variable that enables the storage device to inject or
consume reactive power at its connecting bus, subject to the injection limits
of the device.
"""
function var_storage_power_control_imaginary(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    qsc = var(pm, :qsc)[nw] = @variable(pm.model, qsc[assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(qsc[i], max(-field(system, :storages, :thermal_rating)[i], field(system, :storages, :qmin)[i]))
            JuMP.set_upper_bound(qsc[i], min(field(system, :storages, :thermal_rating)[i], field(system, :storages, :qmax)[i]))            
        end
    end
end

""
function var_storage_energy(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    se = var(pm, :se)[nw] = @variable(pm.model, se[assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(se[i], 0)
            JuMP.set_upper_bound(se[i], field(system, :storages, :energy_rating)[i])
        end
    end

end

""
function var_storage_charge(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    sc = var(pm, :sc)[nw] = @variable(pm.model, sc[assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(sc[i], 0)
            JuMP.set_upper_bound(sc[i], field(system, :storages, :charge_rating)[i])
        end
    end

end

""
function var_storage_discharge(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    sd = var(pm, :sd)[nw] = @variable(pm.model, sd[assetgrouplist(topology(pm, :storages_idxs))])

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
        sc_on = var(pm, :sc_on)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))], binary = true)
        sd_on = var(pm, :sd_on)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))], binary = true)
    else
        sc_on = var(pm, :sc_on)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))], lower_bound = 0, upper_bound = 1)
        sd_on = var(pm, :sd_on)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))], lower_bound = 0, upper_bound = 1)
    end

end
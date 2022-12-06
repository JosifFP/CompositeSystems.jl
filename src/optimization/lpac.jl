
""
function var_bus_voltage(pm::AbstractLPACModel, system::SystemModel; kwargs...)
    var_bus_voltage_angle(pm, system; kwargs...)
    var_bus_voltage_magnitude(pm, system; kwargs...)
    var_buspair_cosine(pm, system; kwargs...)
end

""
function var_bus_voltage_magnitude(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    phi = var(pm, :phi)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :buses_idxs))])

    if bounded
        #for i in field(system, :buses, :keys)
        for i in assetgrouplist(topology(pm, :buses_idxs))
            JuMP.set_lower_bound(phi[i], field(system, :buses, :vmin)[i] - 1.0)
            JuMP.set_upper_bound(phi[i], field(system, :buses, :vmax)[i] - 1.0)
        end
    end

end

""
function var_buspair_cosine(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    cs = var(pm, :cs)[nw] = @variable(pm.model, [keys(topology(pm, :buspairs))], start=1.0)

    if bounded
        for (bp, buspair) in topology(pm, :buspairs)
            angmin = buspair[2]
            angmax = buspair[3]
            if angmin >= 0
                cos_max = cos(angmin)
                cos_min = cos(angmax)
            end
            if angmax <= 0
                cos_max = cos(angmax)
                cos_min = cos(angmin)
            end
            if angmin < 0 && angmax > 0
                cos_max = 1.0
                cos_min = min(cos(angmin), cos(angmax))
            end

            JuMP.set_lower_bound(cs[bp], cos_min)
            JuMP.set_upper_bound(cs[bp], cos_max)
        end
    end

end

""
function var_gen_power_imaginary(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    qg = var(pm, :qg)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :generators_idxs))])

    if bounded
        for l in assetgrouplist(topology(pm, :generators_idxs))
            JuMP.set_upper_bound(qg[l], field(system, :generators, :qmax)[l])
            JuMP.set_lower_bound(qg[l], field(system, :generators, :qmin)[l])
        end
    end

end

""
function var_gen_power_imaginary(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)

    qg = var(pm, :qg)[nw] = @variable(pm.model, [field(system, :generators, :keys)])

    if bounded
        for l in field(system, :generators, :keys)
            JuMP.set_upper_bound(qg[l], field(system, :generators, :qmax)[l]*field(states, :generators)[l,t])
            JuMP.set_lower_bound(qg[l], field(system, :generators, :qmin)[l]*field(states, :generators)[l,t])
        end
    end

end

""
function var_storage_power_imaginary(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    qs = var(pm, :qs)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :storages_idxs))])

    if bounded
        for i in assetgrouplist(topology(pm, :storages_idxs))
            JuMP.set_lower_bound(qs[i], max(-field(system, :storages, :thermal_rating)[i], field(system, :storages, :qmin)[i]))
            JuMP.set_upper_bound(qs[i], min(field(system, :storages, :thermal_rating)[i], field(system, :storages, :qmax)[i]))
        end
    end

end

""
function var_storage_power_imaginary(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)

    qs = var(pm, :qs)[nw] = @variable(pm.model, [field(system, :storages, :keys)])

    if bounded
        for i in field(system, :storages, :keys)
            JuMP.set_lower_bound(qs[i], max(-field(system, :storages, :thermal_rating)[i],
                field(system, :storages, :qmin)[i])*field(states, :storages)[i,t]
            )
            JuMP.set_upper_bound(qs[i], min(field(system, :storages, :thermal_rating)[i],
            field(system, :storages, :qmax)[i])*field(states, :storages)[i,t]
            )
        end
    end
end


""
function constraint_model_voltage(pm::AbstractLPACModel, system::SystemModel, n::Int)

    _check_missing_keys(pm.var, [:va,:cs], typeof(pm))

    t = var(pm, :va, n)
    cs = var(pm, :cs, n)

    for (bp, buspair) in topology(pm, :buspairs)
        i,j = bp
        angmin = buspair[2]
        angmax = buspair[3]
        vad_max = max(abs(angmin), abs(angmax))
        JuMP.@constraint(pm.model, cs[bp] <= 1 - (1-cos(vad_max))/vad_max^2*(t[i] - t[j])^2)
   end
end

"checks of any of the given keys are missing from the given dict"
function _check_missing_keys(dict, keys, type)
    missing = []
    for key in keys
        if !haskey(dict, key)
            push!(missing, key)
        end
    end
    if length(missing) > 0
        @error("the formulation $(type) requires the following varible(s) $(keys) but the $(missing) variable(s) were not found in the model")
    end
end
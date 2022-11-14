""
function var_bus_voltage(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_bus_voltage_angle(pm, system; kwargs...)
    var_bus_voltage_magnitude(pm, system; kwargs...)
end

""
function var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    var(pm, :va)[nw] = @variable(pm.model, [field(system, :buses, :keys)])

end

""
function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"variable: `v[i]` for `i` in `bus`es"
function var_bus_voltage_magnitude(pm::AbstractACPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    vm = var(pm, :vm)[nw] = @variable(pm.model, [field(system, :buses, :keys)], start =1.0)
   
    if bounded
        for i in field(system, :buses, :keys)
            set_lower_bound(vm[i], field(system, :buses, :vmin)[i])
            set_upper_bound(vm[i], field(system, :buses, :vmax)[i])
        end
    end

end


""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates; kwargs...)
    var_gen_power_real(pm, system, states; kwargs...)
    var_gen_power_imaginary(pm, system, states; kwargs...)
end

""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_gen_power_real(pm, system; kwargs...)
    var_gen_power_imaginary(pm, system; kwargs...)
end


""
function var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates; nw::Int=1, bounded::Bool=true, update::Bool=true)

    if !update
        
        pg = var(pm, :pg)[nw] = @variable(pm.model, [field(system, :generators, :keys)])

        if bounded
            for l in field(system, :generators, :keys)
                set_upper_bound(pg[l], field(system, :generators, :pmax)[l]*field(states, :generators)[l,nw])
                set_lower_bound(pg[l], 0.0*field(states, :generators)[l,nw])
            end
        end

    elseif update && bounded

        pg = var(pm, :pg, 1)

        for l in field(system, :generators, :keys)
            set_lower_bound(pg[l], 0.0)
            set_upper_bound(pg[l], field(system, :generators, :pmax)[l]*field(states, :generators)[l,nw])
        end

    end

end

""
function var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
    
    pg = var(pm, :pg)[nw] = @variable(pm.model, [field(system, :generators, :keys)])

    if bounded
        for l in field(system, :generators, :keys)
            set_upper_bound(pg[l], field(system, :generators, :pmax)[l])
            set_lower_bound(pg[l], 0.0)
        end
    end

end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"Model ignores reactive power flows"
function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates; nw::Int=1, bounded::Bool=true, update::Bool=true)
end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function var_branch_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates; kwargs...)
    var_branch_power_real(pm, system, states; kwargs...)
    var_branch_power_imaginary(pm, system, states; kwargs...)
end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function var_branch_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_branch_power_real(pm, system; kwargs...)
    var_branch_power_imaginary(pm, system; kwargs...)
end

""
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates; nw::Int=1, bounded::Bool=true, update::Bool=true)


    if !update

        p = @variable(pm.model, [topology(pm, :arcs)])
        if bounded
            for (l,i,j) in topology(pm, :arcs)
                set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,nw])
                set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,nw])
            end
        end

        # this explicit type erasure is necessary
        var(pm, :p)[nw] = merge(
            Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from)), 
            Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from))
        )

    elseif update && bounded

        p = var(pm, :p, 1)

        for (l,i,j) in topology(pm, :arcs)

            if typeof(p[(l,i,j)]) ==JuMP.AffExpr
                p_var = first(keys(p[(l,i,j)].terms))
            elseif typeof(p[(l,i,j)]) ==JuMP.VariableRef
                p_var = p[(l,i,j)]
            else
                @error("Expression $(typeof(p[(l,i,j)])) not supported")
            end

            set_lower_bound(p_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,nw])
            set_upper_bound(p_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,nw])

        end

    end

end

""
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    p = @variable(pm.model, [topology(pm, :arcs)])

    if bounded
        for (l,i,j) in topology(pm, :arcs)
            set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l])
            set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l])
        end
    end

    # this explicit type erasure is necessary
    var(pm, :p)[nw] = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from)), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from))
    )

end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates; nw::Int=1, bounded::Bool=true, update::Bool=true)
end

"DC models ignore reactive power flows"
function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel; kwargs...)
    var_load_curtailment_real(pm, system; kwargs...)
    var_load_curtailment_imaginary(pm, system; kwargs...)
end

"Defines load curtailment variables p to represent the active power flow for each branch"
function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel, states::SystemStates; kwargs...)
    var_load_curtailment_real(pm, system, states; kwargs...)
    var_load_curtailment_imaginary(pm, system, states; kwargs...)
end

""
function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates; nw::Int=1, bounded::Bool=true, update::Bool=true)

    if !update
        
        plc = var(pm, :plc)[nw] = @variable(pm.model, [field(system, :loads, :keys)], start =0.0)
        for l in field(system, :loads, :keys)
            set_upper_bound(plc[l], field(system, :loads, :pd)[l,nw])
            set_lower_bound(plc[l],0.0)
        end

    elseif update && bounded

        plc = var(pm, :plc, 1)
        for l in field(system, :loads, :keys)
            set_upper_bound(plc[l], field(system, :loads, :pd)[l,nw]*field(states, :loads)[l,nw])
            set_lower_bound(plc[l],0.0*field(states, :loads)[l,nw])
        end

    end

end

""
function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    plc = var(pm, :plc)[nw] = @variable(pm.model, [field(system, :loads, :keys)], start =0.0)

    for l in field(system, :loads, :keys)
        set_upper_bound(plc[l], field(system, :loads, :pd)[l,nw])
        set_lower_bound(plc[l],0.0)
    end

end

""
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true)
end

""
function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates; nw::Int=1, bounded::Bool=true)
end

# ""
# function comp_start_value(comp::Dict{String,<:Any}, key::String, default=0.0)
#     return get(comp, key, default)
# end

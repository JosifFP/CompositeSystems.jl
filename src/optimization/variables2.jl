""
function var_gen_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates; kwargs...)
    var_gen_power_real(pm, system, states; kwargs...)
    var_gen_power_imaginary(pm, system; kwargs...)
end

""
function var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates; nw::Int=1, bounded::Bool=true, report::Bool=false)
    
    pg = var(pm, :pg)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :generators_idxs))])

    if bounded
        for l in assetgrouplist(topology(pm, :generators_idxs))
            set_upper_bound(pg[l], field(system, :generators, :pmax)[l]*field(states, :generators)[l,nw])
            set_lower_bound(pg[l], 0.0)
        end
    end

end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function var_branch_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates; kwargs...)
    var_branch_power_real(pm, system, states; kwargs...)
    var_branch_power_imaginary(pm, system; kwargs...)
end

""
function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates; nw::Int=1, bounded::Bool=true, report::Bool=false)

    arcs_from = filter(!ismissing, skipmissing(topology(pm, :arcs, :arcs_from)))
    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs, :arcs)))
    p = @variable(pm.model, [arcs])


    if bounded
        for (l,i,j) in arcs
            set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,nw])
            set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,nw])
        end
    end

    # this explicit type erasure is necessary
    var(pm, :p)[nw] = merge(
        Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in arcs_from), 
        Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in arcs_from))
    #sol_component_value_edge(pm, :branch, :pf, :pt, ref(pm, :arcs_from), ref(pm, :arcs_to), p_expr)
end

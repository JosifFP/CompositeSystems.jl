#***************************************************** VARIABLES *************************************************************************
""
function update_var_gen_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    update_var_gen_power_real(pm, system, states, t)
    update_var_gen_power_imaginary(pm, system, states, t)
end

""
function update_var_gen_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    pg = var(pm, :pg, 1)
    for l in eachindex(field(system, :generators, :keys))
        JuMP.set_upper_bound(pg[l], field(system, :generators, :pmax)[l]*field(states, :generators_de)[l,t])
        JuMP.set_lower_bound(pg[l], 0.0)
    end

end

""
function update_var_gen_power_imaginary(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    qg = var(pm, :qg, 1)
    for l in eachindex(field(system, :generators, :keys))
        JuMP.set_upper_bound(qg[l], field(system, :generators, :qmax)[l]*field(states, :generators_de)[l,t])
        JuMP.set_lower_bound(qg[l], field(system, :generators, :qmin)[l]*field(states, :generators_de)[l,t])
    end

end

"Defines DC or AC power flow variables p to represent the active power flow for each branch"
function update_var_branch_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    update_var_branch_power_real(pm, system, states, t)
    update_var_branch_power_imaginary(pm, system, states, t)
end

""
function update_var_branch_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    p = var(pm, :p, 1)
    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))

    for (l,i,j) in arcs
        if typeof(p[(l,i,j)]) ==JuMP.AffExpr
            p_var = first(keys(p[(l,i,j)].terms))
        elseif typeof(p[(l,i,j)]) ==JuMP.VariableRef
            p_var = p[(l,i,j)]
        else
            @error("Expression $(typeof(p[(l,i,j)])) not supported")
        end
        JuMP.set_lower_bound(p_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
        JuMP.set_upper_bound(p_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    end

end

""
function update_var_branch_power_imaginary(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    q = var(pm, :q, 1)
    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))

    for (l,i,j) in arcs
        if typeof(q[(l,i,j)]) ==JuMP.AffExpr
            q_var = first(keys(q[(l,i,j)].terms))
        elseif typeof(q[(l,i,j)]) ==JuMP.VariableRef
            q_var = q[(l,i,j)]
        else
            @error("Expression $(typeof(q[(l,i,j)])) not supported")
        end
        JuMP.set_lower_bound(q_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
        JuMP.set_upper_bound(q_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    end

end

""
function update_var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    plc = var(pm, :plc, 1)
    JuMP.set_upper_bound(plc[i], field(system, :loads, :pd)[i,t]*field(states, :loads)[i,t])
    JuMP.set_lower_bound(plc[i],0.0)

end

function update_var_load_curtailment_imaginary(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    qlc = var(pm, :qlc, 1)
    JuMP.set_upper_bound(qlc[i], field(system, :loads, :pd)[i,t]*field(system, :loads, :pf)[i]*field(states, :loads)[i,t])
    JuMP.set_lower_bound(qlc[i],0.0)

end

#***************************************************** STORAGE VAR UPDATES *************************************************************************
""
function update_con_storage(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    se_1 = field(states, :se)[i,t-1]
    JuMP.set_normalized_rhs(con(pm, :storage_state, 1)[i], se_1)
end

"Not needed"
function update_var_storage_power_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    ps = var(pm, :ps, 1)
    JuMP.set_lower_bound(ps[i], max(-Inf, -field(system, :storages, :thermal_rating)[i])*field(states, :storages)[i,t])
    JuMP.set_upper_bound(ps[i], min(Inf,  field(system, :storages, :thermal_rating)[i])*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_energy(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    se = var(pm, :se, 1)
    JuMP.set_lower_bound(se[i], 0)
    JuMP.set_upper_bound(se[i], field(system, :storages, :energy_rating)[i]*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_charge(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    sc = var(pm, :sc, 1)
    JuMP.set_lower_bound(sc[i], 0)
    JuMP.set_upper_bound(sc[i], field(system, :storages, :charge_rating)[i]*field(states, :storages)[i,t])

end

"Not needed"
function update_var_storage_discharge(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
    
    sd = var(pm, :sc, 1)
    for i in eachindex(field(system, :storages, :keys))
        JuMP.set_lower_bound(sd[i], 0)
        JuMP.set_upper_bound(sd[i], field(system, :storages, :discharge_rating)[i]*field(states, :storages)[i,t])
    end

end


#***************************************************UPDATES CONSTRAINTS ****************************************************************

function update_con_thermal_limits(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    if hasfield(Branches, :rate_a)
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, 1)[i], (field(system, :branches, :rate_a)[i]^2)*field(states, :branches)[i,t])
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, 1)[i], (field(system, :branches, :rate_a)[i]^2)*field(states, :branches)[i,t])
    end
    
end
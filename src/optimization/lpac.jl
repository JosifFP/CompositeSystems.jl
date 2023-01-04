#***************************************************** VARIABLES *************************************************************************
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
        for i in assetgrouplist(topology(pm, :buses_idxs))
            JuMP.set_lower_bound(phi[i], field(system, :buses, :vmin)[i] - 1.0)
            JuMP.set_upper_bound(phi[i], field(system, :buses, :vmax)[i] - 1.0)
        end
    end

end

""
function var_buspair_cosine(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
    cs = var(pm, :cs)[nw] = @variable(pm.model, [buspairs], start=1.0, container = Dict)

    if bounded
        for (bp, buspair) in topology(pm, :buspairs)
            if !ismissing(buspair)
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

end

#***************************************************** CONSTRAINTS *************************************************************************
""
function _con_model_voltage(pm::AbstractLPACModel, bp::Tuple{Int,Int}, n::Int)

    #_check_missing_keys(pm.var, [:va,:cs], typeof(pm))
    #t = var(pm, :va, n)
    #cs = var(pm, :cs, n)
    buspair = topology(pm, :buspairs)[bp]
    i,j = bp
    angmin = buspair[2]
    angmax = buspair[3]
    vad_max = max(abs(angmin), abs(angmax))
    con(pm, :model_voltage, n)[bp] = JuMP.@constraint(pm.model, var(pm, :cs, n)[bp] <= 1 - (1-cos(vad_max))/vad_max^2*(var(pm, :va, n)[i] - var(pm, :va, n)[j])^2)

end

""
function _con_power_balance(
    pm::AbstractLPACModel, system::SystemModel, i::Int, nw::Int, bus_arcs::Vector{Tuple{Int, Int, Int}}, 
    generators_nodes::Vector{Int}, loads_nodes::Vector{Int}, shunts_nodes::Vector{Int}, storages_nodes::Vector{Int},
    bus_pd::Vector{Float32}, bus_qd::Vector{Float32}, bus_gs::Vector{Float32}, bus_bs::Vector{Float32})

    phi  = var(pm, :phi, nw)
    p    = var(pm, :p, nw)
    q    = var(pm, :q, nw)
    pg   = var(pm, :pg, nw)
    qg   = var(pm, :qg, nw)
    plc   = var(pm, :plc, nw)
    qlc   = var(pm, :qlc, nw)
    ps   = var(pm, :ps, nw)
    qs   = var(pm, :qs, nw)

    exp_p = @expression(pm.model,
    sum(p[a] for a in bus_arcs)
    + sum(ps[s] for s in storages_nodes)
    - sum(pg[g] for g in generators_nodes)
    - sum(plc[m] for m in loads_nodes)     
    )

    exp_q = @expression(pm.model,
    sum(q[a] for a in bus_arcs)
    + sum(qs[s] for s in storages_nodes)
    - sum(qg[g] for g in generators_nodes)
    - sum(qlc[m] for m in loads_nodes)     
    )

    JuMP.drop_zeros!(exp_p)
    JuMP.drop_zeros!(exp_q)

    con(pm, :power_balance_p, nw)[i] = @constraint(pm.model, exp_p == -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*(1.0 + 2*phi[i]))
    con(pm, :power_balance_q, nw)[i] = @constraint(pm.model, exp_q == -sum(qd for qd in bus_qd) + sum(bs for bs in bus_bs)*(1.0 + 2*phi[i]))

end

""
function _con_power_balance_nolc(
    pm::AbstractLPACModel, system::SystemModel, i::Int, nw::Int, bus_arcs::Vector{Tuple{Int, Int, Int}}, 
    generators_nodes::Vector{Int}, loads_nodes::Vector{Int}, shunts_nodes::Vector{Int}, storages_nodes::Vector{Int},
    bus_pd::Vector{Float32}, bus_qd::Vector{Float32}, bus_gs::Vector{Float32}, bus_bs::Vector{Float32})

    phi  = var(pm, :phi, nw)
    p    = var(pm, :p, nw)
    q    = var(pm, :q, nw)
    pg   = var(pm, :pg, nw)
    qg   = var(pm, :qg, nw)
    #plc   = var(pm, :plc, nw)
    #qlc   = var(pm, :qlc, nw)
    ps   = var(pm, :ps, nw)
    qs   = var(pm, :qs, nw)

    exp_p = @expression(pm.model,
    sum(p[a] for a in bus_arcs)
    + sum(ps[s] for s in storages_nodes)
    - sum(pg[g] for g in generators_nodes)
    #- sum(plc[m] for m in loads_nodes)     
    )

    exp_q = @expression(pm.model,
    sum(q[a] for a in bus_arcs)
    + sum(qs[s] for s in storages_nodes)
    - sum(qg[g] for g in generators_nodes)
    #- sum(qlc[m] for m in loads_nodes)     
    )

    #JuMP.drop_zeros!(exp_p);#JuMP.drop_zeros!(exp_q)
    con(pm, :power_balance_p, nw)[i] = @constraint(pm.model, exp_p == -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*(1.0 + 2*phi[i]))
    con(pm, :power_balance_q, nw)[i] = @constraint(pm.model, exp_q == -sum(qd for qd in bus_qd) + sum(bs for bs in bus_bs)*(1.0 + 2*phi[i]))

end

"AC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractLPACModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr_to)

    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    q_fr  = var(pm, :q, nw)[i, f_bus, t_bus]
    phi_fr = var(pm, :phi, nw)[f_bus]
    phi_to = var(pm, :phi, nw)[t_bus]
    cs     = var(pm, :cs, nw)[(f_bus, t_bus)]

    con(pm, :ohms_yt_from_p, nw)[i] = @constraint(pm.model, p_fr ==  (g+g_fr)/tm^2*(1.0 + 2*phi_fr) + (-g*tr+b*ti)/tm^2*(cs + phi_fr + phi_to) + (-b*tr-g*ti)/tm^2*(va_fr_to))
    con(pm, :ohms_yt_from_q, nw)[i] = @constraint(pm.model, q_fr == -(b+b_fr)/tm^2*(1.0 + 2*phi_fr) - (-b*tr-g*ti)/tm^2*(cs + phi_fr + phi_to) + (-g*tr+b*ti)/tm^2*(va_fr_to))
end

"""
Creates Ohms constraints (yt post fix indicates that Y and T values are in rectangular form)
"""
function _con_ohms_yt_to(pm::AbstractLPACModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr_to)

    p_to  = var(pm, :p, nw)[i, t_bus, f_bus]
    q_to  = var(pm, :q, nw)[i, t_bus, f_bus]
    phi_fr = var(pm, :phi, nw)[f_bus]
    phi_to = var(pm, :phi, nw)[t_bus]
    cs     = var(pm, :cs, nw)[(f_bus, t_bus)]

    con(pm, :ohms_yt_to_p, nw)[i] = @constraint(pm.model, p_to ==  (g+g_to)*(1.0 + 2*phi_to) + (-g*tr-b*ti)/tm^2*(cs + phi_fr + phi_to) + (-b*tr+g*ti)/tm^2*-(va_fr_to))
    con(pm, :ohms_yt_to_q, nw)[i] = @constraint(pm.model, q_to == -(b+b_to)*(1.0 + 2*phi_to) - (-b*tr+g*ti)/tm^2*(cs + phi_fr + phi_to) + (-g*tr-b*ti)/tm^2*-(va_fr_to))

end

#***************************************************** UPDATES *************************************************************************

""
function update_var_bus_voltage_magnitude(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
end

""
function update_var_buspair_cosine(pm::AbstractLPACModel, bp::Tuple{Int,Int})

    cs = var(pm, :cs, 1)
    buspair = topology(pm, :buspairs)[bp]

    if !ismissing(buspair)
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
    else
        JuMP.set_lower_bound(cs[bp], 0)
        JuMP.set_upper_bound(cs[bp], 0)   
    end
    
end

""
function update_con_power_balance(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    phi  = var(pm, :phi, 1)
    loads_nodes = topology(pm, :loads_nodes)[i]
    shunts_nodes = topology(pm, :shunts_nodes)[i]
    bus_pd = Float32.([field(system, :loads, :pd)[k,t] for k in loads_nodes])
    bus_qd = Float32.([field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in loads_nodes])
    bus_gs = Float32.([field(system, :shunts, :gs)[k] for k in shunts_nodes if field(states, :shunts)[k,t] == true])
    bus_bs = Float32.([field(system, :shunts, :bs)[k] for k in shunts_nodes if field(states, :shunts)[k,t] == true])

    JuMP.set_normalized_coefficient(con(pm, :power_balance_p, 1)[i], phi[i], -sum(gs for gs in bus_gs)*2)
    JuMP.set_normalized_coefficient(con(pm, :power_balance_q, 1)[i], phi[i], +sum(bs for bs in bus_bs)*2)

    JuMP.set_normalized_rhs(con(pm, :power_balance_p, 1)[i], -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*(1.0))
    JuMP.set_normalized_rhs(con(pm, :power_balance_q, 1)[i], -sum(qd for qd in bus_qd) + sum(bs for bs in bus_bs)*(1.0))
        
end

""
function update_con_power_balance_nolc(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, i::Int, t::Int)

    phi  = var(pm, :phi, 1)
    loads_nodes = topology(pm, :loads_nodes)[i]
    shunts_nodes = topology(pm, :shunts_nodes)[i]

    bus_pd = Float32.([field(system, :loads, :pd)[k,t] for k in loads_nodes if field(states, :loads)[k,t] == true])
    bus_qd = Float32.([field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in loads_nodes if field(states, :loads)[k,t] == true])
    bus_gs = Float32.([field(system, :shunts, :gs)[k] for k in shunts_nodes if field(states, :shunts)[k,t] == true])
    bus_bs = Float32.([field(system, :shunts, :bs)[k] for k in shunts_nodes if field(states, :shunts)[k,t] == true])

    JuMP.set_normalized_coefficient(con(pm, :power_balance_p, 1)[i], phi[i], -sum(gs for gs in bus_gs)*2)
    JuMP.set_normalized_coefficient(con(pm, :power_balance_q, 1)[i], phi[i], +sum(bs for bs in bus_bs)*2)

    JuMP.set_normalized_rhs(con(pm, :power_balance_p, 1)[i], -sum(pd for pd in bus_pd) - sum(gs for gs in bus_gs)*(1.0))
    JuMP.set_normalized_rhs(con(pm, :power_balance_q, 1)[i], -sum(qd for qd in bus_qd) + sum(bs for bs in bus_bs)*(1.0))

end

""
function reset_con_ohms_yt(pm::AbstractLPACModel, active_branches::Vector{Int})
    JuMP.delete(pm.model, con(pm, :ohms_yt_from_p, 1).data)
    JuMP.delete(pm.model, con(pm, :ohms_yt_to_p, 1).data)
    JuMP.delete(pm.model, con(pm, :ohms_yt_from_q, 1).data)
    JuMP.delete(pm.model, con(pm, :ohms_yt_to_q, 1).data)
    add_con_container!(pm.con, :ohms_yt_from_p, active_branches)
    add_con_container!(pm.con, :ohms_yt_to_p, active_branches)
    add_con_container!(pm.con, :ohms_yt_from_q, active_branches)
    add_con_container!(pm.con, :ohms_yt_to_q, active_branches)
end

""
function reset_con_model_voltage(pm::AbstractLPACModel, buspair::Vector{Tuple{Int, Int}})
    JuMP.delete(pm.model, con(pm, :model_voltage, 1).data)
    add_con_container!(pm.con, :model_voltage, buspair)
end







 
 
  


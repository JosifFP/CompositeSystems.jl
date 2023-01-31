



""
function update_var_bus_voltage_magnitude(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)

    phi = var(pm, :phi, nw)[i]
    if field(states, :buses)[i,t] == 4
        JuMP.set_upper_bound(phi, 0)
        JuMP.set_lower_bound(phi, 0)
    else
        JuMP.set_lower_bound(phi[i], field(system, :buses, :vmin)[i] - 1.0)
        JuMP.set_upper_bound(phi[i], field(system, :buses, :vmax)[i] - 1.0)
    end

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
        JuMP.set_lower_bound(cs[bp], 0.0)
        JuMP.set_upper_bound(cs[bp], 0.0)   
    end
    
end

"AC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractLPACModel, states::SystemStates, i::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    
    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    q_fr  = var(pm, :q, nw)[i, f_bus, t_bus]
    phi_fr = var(pm, :phi, nw)[f_bus]
    phi_to = var(pm, :phi, nw)[t_bus]
    cs     = var(pm, :cs, nw)[(f_bus, t_bus)]

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_p, nw)[i], p_fr, field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_q, nw)[i], q_fr, field(states, :branches)[i,t])

    JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_p, nw)[i], (g+g_fr)/tm^2*field(states, :branches)[i,t])
    JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_q, nw)[i], -(b+b_fr)/tm^2*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_p, nw)[i], phi_fr, -(((g+g_fr)/tm^2)*2 + (-g*tr+b*ti)/tm^2)*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_q, nw)[i], phi_fr, -(-((b+b_fr)/tm^2)*2 - (-b*tr-g*ti)/tm^2)*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_p, nw)[i], cs, -(-g*tr+b*ti)/tm^2*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_q, nw)[i], cs, +(-b*tr-g*ti)/tm^2*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_p, nw)[i], phi_to, -(-g*tr+b*ti)/tm^2*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_q, nw)[i], phi_to, +(-b*tr-g*ti)/tm^2*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_p, nw)[i], va_fr, -(-b*tr-g*ti)/tm^2*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_q, nw)[i], va_fr, -(-g*tr+b*ti)/tm^2*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_p, nw)[i], va_to, +(-b*tr-g*ti)/tm^2*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_from_q, nw)[i], va_to, +(-g*tr+b*ti)/tm^2*field(states, :branches)[i,t])

end


"AC Line Flow Constraints"
function _update_con_ohms_yt_to(pm::AbstractLPACModel, states::SystemStates, i::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)

    p_to  = var(pm, :p, nw)[i, t_bus, f_bus]
    q_to  = var(pm, :q, nw)[i, t_bus, f_bus]
    phi_fr = var(pm, :phi, nw)[f_bus]
    phi_to = var(pm, :phi, nw)[t_bus]
    cs     = var(pm, :cs, nw)[(f_bus, t_bus)]

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_p, nw)[i], p_to, field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_q, nw)[i], q_to, field(states, :branches)[i,t])

    JuMP.set_normalized_rhs(con(pm, :ohms_yt_to_p, nw)[i], (g+g_to)*field(states, :branches)[i,t])
    JuMP.set_normalized_rhs(con(pm, :ohms_yt_to_q, nw)[i], -(b+b_to)*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_p, nw)[i], phi_to, -((g+g_to)*2 + (-g*tr-b*ti)/tm^2)*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_q, nw)[i], phi_to, -(-(b+b_to)*2 - (-b*tr+g*ti)/tm^2)*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_p, nw)[i], cs, -(-g*tr-b*ti)/tm^2*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_q, nw)[i], cs, +(-b*tr+g*ti)/tm^2*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_p, nw)[i], phi_fr, -(-g*tr-b*ti)/tm^2*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_q, nw)[i], phi_fr, +(-b*tr+g*ti)/tm^2*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_p, nw)[i], va_fr, +(-b*tr+g*ti)/tm^2*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_q, nw)[i], va_fr, +(-g*tr-b*ti)/tm^2*field(states, :branches)[i,t])

    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_p, nw)[i], va_to, -(-b*tr+g*ti)/tm^2*field(states, :branches)[i,t])
    # JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_q, nw)[i], va_to, -(-g*tr-b*ti)/tm^2*field(states, :branches)[i,t])
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
function reset_con_thermal_limits(pm::AbstractLPACModel, active_branches::Vector{Int})
    JuMP.delete(pm.model, con(pm, :thermal_limit_from, 1).data)
    JuMP.delete(pm.model, con(pm, :thermal_limit_to, 1).data)
    add_con_container!(pm.con, :thermal_limit_from, active_branches)
    add_con_container!(pm.con, :thermal_limit_to, active_branches)
end

""
function reset_con_model_voltage(pm::AbstractLPACModel, buspair::Vector{Tuple{Int, Int}})
    JuMP.delete(pm.model, con(pm, :model_voltage, 1).data)
    add_con_container!(pm.con, :model_voltage, buspair)
end


#---------------------------------------------------------------- DC ----------------------------------------------------------------

"Nothing to do, no voltage angle variables"
function var_bus_voltage(pm::AbstractNFAModel, system::SystemModel; kwargs...)
end


"""
Creates Ohms constraints (yt post fix indicates that Y and T values are in rectangular form)
"""
function _con_ohms_yt_to(pm::AbstractDCPLLModel, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    p_to  = var(pm, :p, nw)[i, t_bus, f_bus]

    r = g/(g^2 + b^2)
    con(pm, :ohms_yt_to_p, nw)[i] = @constraint(pm.model, p_fr + p_to >= r*(p_fr^2))
end

"Nothing to do, no voltage angle variables"
function con_voltage_angle_difference(pm::AbstractNFAModel, bp::Tuple{Int,Int}; nw::Int=1)
end

"Nothing to do, no voltage angle variables"
function _con_voltage_angle_difference(pm::AbstractNFAModel, nw::Int, f_bus::Int, t_bus::Int, angmin, angmax)
end

"`-rate_a <= p[f_idx] <= rate_a`"
function _con_thermal_limit_from(pm::AbstractDCPowerModel, n::Int, i::Int, f_idx, rate_a)

    p_fr = var(pm, :p, n)[f_idx]

    if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
        con(pm, :thermal_limit_from, n)[i] = JuMP.LowerBoundRef(p_fr)
        JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)
        if JuMP.has_upper_bound(p_fr)
            JuMP.upper_bound(p_fr) > rate_a && JuMP.set_upper_bound(p_fr, rate_a)
        end
    else
        con(pm, :thermal_limit_from, n)[i] = JuMP.@constraint(pm.model, p_fr <= rate_a)
    end

end

"Nothing to do, this model is symetric"
function _con_thermal_limit_to(pm::AbstractAPLossLessModels, n::Int, i::Int, t_idx, rate_a)

    l,u,v = t_idx
    p_fr = var(pm, :p, n)[(l,v,u)]
    
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_upper_bound(p_fr)
        con(pm, :thermal_limit_to, n)[i] = JuMP.UpperBoundRef(p_fr)
    else
        p_to = var(pm, :p, n)[t_idx]
        con(pm, :thermal_limit_to, n)[i] = @constraint(pm.model, p_to <= rate_a)
    end

end

"Nothing to do, this model is symetric"
function update_con_thermal_limits(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
end

""
function update_con_voltage_angle_difference(pm::AbstractNFAModel, system::SystemModel, states::SystemStates, i::Int, t::Int)
end

""
function _update_con_ohms_yt_to(pm::AbstractDCPLLModel, states::SystemStates, i::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[i, f_bus, t_bus]
    p_to  = var(pm, :p, nw)[i, t_bus, f_bus]
    JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_p, nw)[i], p_fr, field(states, :branches)[i,t])
    JuMP.set_normalized_coefficient(con(pm, :ohms_yt_to_p, nw)[i], p_to, field(states, :branches)[i,t])

end

""
function reset_con_ohms_yt(pm::AbstractNFAModel, active_branches::Vector{Int})
end

""
function reset_con_ohms_yt(pm::AbstractDCPModel, active_branches::Vector{Int})
    JuMP.delete(pm.model, con(pm, :ohms_yt_from_p, 1).data)
    add_con_container!(pm.con, :ohms_yt_from_p, active_branches)
end

""
function reset_con_ohms_yt(pm::AbstractDCPLLModel, active_branches::Vector{Int})
    JuMP.delete(pm.model, con(pm, :ohms_yt_from_p, 1).data)
    JuMP.delete(pm.model, con(pm, :ohms_yt_to_p, 1).data)
    add_con_container!(pm.con, :ohms_yt_from_p, active_branches)
    add_con_container!(pm.con, :ohms_yt_to_p, active_branches)
end

""
function reset_con_voltage_angle_difference(pm::AbstractNFAModel, buspair::Vector{Tuple{Int, Int}})
end

abstract type AbstractDCPLLModel <: AbstractDCPModel end
struct DCPLLPowerModel <: AbstractDCPLLModel @pm_fields end

abstract type PM_AbstractDCPModel <: AbstractDCPowerModel end
struct PM_DCPPowerModel <: PM_AbstractDCPModel @pm_fields end



""
function update_var_buspair_cosine(pm::AbstractPowerModel, bp::Tuple{Int,Int})
end

""
function update_con_thermal_limits(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)

    if hasfield(Branches, :rate_a)
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, nw)[i], (field(system, :branches, :rate_a)[i]^2)*field(states, :branches)[i,t])
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, nw)[i], (field(system, :branches, :rate_a)[i]^2)*field(states, :branches)[i,t])
    end
    
end


# ""
# function update_con_voltage_angle_difference(pm::AbstractLPACModel, bp::Tuple{Int,Int}; nw::Int=1)

#     f_bus,t_bus = bp
#     va_fr = var(pm, :va, nw)[f_bus]
#     va_to = var(pm, :va, nw)[t_bus]
#     buspair = topology(pm, :buspairs)[bp]
    
#     if !ismissing(buspair)
#         JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_fr, 1)
#         JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_to, -1)
#         JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_fr, 1)
#         JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_to, -1)
#         JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], buspair[3])
#         JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], buspair[2])
#     else
#         JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_fr, 0)
#         JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_to, 0)
#         JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_fr, 0)
#         JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_to, 0)
#         JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], 0)
#         JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], 0)
#     end

# end

""
function update_con_voltage_angle_difference(pm::AbstractPolarModels, bp::Tuple{Int,Int}; nw::Int=1)

    buspair = topology(pm, :buspairs)[bp]

    if !ismissing(buspair)
        f_bus,t_bus = bp
        va_fr = var(pm, :va, nw)[f_bus]
        va_to = var(pm, :va, nw)[t_bus]
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], buspair[3])
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], buspair[2])

        # if JuMP.has_upper_bound(va_fr) && JuMP.has_lower_bound(va_fr)
        #     JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_fr, 0)
        #     JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_fr, 0)
        # else
        #     JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_fr, 1)
        #     JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_fr, 1)
        # end
    
        # if JuMP.has_upper_bound(va_to) && JuMP.has_lower_bound(va_to) 
        #     JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_to, 0)
        #     JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_to, 0)
        # else
        #     JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_to, -1)
        #     JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_to, -1)
        # end

    else

        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, nw)[bp], 5.235987755982988)
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, nw)[bp], -5.235987755982988)
        #JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_to, 0)
        #JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_to, 0)
        #JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_upper, nw)[(f_bus, t_bus)], va_fr, 0)
        #JuMP.set_normalized_coefficient(con(pm, :voltage_angle_diff_lower, nw)[(f_bus, t_bus)], va_fr, 0)
    end

end

""
function reset_con_voltage_angle_difference(pm::AbstractPolarModels, buspair::Vector{Tuple{Int, Int}})

    JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
    JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)
    add_con_container!(pm.con, :voltage_angle_diff_upper, buspair)
    add_con_container!(pm.con, :voltage_angle_diff_lower, buspair)

end

""
function reset_con_model_voltage(pm::AbstractPowerModel, buspair::Vector{Tuple{Int, Int}})
end

"Updates OPF formulation with Load Curtailment variables and constraints"
function update_method!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    for i in field(system, :generators, :keys)
        update_var_gen_power_real(pm, system, states, i, t)
    end

    for i in field(system, :buses, :keys)
        update_var_load_power_factor(pm, system, states, i, t)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_var_bus_voltage_magnitude(pm, system, states, i, t)
        update_con_power_balance(pm, system, states, i, t)
    end

    if all(states.storages[:,t]) ≠ true || all(states.storages[:,t-1]) ≠ true
        for i in field(system, :storages, :keys)
            update_con_storage(pm, system, states, i, t)
        end
    end

    if all(states.branches[:,t]) ≠ true || all(states.branches[:,t-1]) ≠ true

        for arc in field(system, :arcs)
            #update_var_branch_power_real(pm, system, states, arc, t)
            update_var_branch_power_imaginary(pm, system, states, arc, t)
        end    
        for i in field(system, :branches, :keys)
            #update_con_thermal_limits(pm, system, states, i, t)
            #update_con_ohms_yt(pm, system, states, i, t)
        end
        for (bp,_) in field(system, :buspairs)
            #update_con_voltage_angle_difference(pm, bp)
        end

        active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
       # reset_con_model_voltage(pm, active_buspairs)
        for (bp,buspair) in topology(pm, :buspairs)
            #update_var_buspair_cosine(pm, bp)
            if !ismissing(buspair)
                #con_model_voltage(pm, bp)
                #con_voltage_angle_difference(pm, bp)
            end
        end
        #reset_con_voltage_angle_difference(pm, active_buspairs) 
        #reset_con_ohms_yt(pm, active_branches)
        #active_branches = assetgrouplist(topology(pm, :branches_idxs))
        # for i in active_branches
        #     con_ohms_yt(pm, system, i)
        # end
    end
    return
end

""
function initialize_availability!(rng::AbstractRNG, availability::Matrix{Float32}, asset::Generators, N::Int)

    for i in asset.keys
        if asset.status[i] ≠ false

            sequence = view(availability, i, :)
            fill!(sequence, 1)
            λ_updn = asset.λ_updn[i]/N
            μ_updn = asset.μ_updn[i]/N
        
            if asset.state_model[i] == 3
                λ_upde = asset.λ_upde[i]/N
                μ_upde = asset.μ_upde[i]/N
                pde = asset.pde[i]
                if λ_updn ≠ 0.0 && λ_upde ≠ 0.0
                    cycles!(sequence, pde, rng, λ_updn, μ_updn, λ_upde, μ_upde, N)
                end
            else
                if λ_updn ≠ 0.0
                    cycles!(sequence, rng, λ_updn, μ_updn, N)
                end
            end
        end
    end
    return
end

""
function initialize_availability!(rng::AbstractRNG, availability::Matrix{Bool}, asset::AbstractAssets, N::Int)

    for i in asset.keys
        if asset.status[i] ≠ false
            sequence = availability[i,:]
            fill!(sequence, 1)
            λ_updn = asset.λ_updn[i]/N
            μ_updn = asset.μ_updn[i]/N
            if λ_updn ≠ 0.0
                cycles!(sequence, rng, λ_updn, μ_updn, N)
            end
        else
            fill!(sequence, 0)
        end
    end
    return
end

""
function initialize_availability!(rng::AbstractRNG, availability::Matrix{Bool}, asset::CommonBranches, N::Int)

    for i in asset.keys
        sequence = view(availability, i, :)
        fill!(sequence, 1)
        λ_updn = asset.λ_updn[i]/N
        μ_updn = asset.μ_updn[i]/N
        if λ_updn ≠ 0.0
            cycles!(sequence, rng, λ_updn, μ_updn, N)
        end
    end
    return
end

function con_power_balance(pm::AbstractLPACModel, system::SystemModel, i::Int, t::Int; nw::Int=1)

    bus_arcs = topology(pm, :busarcs)[i]
    bus_gens = topology(pm, :bus_generators)[i]
    bus_loads = topology(pm, :bus_loads)[i]
    bus_shunts = topology(pm, :bus_shunts)[i]
    bus_storage = topology(pm, :bus_storages)[i]

    bus_pd = Float32.([field(system, :loads, :pd)[k,t] for k in bus_loads])
    bus_qd = Float32.([field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in bus_loads])
    bus_gs = Float32.([field(system, :shunts, :gs)[k] for k in bus_shunts])
    bus_bs = Float32.([field(system, :shunts, :bs)[k] for k in bus_shunts])

    phi  = var(pm, :phi, nw)
    p    = var(pm, :p, nw)
    q    = var(pm, :q, nw)
    pg   = var(pm, :pg, nw)
    qg   = var(pm, :qg, nw)
    z_demand   = var(pm, :z_demand, nw)
    ps   = var(pm, :ps, nw)
    qs   = var(pm, :qs, nw)

    exp_p = @expression(pm.model,
    sum(p[a] for a in bus_arcs)
    - sum(pg[g] for g in bus_gens)
    + sum(ps[s] for s in bus_storage)
    + sum(pd for pd in bus_pd)*z_demand[i]
    + sum(gs for gs in bus_gs)*(1.0 + 2*phi[i])
    )

    exp_q = @expression(pm.model,
    sum(q[a] for a in bus_arcs)
    - sum(qg[g] for g in bus_gens)
    + sum(qs[s] for s in bus_storage)
    + sum(qd for qd in bus_qd)*z_demand[i]
    - sum(bs for bs in bus_bs)*(1.0 + 2*phi[i])
    )

    con(pm, :power_balance_p, nw)[i] = @constraint(pm.model, exp_p == 0.0)
    con(pm, :power_balance_q, nw)[i] = @constraint(pm.model, exp_q == 0.0)

end

""
function update_con_power_balance_shunts(pm::AbstractLPACModel, system::SystemModel, states::SystemStates, i::Int, t::Int; nw::Int=1)
    phi  = var(pm, :phi, nw)[i]
    bus_shunts = topology(pm, :bus_shunts)[i]
    bus_gs = Float32.([field(system, :shunts, :gs)[k] for k in bus_shunts])
    bus_bs = Float32.([field(system, :shunts, :bs)[k] for k in bus_shunts])
    JuMP.set_normalized_rhs(con(pm, :power_balance_p, nw)[i], -sum(gs for gs in bus_gs)*(1.0))
    JuMP.set_normalized_rhs(con(pm, :power_balance_q, nw)[i], +sum(bs for bs in bus_bs)*(1.0))
    JuMP.set_normalized_coefficient(con(pm, :power_balance_p, nw)[i], phi, sum(gs for gs in bus_gs)*2)
    JuMP.set_normalized_coefficient(con(pm, :power_balance_q, nw)[i], phi, -sum(bs for bs in bus_bs)*2)
end

""
function update_shunts!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    if !check_availability(field(states, :shunts), t, t-1)
        @inbounds @views for i in field(system, :buses, :keys)
            update_con_power_balance_shunts(pm, system, states, i, t)
        end
    end
end

""
function _con_thermal_limit_from(pm::AbstractAPLossLessModels, n::Int, l::Int, f_idx, rate_a)

    p_fr = var(pm, :p, n)[f_idx]
    if JuMP.has_lower_bound(p_fr)
        JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)
        if JuMP.has_upper_bound(p_fr)
            JuMP.upper_bound(p_fr) > rate_a && JuMP.set_upper_bound(p_fr, rate_a)
        end
    else
    con(pm, :thermal_limit_from, n)[l] = @constraint(pm.model, p_fr <= rate_a)
    end
end

""
function _con_thermal_limit_to(pm::AbstractAPLossLessModels, n::Int, l::Int, t_idx, rate_a)

    p_to = var(pm, :p, n)[t_idx]
    if JuMP.has_lower_bound(p_to)
        JuMP.lower_bound(p_to) < -rate_a && JuMP.set_lower_bound(p_to, -rate_a)
        if JuMP.has_upper_bound(p_to)
            JuMP.upper_bound(p_to) >  rate_a && JuMP.set_upper_bound(p_to,  rate_a)
        end
    else
        con(pm, :thermal_limit_to, n)[l] = @constraint(pm.model, p_to <= rate_a)
    end
end

""
function update_con_thermal_limits(pm::AbstractAPLossLessModels, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)

    f_bus = field(system, :branches, :f_bus)[l] 
    t_bus = field(system, :branches, :t_bus)[l]
    rate_a = field(system, :branches, :rate_a)[l]
    f_idx = (l, f_bus, t_bus)
    t_idx = (l, t_bus, f_bus)
    p_fr = var(pm, :p, nw)[f_idx]
    p_to = var(pm, :p, nw)[t_idx]

    if JuMP.has_lower_bound(p_fr)
        JuMP.set_lower_bound(p_fr, (-field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
        if JuMP.has_upper_bound(p_fr) JuMP.set_upper_bound(p_fr, (field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t]) end
    else
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, nw)[l], (field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
    end

    if JuMP.has_lower_bound(p_to)
        JuMP.set_lower_bound(p_to, (-field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
        if JuMP.has_upper_bound(p_to) JuMP.set_upper_bound(p_to, (field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t]) end
    else
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, nw)[l], (field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
    end
end

"DC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractDCPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    #con(pm, :ohms_yt_from_p, nw)[i] = @constraint(pm.model, p_fr == -b*(va_fr - va_to))

    if b <= 0
        con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= -b*(va_fr - va_to))
        con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= -b*(va_fr - va_to))    
    else # account for bound reversal when b is positive
        con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= -b*(va_fr - va_to))
        con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= -b*(va_fr - va_to)) 
    end

end

"DC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractDCMPPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    # get b only based on br_x (b = -1 / br_x) and take tap + shift into account
    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr <= (va_fr - va_to - ta) / (x*tm))
    con(pm, :ohms_yt_from_lower_p, nw)[l] = @constraint(pm.model, p_fr >= (va_fr - va_to - ta) / (x*tm)) 

end

"DC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractDCPModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]

    if field(states, :branches)[l,t] == false
        if b <= 0
            JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], vad_max)
            JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], vad_min)
        else # account for bound reversal when b is positive
            JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], vad_min)
            JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], vad_max)
        end
    else
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], 0.0)
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], 0.0)
    end

end

"DC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractDCMPPModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]

    if field(states, :branches)[l,t] == false
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], (-ta + vad_max)/(x*tm))
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], (-ta + vad_min)/(x*tm))
    else
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], -ta/(x*tm))
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], -ta/(x*tm))
    end
end

""
function _con_thermal_limit_from(pm::AbstractAPLossLessModels, n::Int, l::Int, f_idx, rate_a)
    p_fr = var(pm, :p, n)[f_idx]
    con(pm, :thermal_limit_from, n)[l] = @constraint(pm.model, p_fr <= rate_a)
    #con(pm, :thermal_limit_from_upper, n)[l] = @constraint(pm.model, p_fr <= rate_a)
    #con(pm, :thermal_limit_from_lower, n)[l] = @constraint(pm.model, p_fr >= -rate_a)
end

""
function _con_thermal_limit_to(pm::AbstractAPLossLessModels, n::Int, l::Int, t_idx, rate_a)
    p_to = var(pm, :p, n)[t_idx]
    con(pm, :thermal_limit_to, n)[l] = @constraint(pm.model, p_to <= rate_a)
    #con(pm, :thermal_limit_to_upper, n)[l] = @constraint(pm.model, p_to <= rate_a)
    #con(pm, :thermal_limit_to_lower, n)[l] = @constraint(pm.model, p_to >= -rate_a)
end

""
function update_con_thermal_limits(pm::AbstractAPLossLessModels, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)
    JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, nw)[l], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, nw)[l], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    #JuMP.set_normalized_rhs(con(pm, :thermal_limit_from_upper, nw)[l], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    #JuMP.set_normalized_rhs(con(pm, :thermal_limit_from_lower, nw)[l], (-field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
    #JuMP.set_normalized_rhs(con(pm, :thermal_limit_to_upper, nw)[l], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
    #JuMP.set_normalized_rhs(con(pm, :thermal_limit_to_lower, nw)[l], (-field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
end

""
function _con_thermal_limit_to(pm::AbstractAPLossLessModels, n::Int, l::Int, t_idx, rate_a)

    p_to = var(pm, :p, n)[t_idx]
    if isa(p_to, JuMP.VariableRef) && JuMP.has_lower_bound(p_to)
        JuMP.lower_bound(p_to) < -rate_a && JuMP.set_lower_bound(p_to, -rate_a)
        if JuMP.has_upper_bound(p_to)
            JuMP.upper_bound(p_to) >  rate_a && JuMP.set_upper_bound(p_to,  rate_a)
        end
    else
        println("hello")
        con(pm, :thermal_limit_to, n)[l] = @constraint(pm.model, p_to <= rate_a)
    end
end

""
function update_con_thermal_limits(pm::AbstractAPLossLessModels, system::SystemModel, states::SystemStates, l::Int, t::Int; nw::Int=1)

    f_bus = field(system, :branches, :f_bus)[l] 
    t_bus = field(system, :branches, :t_bus)[l]
    rate_a = field(system, :branches, :rate_a)[l]
    f_idx = (l, f_bus, t_bus)
    t_idx = (l, t_bus, f_bus)
    p_fr = var(pm, :p, nw)[f_idx]
    p_to = var(pm, :p, nw)[t_idx]

    if JuMP.has_lower_bound(p_fr)
        JuMP.set_lower_bound(p_fr, (-field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
        if JuMP.has_upper_bound(p_fr) JuMP.set_upper_bound(p_fr, (field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t]) end
    else
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, nw)[l], (field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
    end

    if JuMP.has_lower_bound(p_to)
        JuMP.set_lower_bound(p_to, (-field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
        if JuMP.has_upper_bound(p_to) JuMP.set_upper_bound(p_to, (field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t]) end
    else
        JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, nw)[l], (field(system, :branches, :rate_a)[l])*field(states, :branches)[l,t])
    end
end

function _con_thermal_limit_from(pm::AbstractAPLossLessModels, n::Int, l::Int, f_idx, rate_a)

    p_fr = var(pm, :p, n)[f_idx]
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
        JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)
        if JuMP.has_upper_bound(p_fr)
            JuMP.upper_bound(p_fr) > rate_a && JuMP.set_upper_bound(p_fr, rate_a)
        end

        con(pm, :thermal_limit_from, n)[l] = JuMP.UpperBoundRef(p_fr)

    else
    con(pm, :thermal_limit_from, n)[l] = @constraint(pm.model, p_fr <= rate_a)
    end

    con(pm, :thermal_limit_from, n)[l] = @constraint(pm.model, p_fr <= rate_a)


end

"Nothing to do, no voltage angle variables"
function con_ohms_yt(pm::AbstractNFAModel, system::SystemModel, i::Int; nw::Int=1)
end

"DC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractDCPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    con(pm, :ohms_yt_from_p, nw)[l] = @constraint(pm.model, p_fr == -b*(va_fr - va_to))
end

"DC Line Flow Constraints"
function _con_ohms_yt_from(pm::AbstractDCMPPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    # get b only based on br_x (b = -1 / br_x) and take tap + shift into account
    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    con(pm, :ohms_yt_from_p, nw)[l] = @constraint(pm.model, p_fr == (va_fr - va_to - ta) / (x*tm))
end

"Nothing to do, this model is symetric"
function _con_ohms_yt_to(pm::AbstractAPLossLessModels, i::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
end

"DC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractDCPModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]

    if field(states, :branches)[l,t] == false
        if b <= 0
            JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], vad_max)
            JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], vad_min)
        else # account for bound reversal when b is positive
            JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], vad_min)
            JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], vad_max)
        end
    else
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], 0.0)
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], 0.0)
    end

end


"DC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractDCMPPModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    vad_min = topology(pm, :delta_bounds)[1]
    vad_max = topology(pm, :delta_bounds)[2]

    if field(states, :branches)[l,t] == false
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], (-ta + vad_max)/(x*tm))
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], (-ta + vad_min)/(x*tm))
    else
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_upper_p, nw)[l], -ta/(x*tm))
        JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_lower_p, nw)[l], -ta/(x*tm))
    end
end


"DC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractDCPModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    vad = max(topology(pm, :delta_bounds)[1], topology(pm, :delta_bounds)[2])
    JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_p, nw)[l], 0.0*(1-field(states, :branches)[l,t]))
end

"DC Line Flow Constraints"
function _update_con_ohms_yt_from(pm::AbstractDCMPPModel, states::SystemStates, l::Int, t::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    vad = max(topology(pm, :delta_bounds)[1], topology(pm, :delta_bounds)[2])
    JuMP.set_normalized_rhs(con(pm, :ohms_yt_from_p, nw)[l], ((-ta + 0.0)/(x*tm))*(1-field(states, :branches)[l,t]))
end

function _con_ohms_yt_from_2(pm::AbstractDCPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    #con(pm, :ohms_yt_from_p, nw)[i] = @constraint(pm.model, p_fr == -b*(va_fr - va_to))
    con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr == -b*(va_fr - va_to))
end

"DC Line Flow Constraints"
function _con_ohms_yt_from_2(pm::AbstractDCMPPModel, l::Int, nw::Int, f_bus::Int, t_bus::Int, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    # get b only based on br_x (b = -1 / br_x) and take tap + shift into account
    p_fr  = var(pm, :p, nw)[l, f_bus, t_bus]
    x = -b / (g^2 + b^2)
    ta = atan(ti, tr)
    con(pm, :ohms_yt_from_upper_p, nw)[l] = @constraint(pm.model, p_fr == (va_fr - va_to - ta) / (x*tm))
end

""
function con_ohms_yt_2(pm::AbstractPowerModel, system::SystemModel, l::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[l]
    t_bus = field(system, :branches, :t_bus)[l]
    g, b = calc_branch_y(field(system, :branches), l)
    tr, ti = calc_branch_t(field(system, :branches), l)
    tm = field(system, :branches, :tap)[l]
    va_fr  = var(pm, :va, nw)[f_bus]
    va_to  = var(pm, :va, nw)[t_bus]
    g_fr = field(system, :branches, :g_fr)[l]
    b_fr = field(system, :branches, :b_fr)[l]
    g_to = field(system, :branches, :g_to)[l]
    b_to = field(system, :branches, :b_to)[l]

    _con_ohms_yt_from_2(pm, l, nw, f_bus, t_bus, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)
    _con_ohms_yt_to(pm, l, nw, f_bus, t_bus, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
end

""
function var_bus_voltage(pm::AbstractLPACModel, system::SystemModel; kwargs...)
    var_bus_voltage_angle(pm, system; kwargs...)
    var_bus_voltage_magnitude(pm, system; kwargs...)
    var_buspair_cosine(pm, system; kwargs...)
end

""
function var_buspair_cosine(pm::AbstractLPACModel, system::SystemModel; nw::Int=1, bounded::Bool=true)

    buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
    cs = var(pm, :cs)[nw] = @variable(pm.model, cs[buspairs], start=1.0)

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


@testset "test OPF, frankenstein_00 system" begin

    rawfile = "test/data/others/frankenstein_00.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "DC-OPF with NFAPowerModel, frankenstein_00" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        PowerModels.simplify_network!(data)
        result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, juniper_optimizer_2)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(key_buses)
            @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)


    end

    @testset "DC-OPF with DCPPowerModel, frankenstein_00" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "DC-OPF with DCMPPowerModel, frankenstein_00" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "AC-OPF with LPACCPowerModel, frankenstein_00" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-4)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-4)

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

end





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



























"NOT TESTED"
@testset "test OPF, RTS system, LPACCPowerModel, outages" begin

    rawfile = "test/data/RTS/Base/RTS.m"
    system = BaseModule.SystemModel(rawfile)
    settings = CompositeSystems.Settings(juniper_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
    states = CompositeAdequacy.SystemStates(system, available=true)
    pm = OPF.solve_opf(system, settings)

    #OUTAGE BRANCH 1
    states.branches[1] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["1"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)

    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #1" begin
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 25 - 26
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[25] = 0
    states.branches[26] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["25"]["br_status"] = 0
    data["branch"]["26"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #25 and #26" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 14 - 16
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[14] = 0
    states.branches[16] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["14"]["br_status"] = 0
    data["branch"]["16"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)

    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #14 and #16" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 6
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[6] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["6"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #6" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #NO OUTAGE
    states = CompositeAdequacy.SystemStates(system, available=true)
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, no outage" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 3
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[3] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["3"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 3" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 2
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[2] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["2"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 2" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 33
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[33] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["33"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 7" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 4
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[4] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["4"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 4" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 5
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[5] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["5"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 5" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 8
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[8] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["8"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 8" begin

        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH 9
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[9] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["9"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 9" begin
        
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #NO OUTAGE
    states = CompositeAdequacy.SystemStates(system, available=true)
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, no outage" begin
        
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH #1 AND #6
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[1] = 0
    states.branches[6] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["1"]["br_status"] = 0
    data["branch"]["6"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #1 and #6" begin
        
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH #20
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[20] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["20"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #20" begin
        
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH #12
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[12] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["12"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #12" begin
        
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH #7
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[7] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["7"]["br_status"] = 0
    data["bus"]["24"]["bus_type"] = 4
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #7" begin
        
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

    #OUTAGE BRANCH #7 and #27
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[7] = 0
    states.branches[27] = 0
    OPF._update_opf!(pm, system, states, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["7"]["br_status"] = 0
    data["branch"]["27"]["br_status"] = 0
    data["bus"]["24"]["bus_type"] = 4
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #7 and #27" begin
        
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, juniper_optimizer_1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_1)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
            @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
            @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
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
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
    end

end
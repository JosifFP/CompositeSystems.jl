"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
"""

"Transportation"
function build_method!(pm::AbstractNFAModel, system::SystemModel, t::Int; nw::Int=0)
 
    var_gen_power(pm, system, nw=nw)
    var_branch_power(pm, system, nw=nw)
    var_load_curtailment(pm, system, t, nw=nw)

    # Add Constraints
    # ---------------
    for i in assetgrouplist(topology(pm, :buses_idxs))
        constraint_power_balance(pm, system, i, t, nw=nw)
    end

    #for i in assetgrouplist(topology(pm, :branches_idxs))
    #    constraint_thermal_limits(pm, system, i, t)
    #end

    objective_min_load_curtailment(pm, system, nw=nw)
    return

end

"Load Minimization version of DCOPF"
function build_method!(pm::Union{AbstractDCMPPModel, AbstractDCPModel}, system::SystemModel, t::Int; nw::Int=0)
    # Add Optimization and State Variables
    var_bus_voltage(pm, system, nw=nw)
    var_gen_power(pm, system, nw=nw)
    var_branch_power(pm, system, nw=nw)
    var_load_curtailment(pm, system, t, nw=nw)
    #variable_storage_power_mi(pm)
    #var_dcline_power(pm)

    # Add Constraints
    # ---------------
    for i in field(system, :ref_buses)
        constraint_theta_ref(pm, i, nw=nw)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        constraint_power_balance(pm, system, i, t, nw=nw)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        constraint_ohms_yt(pm, system, i, nw=nw)
        constraint_voltage_angle_diff(pm, system, i, nw=nw)
        #constraint_thermal_limits(pm, system, i, t)
    end

    # for i in ids(pm, :dcline)
    #     constraint_dcline_power_losses(pm, i)
    # end
    objective_min_load_curtailment(pm, system, nw=nw)
    return

end

""
function build_opf!(pm::PM_AbstractDCPModel, system::SystemModel, t::Int; nw::Int=0)
    # Add Optimization and State Variables
    var_bus_voltage(pm, system, nw=nw)
    var_gen_power(pm, system, nw=nw)
    var_branch_power(pm, system, nw=nw)
    #variable_storage_power_mi(pm)
    #var_dcline_power(pm)

    # Add Constraints
    # ---------------
    for i in field(system, :ref_buses)
        constraint_theta_ref(pm, i, nw=nw)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        constraint_power_balance(pm, system, i, t, nw=nw)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        constraint_ohms_yt(pm, system, i, nw=nw)
        constraint_voltage_angle_diff(pm, system, i, nw=nw)
        #constraint_thermal_limits(pm, system, i, t)
    end

    # for i in ids(pm, :dcline)
    #     constraint_dcline_power_losses(pm, i)
    # end
    #objective_min_cost(pm, system, nw=nw)
    objective_min_fuel_and_flow_cost(pm, system, nw=nw)
    return

end

""
function objective_min_fuel_and_flow_cost(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=0)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    for i in system.generators.keys
        cost = reverse(system.generators.cost[i])
        pg = var(pm, :pg, nw)[i]
        if length(cost) == 1
            gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1])
        elseif length(cost) == 2
            gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1] + cost[2]*pg)
        elseif length(cost) == 3
            gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1] + cost[2]*pg + cost[3]*pg^2)
        else
            gen_cost[i] = JuMP.@NLexpression(pm.model, 0.0)
        end
    end

    return JuMP.@NLobjective(pm.model, Min, sum(gen_cost[i] for i in eachindex(gen_idxs)))
    
end


""
function objective_min_load_curtailment(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=0)

    # gen_cost = Dict{Int, Any}()
    # gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    # for i in system.generators.keys
    #     cost = reverse(system.generators.cost[i])
    #     gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1] + cost[2]*var(pm, :pg, nw)[i])
    # end

    # fg = JuMP.@NLexpression(pm.model, sum(gen_cost[i] for i in eachindex(gen_idxs)))

    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in assetgrouplist(topology(pm, :loads_idxs))))

    return @objective(pm.model, Min, fd)
    
end

# index representing which side the HVDC line is starting
#from_idx = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])
#lc = @expression(pm.model, #sum(gen["cost"][1]*model[:pg][i]^2 + gen["cost"][2]*model[:pg][i] + gen["cost"][3] for (i,gen) in ref[:gen]) +
#sum(dcline["cost"][1]*model[:p_dc][from_idx[i]]^2 + dcline["cost"][2]*model[:p_dc][from_idx[i]] + dcline["cost"][3] for (i,dcline) in ref[:dcline]) +
#sum(ref[:load][i]["cost"]*model[:plc][i] for i in keys(ref[:load]))
#sum(pm.ref[:load][i]["cost"]*pm.model[:plc][i] for i in keys(pm.ref[:load])))
# Objective Function: minimize load curtailment

# ""
# function optimization!(pm::AbstractPowerModel, type::Type)
    
#     #JuMP.set_time_limit_sec(pm.model, 2.0)
#     JuMP.optimize!(pm.model)

#     # if JuMP.termination_status(pm.model) ≠ JuMP.LOCALLY_SOLVED && type == DCOPF
#     #     JuMP.set_time_limit_sec(pm.model, 2.0)
#     #     var_buspair_current_magnitude_sqr(pm)
#     #     var_bus_voltage_magnitude_sqr(pm)
#     #     for i in ids(pm, :branch)
#     #         constraint_voltage_magnitude_diff(pm, i)
#     #     end
#     #     JuMP.optimize!(pm.model)
#     # end
    
#     return

# end
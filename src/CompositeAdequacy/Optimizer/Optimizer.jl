"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
"""
# function build_method!(pm::AbstractDCPowerModel; nw::Int=0)
#     type = ext(pm, nw, :type)
#     return  build_method!(pm; nw, type=type)
# end

"Transportation"
function build_method!(pm::AbstractDCPowerModel, type::Type{Transportation}; nw::Int=0)
 
    var_gen_power(pm, nw=nw)
    var_branch_power(pm, nw=nw)
    var_dcline_power(pm, nw=nw)
    var_load_curtailment(pm, nw=nw)

    # Add Constraints
    # ---------------
    for i in ids(pm, :bus, nw=nw)
        constraint_power_balance(pm, i, nw=nw)
    end

    for i in ids(pm, :branch, nw=nw)
        constraint_thermal_limit_from(pm, i, nw=nw)
        constraint_thermal_limit_to(pm, i, nw=nw)
    end

    for i in ids(pm, :dcline, nw=nw)
        constraint_dcline_power_losses(pm, i, nw=nw)
    end

    objective_min_load_curtailment(pm, nw=nw)

    return

end

"DCMPPowerModel"
function build_method!(pm::AbstractDCPowerModel, type::Type{DCMPPowerModel}; nw::Int=0)
    # Add Optimization and State Variables
    var_bus_voltage(pm, nw=nw)
    var_gen_power(pm, nw=nw)
    #variable_storage_power_mi(pm, nw=n)
    var_branch_power(pm, nw=nw)
    var_dcline_power(pm, nw=nw)

    # Add Constraints
    # ---------------
    for i in ids(pm, :ref_buses, nw=nw)
        constraint_theta_ref(pm, i, nw=nw)
    end

    for i in ids(pm, :bus, nw=nw)
        constraint_power_balance(pm, i, nw=nw)
    end

    for i in ids(pm, :branch, nw=nw)
        constraint_ohms_yt_from(pm, i, nw=nw)
        #constraint_ohms_yt_to(pm, i, nw=n)

        constraint_voltage_angle_difference(pm, i, nw=nw)

        constraint_thermal_limit_from(pm, i, nw=nw)
        constraint_thermal_limit_to(pm, i, nw=nw)
    end

    for i in ids(pm, :dcline, nw=nw)
        constraint_dcline_power_losses(pm, i, nw=nw)
    end

    return

end

"Load Minimization version of DCOPF"
function build_method!(pm::AbstractDCPowerModel, type::Type{DCOPF}; nw::Int=0)
    # Add Optimization and State Variables
    var_bus_voltage(pm, nw=nw)
    var_gen_power(pm, nw=nw)
    #variable_storage_power_mi(pm, nw=n)
    var_branch_power(pm, nw=nw)
    var_dcline_power(pm, nw=nw)
    var_load_curtailment(pm, nw=nw)

    # Add Constraints
    # ---------------
    for i in ids(pm, :ref_buses, nw=nw)
        constraint_theta_ref(pm, i, nw=nw)
    end

    for i in ids(pm, :bus, nw=nw)
        constraint_power_balance(pm, i, nw=nw)
    end

    #for i in ids(pm, :storage, nw=n)
    #    constraint_storage_complementarity_mi(pm, i, nw=n)
    #    constraint_storage_losses(pm, i, nw=n)
    #    constraint_storage_thermal_limit(pm, i, nw=n)
    #end

    for i in ids(pm, :branch, nw=nw)
        constraint_ohms_yt_from(pm, i, nw=nw)
        constraint_ohms_yt_to(pm, i, nw=nw)

        constraint_voltage_angle_difference(pm, i, nw=nw)

        constraint_thermal_limit_from(pm, i, nw=nw)
        constraint_thermal_limit_to(pm, i, nw=nw)
    end

    for i in ids(pm, :dcline, nw=nw)
        constraint_dcline_power_losses(pm, i, nw=nw)
    end

    objective_min_load_curtailment(pm, nw=nw)

    return

end

# index representing which side the HVDC line is starting
#from_idx = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])
#lc = JuMP.@expression(pm.model, #sum(gen["cost"][1]*model[:pg][i]^2 + gen["cost"][2]*model[:pg][i] + gen["cost"][3] for (i,gen) in ref[:gen]) +
#sum(dcline["cost"][1]*model[:p_dc][from_idx[i]]^2 + dcline["cost"][2]*model[:p_dc][from_idx[i]] + dcline["cost"][3] for (i,dcline) in ref[:dcline]) +
#sum(ref[:load][i]["cost"]*model[:plc][i] for i in keys(ref[:load]))
#sum(pm.ref[:load][i]["cost"]*pm.model[:plc][i] for i in keys(pm.ref[:load])))
# Objective Function: minimize load curtailment

""
function optimization!(pm::AbstractPowerModel, type::Type; nw::Int=0)
    
    JuMP.set_time_limit_sec(pm.model, 2.0)
    JuMP.optimize!(pm.model)

    if JuMP.termination_status(pm.model) ≠ JuMP.LOCALLY_SOLVED && type == DCOPF
        JuMP.set_time_limit_sec(pm.model, 2.0)
        var_buspair_current_magnitude_sqr(pm, nw=nw)
        var_bus_voltage_magnitude_sqr(pm, nw=nw)
        for i in ids(pm, :branch)
            constraint_voltage_magnitude_diff(pm, i, nw=nw)
        end
        JuMP.optimize!(pm.model)
    end
    
    return pm

end

function objective_min_load_curtailment(pm::AbstractDCPowerModel; nw::Int=0)

    load_cost = Dict()
    for (i,load) in ref(pm, nw, :load)
        p_lc = CompositeAdequacy.var(pm, nw, :p_lc, i)
        load_cost[i] = load["cost"]*p_lc
    end


    return JuMP.@objective(pm.model, Min,
        sum(load_cost[i] for (i,load) in ref(pm, nw, :load))
    )
end

function _objective_min_load_curtailment(pm)

    load_cost = Dict()
    for (n, nw_ref) in CompositeAdequacy.nws(pm)
        for (i,load) in nw_ref[:load]
            p_lc = CompositeAdequacy.var(pm, n, :p_lc, i)
            load_cost[(n,i)] = load["cost"]*p_lc
        end
    end

    return JuMP.@objective(pm.model, Min,
        sum(
            sum( load_cost[(n,i)] for (i,load) in nw_ref[:load] )
        for (n, nw_ref) in CompositeAdequacy.nws(pm))
    )
end
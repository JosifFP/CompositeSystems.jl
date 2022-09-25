"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
"""
function build_method!(pm::AbstractPowerModel; nw::Int=0)
    type = ext(pm, nw, :type)
    return build_mn_lmopf!(pm; nw, type)
end

""
function build_mn_lmopf!(pm::AbstractPowerModel; n::Int, type::Type)
    # Add Optimization and State Variables
    var_bus_voltage(pm, nw=n)
    var_gen_power(pm, nw=n)
    #variable_storage_power_mi(pm, nw=n)
    var_branch_power(pm, nw=n)
    var_dcline_power(pm, nw=n)
    #constraint_model_voltage(pm, nw=n)

    # Add Constraints
    # ---------------
    for i in ids(pm, :ref_buses, nw=n)
        constraint_theta_ref(pm, i, nw=n)
    end

    if type == LMOPFMethod

        var_load_curtailment(pm,nw)
    
        lc = JuMP.@expression(pm.model, sum(pm.ref[:load][i]["cost"]*pm.model[:p_lc][i] for i in keys(pm.ref[:load])))
        JuMP.@objective(pm.model, Min, lc)

    end

    constraint_nodal_power_balance(pm, type)
    constraint_branch_pf_limits(pm)
    constraint_hvdc_line(pm)

    return pm

end

# index representing which side the HVDC line is starting
#from_idx = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])
#lc = JuMP.@expression(pm.model, #sum(gen["cost"][1]*model[:pg][i]^2 + gen["cost"][2]*model[:pg][i] + gen["cost"][3] for (i,gen) in ref[:gen]) +
#sum(dcline["cost"][1]*model[:p_dc][from_idx[i]]^2 + dcline["cost"][2]*model[:p_dc][from_idx[i]] + dcline["cost"][3] for (i,dcline) in ref[:dcline]) +
#sum(ref[:load][i]["cost"]*model[:plc][i] for i in keys(ref[:load]))
#sum(pm.ref[:load][i]["cost"]*pm.model[:plc][i] for i in keys(pm.ref[:load])))
# Objective Function: minimize load curtailment

""
function optimization!(pm::AbstractPowerModel, type::Type{OPFMethod})
    
    JuMP.set_time_limit_sec(pm.model, 1.5)
    JuMP.optimize!(pm.model)
    return pm
    
end

""
function optimization!(pm::AbstractPowerModel, type::Type{LMOPFMethod})
    
    JuMP.set_time_limit_sec(pm.model, 1.5)
    JuMP.optimize!(pm.model)

    if JuMP.termination_status(pm.model) ≠ JuMP.LOCALLY_SOLVED
        JuMP.set_time_limit_sec(pm.model, 2.0)
        var_buspair_current_magnitude_sqr(pm)
        var_bus_voltage_magnitude_sqr(pm)
        constraint_voltage_magnitude_diff(pm)
        JuMP.optimize!(pm.model)
    end
    
    return pm

end
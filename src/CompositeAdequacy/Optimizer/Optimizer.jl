
"Standard DC OPF"
function build_model!(pm::AbstractDCPModel)
    return build_model!(pm, pm.type)
end

function build_model!(pm::AbstractPowerModel, type::Type{OPFMethod})
    # Add Optimization and State Variables
    var_bus_voltage(pm; bounded=false)
    var_gen_power(pm)
    var_branch_power(pm)
    var_dcline_power(pm)

    # Add Constraints
    # ---------------
    constraint_theta_ref_bus(pm)
    constraint_nodal_power_balance(pm, type)
    constraint_branch_pf_limits(pm)
    constraint_hvdc_line(pm)

    return pm

end

"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (Min Load Curtailment) formulation of the given data and returns the JuMP model
"""
function build_model!(pm::AbstractPowerModel, type::Type{LMOPFMethod})
    # Add Optimization and State Variables

    var_bus_voltage(pm; bounded=false)
    var_gen_power(pm)
    var_branch_power(pm)
    var_load_curtailment(pm)
    var_dcline_power(pm)

    lc = JuMP.@expression(pm.model, sum(pm.ref[:load][i]["cost"]*pm.model[:plc][i] for i in keys(pm.ref[:load])))
    JuMP.@objective(pm.model, Min, lc)

    constraint_theta_ref_bus(pm)
    constraint_nodal_power_balance(pm, type)
    constraint_branch_pf_limits(pm)
    constraint_hvdc_line(pm)

    return pm.model
    # index representing which side the HVDC line is starting
    #from_idx = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])
    #lc = JuMP.@expression(pm.model, #sum(gen["cost"][1]*model[:pg][i]^2 + gen["cost"][2]*model[:pg][i] + gen["cost"][3] for (i,gen) in ref[:gen]) +
    #sum(dcline["cost"][1]*model[:p_dc][from_idx[i]]^2 + dcline["cost"][2]*model[:p_dc][from_idx[i]] + dcline["cost"][3] for (i,dcline) in ref[:dcline]) +
    #sum(ref[:load][i]["cost"]*model[:plc][i] for i in keys(ref[:load]))
    #sum(pm.ref[:load][i]["cost"]*pm.model[:plc][i] for i in keys(pm.ref[:load])))
    # Objective Function: minimize load curtailment

end

""
function optimization!(pm::AbstractDCPModel)
    optimization!(pm, pm.type)
end

function optimization!(pm::AbstractPowerModel, type::Type{OPFMethod})
    JuMP.set_time_limit_sec(pm.model, 1.5)

    if JuMP.mode(pm.model) ≠ JuMP.DIRECT && JuMP.backend(pm.model).optimizer === nothing
        Memento.error(_LOGGER, "No optimizer specified in `optimize_model!` or the given JuMP model.")
    end

    JuMP.optimize!(pm.model)
    return
    
end

""
function optimization!(pm::AbstractPowerModel, type::Type{LMOPFMethod})
    JuMP.set_time_limit_sec(pm.model, 1.5)

    if JuMP.mode(pm.model) ≠ JuMP.DIRECT && JuMP.backend(pm.model).optimizer === nothing
        Memento.error(_LOGGER, "No optimizer specified in `optimize_model!` or the given JuMP model.")
    end

    JuMP.optimize!(pm.model)

    if JuMP.termination_status(pm.model) ≠ JuMP.LOCALLY_SOLVED
        JuMP.set_time_limit_sec(pm.model, 2.0)
        var_buspair_current_magnitude_sqr(pm)
        var_bus_voltage_magnitude_sqr(pm)
        constraint_voltage_magnitude_diff(pm)
        JuMP.optimize!(pm.model)
    end
    
    return

end
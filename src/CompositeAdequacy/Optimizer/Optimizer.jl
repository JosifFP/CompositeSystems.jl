
"Standard DC OPF"
function build_model(pm::DCPPowerModel)
    # Add Optimization and State Variables
    var_bus_voltage(pm; bounded=false)
    var_gen_power(pm)
    var_branch_power(pm)
    var_dcline_power(pm)

    # Add Constraints
    # ---------------
    constraint_theta_ref_bus(pm)
    constraint_nodal_power_balance(pm)
    constraint_branch_pf_limits(pm)
    constraint_hvdc_line(pm)
end

"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (Min Load Curtailment) formulation of the given data and returns the JuMP model
"""

function build_model(pm::DCMLPowerModel)
    # Add Optimization and State Variables

    var_bus_voltage(pm; bounded=false)
    var_gen_power(pm)
    var_branch_power(pm)
    var_dcline_power(pm)
    var_load_curtailment(pm)

    # index representing which side the HVDC line is starting
    #from_idx = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])

    lc = JuMP.@expression(pm.model, #sum(gen["cost"][1]*model[:pg][i]^2 + gen["cost"][2]*model[:pg][i] + gen["cost"][3] for (i,gen) in ref[:gen]) +
    #sum(dcline["cost"][1]*model[:p_dc][from_idx[i]]^2 + dcline["cost"][2]*model[:p_dc][from_idx[i]] + dcline["cost"][3] for (i,dcline) in ref[:dcline]) +
    #sum(ref[:load][i]["cost"]*model[:plc][i] for i in keys(ref[:load]))
    sum(1000*pm.model[:plc][i] for i in keys(pm.ref[:load])))

    # Objective Function: minimize load curtailment
    @objective(pm.model, Min, lc)

    constraint_theta_ref_bus(pm)
    constraint_nodal_power_balance(pm)
    constraint_branch_pf_limits(pm)
    constraint_hvdc_line(pm)

end

""
function optimization(pm::AbstractPowerModel)
    
    #start_time = time()
    JuMP.set_time_limit_sec(pm.model, 3.0)

    if JuMP.mode(pm.model) != JuMP.DIRECT && JuMP.backend(pm.model).optimizer === nothing
        Memento.error(_LOGGER, "No optimizer specified in `optimize_model!` or the given JuMP model.")
    end
    
    JuMP.optimize!(pm.model)
    #solve_time = @timed JuMP.optimize!(pm.model)
    try
        solve_time = JuMP.solve_time(pm.model)
    catch
        Memento.warn(_LOGGER, "The given optimizer does not provide the SolveTime() attribute, falling back on @timed.  This is not a rigorous timing value.");
    end
    #Memento.debug(_LOGGER, "JuMP model optimize time: $(time() - start_time)")

    if JuMP.termination_status(pm.model) != JuMP.LOCALLY_SOLVED

        var_buspair_current_magnitude_sqr(pm)
        var_bus_voltage_magnitude_sqr(pm)
        constraint_voltage_magnitude_diff(pm)
        JuMP.optimize!(pm.model)
        #solve_time = solve_time + JuMP.solve_time(pm.model)
    end

    result = build_result(pm) 
    #start_time = time()
    #result = build_result(pm, solve_time)  
    #Memento.debug(_LOGGER, "solution build time: $(time() - start_time)")

    return result

end
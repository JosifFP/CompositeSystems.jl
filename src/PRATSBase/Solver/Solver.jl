
""
function OptimizationProblem(data::Dict{String, <:Any}, method::Type{dc_opf}, optimizer)

    ref =  get_ref(data)
    model = build_opf(ref, dc_opf, JuMP.Model(optimizer; add_bridges = false))
    result = optimization(data, ref, dc_opf, model)
    return result
    
end

""
function OptimizationProblem(data::Dict{String, <:Any}, method::Type{dc_opf_lc}, optimizer)

    ref =  get_ref(data)
    model = build_opf_lc(ref, dc_opf_lc, JuMP.Model(optimizer; add_bridges = false))
    result = optimization(data, ref, dc_opf_lc, model)
    return result
    
end

"Standard DC OPF"
function build_opf(ref::Dict{Symbol,Any}, method::Type{dc_opf}, model::Model)
    
    # Add Optimization and State Variables
    var_bus_voltage(ref, method, model)
    var_gen_power(ref, method, model)
    var_branch_power(ref, method, model)
    var_dcline_power(ref, method, model)

    # Add Constraints
    # ---------------
    constraint_theta_ref_bus(ref, model)
    constraint_nodal_power_balance(ref, method, model)
    constraint_branch_pf_limits(ref, method, model)
    constraint_hvdc_line(ref, model)
    return model

end

"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (Min Load Curtailment) formulation of the given data and returns the JuMP model
"""
function build_opf_lc(ref::Dict{Symbol,Any}, method::Type{dc_opf_lc}, model::Model)

    # Add Optimization and State Variables
    var_bus_voltage(ref, method, model)
    var_gen_power(ref, method, model)
    var_branch_power(ref, method, model)
    var_load_curtailment(ref, method, model)
    var_dcline_power(ref, method, model)

    # index representing which side the HVDC line is starting
    from_idx = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])

    lc = JuMP.@expression(model, #sum(gen["cost"][1]*model[:pg][i]^2 + gen["cost"][2]*model[:pg][i] + gen["cost"][3] for (i,gen) in ref[:gen]) +
    #sum(dcline["cost"][1]*model[:p_dc][from_idx[i]]^2 + dcline["cost"][2]*model[:p_dc][from_idx[i]] + dcline["cost"][3] for (i,dcline) in ref[:dcline]) +
    #sum(ref[:load][i]["cost"]*model[:plc][i] for i in keys(ref[:load]))
    sum(1000*model[:plc][i] for i in keys(ref[:load]))
    )

    # Objective Function: minimize load curtailment
    @objective(model, Min, lc)
    
    constraint_theta_ref_bus(ref, model)
    constraint_nodal_power_balance(ref, method, model)
    constraint_branch_pf_limits(ref, method, model)
    constraint_hvdc_line(ref, model)
    return model

end

""
function optimization(data::Dict{String, <:Any}, ref::Dict{Symbol,Any}, method, model::Model)
    
    opf_model = model
    start_time = time()

    if JuMP.mode(opf_model) != JuMP.DIRECT && JuMP.backend(opf_model).optimizer === nothing
        Memento.error(_LOGGER, "No optimizer specified in `optimize_model!` or the given JuMP model.")
    end

    solve_time = @timed JuMP.optimize!(opf_model)
    try
        solve_time = JuMP.solve_time(opf_model)
    catch
        Memento.warn(_LOGGER, "The given optimizer does not provide the SolveTime() attribute, falling back on @timed.  This is not a rigorous timing value.");
    end
    Memento.debug(_LOGGER, "JuMP model optimize time: $(time() - start_time)")

    if JuMP.termination_status(opf_model) != JuMP.LOCALLY_SOLVED

        var_buspair_current_magnitude_sqr(ref, model)
        var_bus_voltage_magnitude_sqr(ref, model)
        constraint_voltage_magnitude_diff(ref, model)
        JuMP.optimize!(model)
        solve_time = solve_time + JuMP.solve_time(model)
        start_time = time()
        result = build_result(data, ref, method, model, solve_time)          
    else
        start_time = time()
        result = build_result(data, ref, method, opf_model, solve_time)   
    end

    Memento.debug(_LOGGER, "solution build time: $(time() - start_time)")
    return result

end
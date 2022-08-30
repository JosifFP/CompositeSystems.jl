
""
function min_load(data::Dict{String, <:Any}, optimizer)
    
    ref =  get_ref(data)
    model = build_min_lc(ref, JuMP.Model(optimizer; add_bridges = false))
    result = optimization(data, ref, model)

    return result
end

"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (Min Load Curtailment) formulation of the given data and returns the JuMP model
"""
function build_min_lc(ref::Dict{Symbol,Any}, model::Model)
    return build_opf_lc(ref, dc_opf_lc, model)
end

""
function build_opf_lc(ref::Dict{Symbol,Any}, method::Type{dc_opf_lc}, model::Model)

    # Add Optimization and State Variables
    var_bus_voltage(ref, method, model)
    var_gen_power(ref, method, model)
    var_branch_power(ref, method, model)
    var_load_curtailment(ref, method, model)
    var_dcline_power(ref, method, model)

    #opf = JuMP.@expression(model, sum(0.001*gen["cost"][1]*model[:pg][i]^2 + 0.001*gen["cost"][2]*model[:pg][i] + 0.001*gen["cost"][3] for (i,gen) in ref[:gen]))
    lc = JuMP.@expression(model, sum(ref[:load][i]["cost"] *model[:plc][i] for i in keys(ref[:load])))

    # Objective Function: minimize load curtailment
    @objective(model, Min, lc)
    
    constraint_theta_ref_bus(ref, model)
    constraint_nodal_power_balance(ref, method, model)
    constraint_branch_pf_limits(ref, method, model)
    constraint_hvdc_line(ref, model)

    return model
end

""
function optimization(data::Dict{String, <:Any}, ref::Dict{Symbol,Any}, model::Model)
    
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
        result = build_result(data, ref, model, solve_time)          
    else
        start_time = time()
        result = build_result(data, ref, opf_model, solve_time)   
    end

    Memento.debug(_LOGGER, "solution build time: $(time() - start_time)")
    return result
end
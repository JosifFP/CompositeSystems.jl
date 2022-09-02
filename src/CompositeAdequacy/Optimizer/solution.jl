""
function build_result(pm)
    
    result_count = 1
    try
        result_count = JuMP.result_count(pm.model)
    catch
        Memento.warn(_LOGGER, "the given optimizer does not provide the ResultCount() attribute, assuming the solver returned a solution which may be incorrect.");
    end

    container = pm.solution

    if result_count > 0
        build_solution!(container, pm)
    else
        Memento.warn(_LOGGER, "model has no results, solution cannot be built")

        pm.solution = Dict{String,Any}(
            "optimizer" => JuMP.solver_name(pm.model),
            "termination_status" => JuMP.termination_status(pm.model),
            "primal_status" => JuMP.primal_status(pm.model),
            "dual_status" => JuMP.dual_status(pm.model),
            "objective" => guard_objective_value(pm.model),
            "objective_lb" => guard_objective_bound(pm.model)
        )
        println(pm.solution)
        return

    end

    pm.solution = Dict{String,Any}(
        "optimizer" => JuMP.solver_name(pm.model),
        "termination_status" => JuMP.termination_status(pm.model),
        #"primal_status" => JuMP.primal_status(pm.model),
        #"dual_status" => JuMP.dual_status(pm.model),
        #"objective" => guard_objective_value(pm.model),
        #"objective_lb" => guard_objective_bound(pm.model),
        #"solve_time" => solve_time,
                #"solution_details" => JuMP.solution_summary(pm.model, verbose=false),
        "solution" => container
    )
    
end

""
function guard_objective_value(opf_model)
    obj_val = NaN
    try
        obj_val = JuMP.objective_value(opf_model)
    catch
    end
    return obj_val
end

""
function guard_objective_bound(opf_model)
    obj_lb = -Inf
    try
        obj_lb = JuMP.objective_bound(opf_model)
    catch
    end
    return obj_lb
end

""
function build_solution!(solution::Dict{String,Any}, pm::AbstractDCPModel)
    
    solution["gen"] = get_gens_sol!(Dict{Int64,Dict{String,Float64}}(), pm)
    solution["bus"] = get_buses_sol!(Dict{Int64,Dict{String,Float64}}(), pm)
    solution["branch"] = get_branches_sol!(Dict{Int64,Dict{String,Float64}}(), pm)
    solution["load_initial"], 
    solution["load"], 
    solution["load_curtailment"] = get_loads_sol!(Dict{Int64,Dict{String,Float64}}(), pm)
    solution["total"]          = Dict(
        "total_Pg"                => sum([solution["gen"][i]["pg"] for i in keys(solution["gen"])]),
        "total_P_load_before"     => sum([solution["load_initial"][i]["pl"] for i in keys(solution["load_initial"])]),
        "total_P_load_after"      => sum([solution["load"][i]["pl"] for i in keys(solution["load"])]),
        "P_load_curtailed"        => sum([solution["load_curtailment"][i]["pl"] for i in keys(solution["load_curtailment"])]),
        "P_balance_mismatch"      => sum([solution["gen"][i]["pg"] for i in keys(solution["gen"])])-
                                     sum([solution["load"][i]["pl"] for i in keys(solution["load"])]))
    return solution
    
end

""
function get_loads_sol!(tmp, pm::DCPPowerModel)

    loads = Dict{Int64,Dict{String,Float64}}()
    curt_loads = Dict{Int64,Dict{String,Float64}}()

    for (i, load) in pm.ref[:load_initial]
        #initial load
        get!(tmp, i, Dict("ql" => 0.0, "pl" => Float16(load["pd"])))
        get!(loads, i, Dict("ql" => 0.0, "pl" => Float16(load["pd"])))
        get!(curt_loads, i, Dict("ql" => 0.0, "pl" => 0.0))
    end

    return tmp, loads, curt_loads
end

""
function get_loads_sol!(tmp, pm::DCMLPowerModel)

    loads = Dict{Int64,Dict{String,Float64}}()
    curt_loads = Dict{Int64,Dict{String,Float64}}()

    for (i, load) in pm.ref[:load_initial]
        #initial load
        get!(tmp, i, Dict("ql" => 0.0, "pl" => Float16(load["pd"])))
    end

    for (index, load) in pm.data_load
        i = parse(Int, index)
        if load["status"]!= 0
            if JuMP.value(pm.model[:plc][load["index"]])>1e-4          
                #actual load    
                get!(loads, i, Dict("ql"=>0.0, "pl"=> Float16(load["pd"]-JuMP.value(pm.model[:plc][load["index"]]))))
                #curtailed load         
                get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> Float16(JuMP.value(pm.model[:plc][load["index"]]))))
            else
                get!(loads, i, Dict("ql"=>0.0, "pl"=> Float16(load["pd"])))
                get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> 0.0))
            end
        else
            get!(loads, i, Dict("ql"=>0.0, "pl"=> 0.0))           
            get!(curt_loads, i, Dict("ql"=>0.0, "pl"=> Float16(load["pd"])))
        end
    end
    return tmp, loads, curt_loads
end

""
function get_buses_sol!(tmp, pm::AbstractDCPModel)

    for (i, bus) in pm.ref[:bus]
        if bus["bus_type"] != 4
            get!(tmp, i, Dict("va"=>Float16(JuMP.value(pm.model[:va][bus["index"]]))))
        end
    end
    return tmp
end

""
function get_gens_sol!(tmp, pm::AbstractDCPModel)

    for (i, gen) in pm.ref[:gen]
        if gen["gen_status"] != 0
            get!(tmp, i, Dict("qg"=>0.0, "pg"=>Float16(JuMP.value(pm.model[:pg][gen["index"]]))))
        end
    end
    return tmp
end

""
function get_branches_sol!(tmp, pm::AbstractDCPModel)

    for (i, branch) in pm.ref[:branch]
        if branch["br_status"]!= 0  
            get!(tmp, i, Dict("qf"=>0.0, "qt"=>0.0,        
            "pt" => float(-JuMP.value(pm.model[:p][(branch["index"],branch["f_bus"],branch["t_bus"])])),
            "pf" => float(JuMP.value(pm.model[:p][(branch["index"],branch["f_bus"],branch["t_bus"])])))
            )
        end
    end
    return tmp
end
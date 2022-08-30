""
function build_result(data::Dict{String, <:Any}, ref::Dict{Symbol,Any}, opf_model::Model, solve_time)
    
    result_count = 1
    try
        result_count = JuMP.result_count(opf_model)
    catch
        Memento.warn(_LOGGER, "the given optimizer does not provide the ResultCount() attribute, assuming the solver returned a solution which may be incorrect.");
    end

    solution = Dict{String,Any}()

    if result_count > 0
        solution = build_solution!(data::Dict{String, <:Any}, solution, ref, dc_opf_lc, opf_model)
    else
        Memento.warn(_LOGGER, "model has no results, solution cannot be built")
    end

    result = Dict{String,Any}(
        "optimizer" => JuMP.solver_name(opf_model),
        "termination_status" => JuMP.termination_status(opf_model),
        "primal_status" => JuMP.primal_status(opf_model),
        "dual_status" => JuMP.dual_status(opf_model),
        "objective" => guard_objective_value(opf_model),
        "objective_lb" => guard_objective_bound(opf_model),
        "solve_time" => solve_time,
        "solution" => solution,
        "solution_details" => JuMP.solution_summary(opf_model, verbose=false)
    )

    return result
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
function build_solution!(data::Dict{String, <:Any}, solution::Dict{String,Any}, ref::Dict{Symbol,Any}, method::Union{Type{dc_opf_lc}, Type{ac_opf_lc}}, opf_model::Model)

    solution["gen"] = get_gens_sol!(Dict{Int64,Dict{String,Float64}}(), ref, method, opf_model)
    solution["bus"] = get_buses_sol!(Dict{Int64,Dict{String,Float64}}(), ref, method, opf_model)
    solution["branch"] = get_branches_sol!(Dict{Int64,Dict{String,Float64}}(), ref, method, opf_model)
    solution["load_initial"], solution["load"], solution["load curtailment"]  = get_loads_sol!(Dict{Int64,Dict{String,Float64}}(), data, ref, method, opf_model)
    solution["total"] = get_total_sol(solution, method)
    return solution
end

""
function get_total_sol(solution::Dict{String,Any}, method::Type{dc_opf_lc})

    solution_total = Dict(
        "total_Pg"                => sum([solution["gen"][i]["pg"] for i in keys(solution["gen"])]),
        "total_P_load_before"     => sum([solution["load_initial"][i]["pl"] for i in keys(solution["load_initial"])]),
        "total_P_load_after"      => sum([solution["load"][i]["pl"] for i in keys(solution["load"])]),
        "P_load_curtailed"        => sum([solution["load curtailment"][i]["pl"] for i in keys(solution["load curtailment"])]),
        "P_balance mismatch"      => sum([solution["gen"][i]["pg"] for i in keys(solution["gen"])])-
                                     sum([solution["load"][i]["pl"] for i in keys(solution["load"])]))
    return solution_total
end

""
function get_loads_sol!(tmp, data::Dict{String, <:Any}, ref::Dict{Symbol,Any}, method::Type{dc_opf_lc},  opf_model::Model)

    loads = Dict{Int64,Dict{String,Float64}}()
    curt_loads = Dict{Int64,Dict{String,Float64}}()

    for (i, load) in ref[:load_initial]
        #initial load
        get!(tmp, i, Dict("ql" => 0.0, "pl" => ref[:baseMVA]*load["pd"]))
    end

    for (i, load) in data["load"]
        index = parse(Int, i)
        if load["status"]!= 0
            if JuMP.value(opf_model[:plc][load["index"]])>1e-4          
                #actual load    
                get!(loads, index, Dict("ql"=>0.0, "pl"=> ref[:baseMVA]*load["pd"]-ref[:baseMVA]*JuMP.value(opf_model[:plc][load["index"]])))
                #curtailed load         
                get!(curt_loads, index, Dict("ql"=>0.0, "pl"=> ref[:baseMVA]*JuMP.value(opf_model[:plc][load["index"]])))
            else
                get!(loads, index, Dict("ql"=>0.0, "pl"=> ref[:baseMVA]*load["pd"]))
                get!(curt_loads, index, Dict("ql"=>0.0, "pl"=> 0.0))
            end
        else
            get!(loads, index, Dict("ql"=>0.0, "pl"=> 0.0))           
            get!(curt_loads, index, Dict("ql"=>0.0, "pl"=> ref[:baseMVA]*load["pd"]))
        end
    end
    return tmp, loads, curt_loads
end

""
function get_buses_sol!(tmp, ref::Dict{Symbol,Any}, method::Union{Type{dc_opf}, Type{dc_opf_lc}}, opf_model::Model)

    for (i, bus) in ref[:bus]
        if bus["bus_type"] != 4
            get!(tmp, i, Dict("va"=>(180/pi)*JuMP.value(opf_model[:va][bus["index"]]), "vm"=>1.0))
        end
    end
    return tmp
end

""
function get_gens_sol!(tmp, ref::Dict{Symbol,Any}, method::Union{Type{dc_opf}, Type{dc_opf_lc}}, opf_model::Model)

    for (i, gen) in ref[:gen]
        if gen["gen_status"] != 0
            get!(tmp, i, Dict("qg"=>0.0, "pg"=>ref[:baseMVA]*JuMP.value(opf_model[:pg][gen["index"]])))
        end
    end
    return tmp
end

""
function get_branches_sol!(tmp, ref::Dict{Symbol,Any}, method::Union{Type{dc_opf}, Type{dc_opf_lc}}, opf_model::Model)

    for (i, branch) in ref[:branch]
        if branch["br_status"]!= 0  
            get!(tmp, i, Dict("qf"=>0.0, "qt"=>0.0,        
            "pt" => float(-ref[:baseMVA]*JuMP.value(opf_model[:p][(branch["index"],branch["f_bus"],branch["t_bus"])])),
            "pf" => float(ref[:baseMVA]*JuMP.value(opf_model[:p][(branch["index"],branch["f_bus"],branch["t_bus"])])))
            )
        end
    end
    return tmp
end
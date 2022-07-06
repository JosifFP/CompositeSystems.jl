
""
function get_ref(data::Network)
    network = conversion_to_pm_data(data)
    ref = ref_initialize!(network)
    ref_add!(ref)
    return ref
end

"Builds a ref object with dictionaries from PowerModels data"
function get_ref(data::Network, method::Type{})
    network = conversion_to_pm_data(data)
    ref = ref_initialize!(network)
    ref_add!(ref)
    get!(ref,:method, method)
    return ref
end

"Builds a ref object with dictionaries from PowerModels data"
function get_ref(data::Network, method::Type{}, load_curt_info::Union{Vector{Tuple{Int64, Float64, Float64}},Vector{}})
    network = conversion_to_pm_data(data)
    ref = ref_initialize!(network)
    ref_add!(ref)
    get_ref_n!(ref, load_curt_info)
    get!(ref,:method, method)
    return ref
end

"Add load curtailment information to ref()"
function get_ref_n!(ref::Dict{Symbol,Any}, load_curt_info::Vector{Tuple{Int64, Float64, Float64}})
    get!(ref,:load_curtailment, 
        Dict(l => Dict(
            "load_bus" => float(ref[:load][l]["load_bus"]), 
            "pmax" => float(load["pd"])*getfield(load_curt_info[l], 2), 
            "qmax" => float(load["qd"])*getfield(load_curt_info[l], 2), 
            "cost" => float(getfield(load_curt_info[l], 3)*100)) for (l, load) in ref[:load])
    )
end

function get_ref_n!(ref::Dict{Symbol,Any}, load_curt_info::Vector{})
    get!(ref,:load_curtailment, Dict(l => Dict(
        "load_bus" => float(ref[:load][l]["load_bus"]), 
        "pmax" => float(load["pd"]), 
        "qmax" => float(load["qd"]), 
        "cost" => float(1000)) for (l, load) in ref[:load])
)
end

function ref_add!(ref::Dict{Symbol,Any})

    ### filter out inactive components ###
    ref[:bus] = Dict(x for x in ref[:bus] if (x.second["bus_type"] != pm_component_status_inactive["bus"]))
    ref[:load] = Dict(x for x in ref[:load] if (x.second["status"] != pm_component_status_inactive["load"] && x.second["load_bus"] in keys(ref[:bus])))
    ref[:load_initial] = Dict(x for x in ref[:load] if (x.second["status"] != pm_component_status_inactive["load"] && x.second["load_bus"] in keys(ref[:bus])))
    ref[:shunt] = Dict(x for x in ref[:shunt] if (x.second["status"] != pm_component_status_inactive["shunt"] && x.second["shunt_bus"] in keys(ref[:bus])))
    ref[:gen] = Dict(x for x in ref[:gen] if (x.second["gen_status"] != pm_component_status_inactive["gen"] && x.second["gen_bus"] in keys(ref[:bus])))
    ref[:storage] = Dict(x for x in ref[:storage] if (x.second["status"] != pm_component_status_inactive["storage"] && x.second["storage_bus"] in keys(ref[:bus])))
    ref[:switch] = Dict(x for x in ref[:switch] if (x.second["status"] != pm_component_status_inactive["switch"] && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))
    ref[:branch] = Dict(x for x in ref[:branch] if (x.second["br_status"] != pm_component_status_inactive["branch"] && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))
    ref[:dcline] = Dict(x for x in ref[:dcline] if (x.second["br_status"] != pm_component_status_inactive["dcline"] && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))

    ### setup arcs from edges ###
    ref[:arcs_from] = [(i,branch["f_bus"],branch["t_bus"]) for (i,branch) in ref[:branch]]
    ref[:arcs_to]   = [(i,branch["t_bus"],branch["f_bus"]) for (i,branch) in ref[:branch]]
    ref[:arcs] = [ref[:arcs_from]; ref[:arcs_to]]

    ref[:arcs_from_dc] = [(i,dcline["f_bus"],dcline["t_bus"]) for (i,dcline) in ref[:dcline]]
    ref[:arcs_to_dc]   = [(i,dcline["t_bus"],dcline["f_bus"]) for (i,dcline) in ref[:dcline]]
    ref[:arcs_dc]      = [ref[:arcs_from_dc]; ref[:arcs_to_dc]]

    ref[:arcs_from_sw] = [(i,switch["f_bus"],switch["t_bus"]) for (i,switch) in ref[:switch]]
    ref[:arcs_to_sw]   = [(i,switch["t_bus"],switch["f_bus"]) for (i,switch) in ref[:switch]]
    ref[:arcs_sw] = [ref[:arcs_from_sw]; ref[:arcs_to_sw]]

    tmp = Dict{Int64, Vector{Int64}}

    ### bus connected component lookups ###
    tmp = Dict((i, Int[]) for (i,bus) in ref[:bus])
    for (i, load) in ref[:load]
        push!(tmp[load["load_bus"]], i)
    end
    ref[:bus_loads] = tmp

    tmp = Dict((i, Int[]) for (i,bus) in ref[:bus])
    for (i,shunt) in ref[:shunt]
        push!(tmp[shunt["shunt_bus"]], i)
    end
    ref[:bus_shunts] = tmp

    tmp = Dict((i, Int[]) for (i,bus) in ref[:bus])
    for (i,gen) in ref[:gen]
        push!(tmp[gen["gen_bus"]], i)
    end
    ref[:bus_gens] = tmp

    tmp = Dict((i, Int[]) for (i,bus) in ref[:bus])
    for (i,strg) in ref[:storage]
        push!(tmp[strg["storage_bus"]], i)
    end
    ref[:bus_storage] = tmp

    tmp = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in ref[:bus])
    for (l,i,j) in ref[:arcs]
        push!(tmp[i], (l,i,j))
    end
    ref[:bus_arcs] = tmp

    tmp = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in ref[:bus])
    for (l,i,j) in ref[:arcs_dc]
        push!(tmp[i], (l,i,j))
    end
    ref[:bus_arcs_dc] = tmp

    tmp = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in ref[:bus])
    for (l,i,j) in ref[:arcs_sw]
        push!(tmp[i], (l,i,j))
    end
    ref[:bus_arcs_sw] = tmp

    tmp = Dict{Int64, Vector{Int64}}

    ### reference bus lookup (a set to support multiple connected components) ###
    ref_buses = Dict{Int,Any}()
    for (k,v) in ref[:bus]
        if v["bus_type"] == 3
            ref_buses[k] = v
        end
    end

    ref[:ref_buses] = ref_buses

    if length(ref_buses) > 1
        Memento.warn(_LOGGER, "multiple reference buses found, $(keys(ref_buses)), this can cause infeasibility if they are in the same connected component")
    end

    ref[:buspairs] = calc_buspair_parameters(ref[:bus], ref[:branch])

end

function ref_initialize!(data::Dict{String, <:Any})
    # Initialize the refs dictionary.
    refs = Dict{Symbol, Any}()
    for (key,item) in data
        if isa(item, Dict{String, Any})
            refs[Symbol(key)] = Dict{Int, Any}([(parse(Int, k), v) for (k, v) in item])
        else
            refs[Symbol(key)] = item
        end        
    end
    # Return the final refs object.
    return refs
end


"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses, branches)

    bus_lookup = Dict(bus["index"] => bus for (i,bus) in buses if bus["bus_type"] != 4)
    branch_lookup = Dict(branch["index"] => branch for (i,branch) in branches if branch["br_status"] == 1 
    && haskey(bus_lookup, branch["f_bus"]) && haskey(bus_lookup, branch["t_bus"]))

    buspair_indexes = Set((branch["f_bus"], branch["t_bus"]) for (i,branch) in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)

    for (l,branch) in branch_lookup
        bp_angmin[(branch["f_bus"],branch["t_bus"])] = max(bp_angmin[(branch["f_bus"],branch["t_bus"])], branch["angmin"])
        bp_angmax[(branch["f_bus"],branch["t_bus"])] = min(bp_angmax[(branch["f_bus"],branch["t_bus"])], branch["angmax"])
        bp_branch[(branch["f_bus"],branch["t_bus"])] = min(bp_branch[(branch["f_bus"],branch["t_bus"])], l)
    end

    buspairs = Dict((i,j) => Dict(
        "branch"=>bp_branch[(i,j)],
        "angmin"=>bp_angmin[(i,j)],
        "angmax"=>bp_angmax[(i,j)],
        "tap"=>branch_lookup[bp_branch[(i,j)]]["tap"],
        "vm_fr_min"=>bus_lookup[i]["vmin"],
        "vm_fr_max"=>bus_lookup[i]["vmax"],
        "vm_to_min"=>bus_lookup[j]["vmin"],
        "vm_to_max"=>bus_lookup[j]["vmax"]
        ) for (i,j) in buspair_indexes
    )

    # add optional parameters
    for bp in buspair_indexes
        branch = branch_lookup[bp_branch[bp]]
        if haskey(branch, "rate_a")
            buspairs[bp]["rate_a"] = branch["rate_a"]
        end
        if haskey(branch, "c_rating_a")
            buspairs[bp]["c_rating_a"] = branch["c_rating_a"]
        end
    end

    return buspairs
end


"computes voltage product bounds from ref data"
function calc_voltage_product_bounds(buspairs)
    wr_min = Dict((bp, -Inf) for bp in keys(buspairs))
    wr_max = Dict((bp,  Inf) for bp in keys(buspairs))
    wi_min = Dict((bp, -Inf) for bp in keys(buspairs))
    wi_max = Dict((bp,  Inf) for bp in keys(buspairs))

    buspairs_conductor = Dict()
    for (bp, buspair) in buspairs
        buspairs_conductor[bp] = Dict( k => v[1] for (k,v) in buspair)
    end

    for (bp, buspair) in buspairs_conductor

        if buspair["angmin"] >= 0
            wr_max[bp] = buspair["vm_fr_max"]*buspair["vm_to_max"]*cos(buspair["angmin"])
            wr_min[bp] = buspair["vm_fr_min"]*buspair["vm_to_min"]*cos(buspair["angmax"])
            wi_max[bp] = buspair["vm_fr_max"]*buspair["vm_to_max"]*sin(buspair["angmax"])
            wi_min[bp] = buspair["vm_fr_min"]*buspair["vm_to_min"]*sin(buspair["angmin"])
        end
        if buspair["angmax"] <= 0
            wr_max[bp] = buspair["vm_fr_max"]*buspair["vm_to_max"]*cos(buspair["angmax"])
            wr_min[bp] = buspair["vm_fr_min"]*buspair["vm_to_min"]*cos(buspair["angmin"])
            wi_max[bp] = buspair["vm_fr_min"]*buspair["vm_to_min"]*sin(buspair["angmax"])
            wi_min[bp] = buspair["vm_fr_max"]*buspair["vm_to_max"]*sin(buspair["angmin"])
        end
        if buspair["angmin"] < 0 && buspair["angmax"] > 0
            wr_max[bp] = buspair["vm_fr_max"]*buspair["vm_to_max"]*1.0
            wr_min[bp] = buspair["vm_fr_min"]*buspair["vm_to_min"]*min(cos(buspair["angmin"]), cos(buspair["angmax"]))
            wi_max[bp] = buspair["vm_fr_max"]*buspair["vm_to_max"]*sin(buspair["angmax"])
            wi_min[bp] = buspair["vm_fr_max"]*buspair["vm_to_max"]*sin(buspair["angmin"])
        end
    end

    return wr_min, wr_max, wi_min, wi_max
end
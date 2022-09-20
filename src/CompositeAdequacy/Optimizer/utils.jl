"maps component types to inactive status values"
const component_status_inactive = Dict(
    "bus" => 4,
    "load" => 0,
    "shunt" => 0,
    "gen" => 0,
    "storage" => 0,
    "switch" => 0,
    "branch" => 0,
    "dcline" => 0,
)

function ref_add!(ref::Dict{Symbol,Any})

    ### filter out inactive components ###
    ref[:bus] = Dict(x for x in ref[:bus] if (x.second["bus_type"] ≠ component_status_inactive["bus"]))
    ref[:load] = Dict(x for x in ref[:load] if (x.second["status"] ≠ component_status_inactive["load"] && x.second["load_bus"] in keys(ref[:bus])))
    ref[:shunt] = Dict(x for x in ref[:shunt] if (x.second["status"] ≠ component_status_inactive["shunt"] && x.second["shunt_bus"] in keys(ref[:bus])))
    ref[:gen] = Dict(x for x in ref[:gen] if (x.second["gen_status"] ≠ component_status_inactive["gen"] && x.second["gen_bus"] in keys(ref[:bus])))
    ref[:storage] = Dict(x for x in ref[:storage] if (x.second["status"] ≠ component_status_inactive["storage"] && x.second["storage_bus"] in keys(ref[:bus])))
    ref[:switch] = Dict(x for x in ref[:switch] if (x.second["status"] ≠ component_status_inactive["switch"] && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))
    ref[:branch] = Dict(x for x in ref[:branch] if (x.second["br_status"] ≠ component_status_inactive["branch"] && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))
    ref[:dcline] = Dict(x for x in ref[:dcline] if (x.second["br_status"] ≠ component_status_inactive["dcline"] && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))

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

"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses, branches)

    bus_lookup = Dict(bus["index"] => bus for (i,bus) in buses if bus["bus_type"] ≠ 4)
    branch_lookup = Dict(branch["index"] => branch for (i,branch) in branches if branch["br_status"] == 1 && haskey(bus_lookup, branch["f_bus"]) && haskey(bus_lookup, branch["t_bus"]))
    buspair_indexes = Set((branch["f_bus"], branch["t_bus"]) for (i,branch) in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)

    for (l,branch) in branch_lookup
        i = branch["f_bus"]
        j = branch["t_bus"]
        bp_angmin[(i,j)] = max(bp_angmin[(i,j)], branch["angmin"])
        bp_angmax[(i,j)] = min(bp_angmax[(i,j)], branch["angmax"])
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
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

""
function calc_branchs_y(branch::Dict{String,<:Any})

    g=(branch["br_r"] + im * branch["br_x"])
    #y = pinv(branch["br_r"] + im * branch["br_x"])
    g, b = real(pinv(branch["br_r"] + im * branch["br_x"])), imag(pinv(branch["br_r"] + im * branch["br_x"]))
    return g, b
end


""
function calc_branchs_t(branch::Dict{String,<:Any})
    #tap_ratio = branch["tap"]
    #angle_shift = branch["shift"]

    tr = branch["tap"] .* cos.(branch["shift"])
    ti = branch["tap"] .* sin.(branch["shift"])

    return tr, ti
end

""
function pinv(x::Number)
    xi = inv(x)
    return ifelse(isfinite(xi), xi, zero(xi))
end
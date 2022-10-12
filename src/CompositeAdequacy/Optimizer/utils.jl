function get_bus_components(arcs::Vector{Tuple{Int, Int, Int}}, buses::Buses, loads::Loads, shunts::Shunts, generators::Generators, storages::Storages)

    tmp = Dict((i, Tuple{Int,Int,Int}[]) for i in field(buses, :keys))
    for (l,i,j) in arcs
        push!(tmp[i], (l,i,j))
    end
    bus_arcs = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    bus_loads = bus_asset!(tmp, field(loads, :keys), field(loads, :buses))
    
    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    bus_shunts = bus_asset!(tmp, field(shunts, :keys), field(shunts, :buses))

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    bus_gens = bus_asset!(tmp, field(generators, :keys), field(generators, :buses))

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    bus_storage = bus_asset!(tmp, field(storages, :keys), field(storages, :buses))

    return (bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage)

end

""
function bus_asset!(tmp::Dict{Int, Vector{Int}}, key_assets::Vector{Int}, bus_assets::Vector{Int})
    for k in key_assets
        push!(tmp[bus_assets[k]], k)
    end
    return tmp
end

"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses::Buses, branches::Branches, branch_lookup::Vector{Int})
 
    buspair_indexes = Set((field(branches, :f_bus)[i], field(branches, :t_bus)[i]) for i in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)
    
    for l in branch_lookup
        i = field(branches, :f_bus)[l]
        j = field(branches, :t_bus)[l]
        bp_angmin[(i,j)] = max(bp_angmin[(i,j)], field(branches, :angmin)[l])
        bp_angmax[(i,j)] = min(bp_angmax[(i,j)], field(branches, :angmax)[l])
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    
    buspairs = Dict((i,j) => Dict(
        "branch"=>Int(bp_branch[(i,j)]),
        "angmin"=>Float16(bp_angmin[(i,j)]),
        "angmax"=>Float16(bp_angmax[(i,j)]),
        "tap"=>Float16(field(branches, :tap)[bp_branch[(i,j)]]),
        "vm_fr_min"=>Float16(field(buses, :vmin)[i]),
        "vm_fr_max"=>Float16(field(buses, :vmax)[i]),
        "vm_to_min"=>Float16(field(buses, :vmin)[j]),
        "vm_to_max"=>Float16(field(buses, :vmax)[j]),
        ) for (i,j) in buspair_indexes
    )
    
    # add optional parameters
    for bp in buspair_indexes
        buspairs[bp]["rate_a"] = field(branches, :rate_a)[bp_branch[bp]]
    end
    
    return buspairs

end

""
function check_status(system::SystemModel)
    for k in field(system, Branches, :keys)
        if field(system, Branches, :status)[k] ≠ 0
            f_bus = field(system, Branches, :f_bus)[k]
            t_bus = field(system, Branches, :t_bus)[k]
            if field(system, Buses, :bus_type)[f_bus] == 4 || field(system, Buses, :bus_type)[t_bus] == 4
                #Memento.info(_LOGGER, "deactivating branch $(k):($(f_bus),$(t_bus)) due to connecting bus status")
                field(system, Branches, :status)[k] = 0
            end
        end
    end
    
    for k in field(system, Buses, :keys)
        if field(system, Buses, :bus_type)[k] == 4
            if field(system, Loads, :status)[k] ≠ 0 field(system, Loads, :status)[k] = 0 end
            if field(system, Shunts, :status)[k] ≠ 0 field(system, Shunts, :status)[k] = 0 end
            if field(system, Generators, :status)[k] ≠ 0 field(system, Generators, :status)[k] = 0 end
            if field(system, Storages, :status)[k] ≠ 0 field(system, Storages, :status)[k] = 0 end
            if field(system, GeneratorStorages, :status)[k] ≠ 0 field(system, GeneratorStorages, :status)[k] = 0 end
        end
    end
end

"computes flow bounds on branches from ref data"
function ref_calc_branch_flow_bounds(branches::Branches)
    flow_lb = Dict() 
    flow_ub = Dict()

    for i in field(branches, :keys)
        flow_lb[i] = -Inf
        flow_ub[i] = Inf

        if hasfield(Branches, :rate_a)
            flow_lb[i] = max(flow_lb[i], -field(branches, :rate_a)[i])
            flow_ub[i] = min(flow_ub[i],  field(branches, :rate_a)[i])
        end
    end

    return flow_lb, flow_ub
end

""
function ref_add!(ref::Dict{Symbol,Any})

    ### filter out inactive components ###
    filter_inactive_components!(ref)

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

    return ref

end

""
function filter_inactive_components!(ref::Dict{Symbol,Any})

    ### filter out inactive components ###
    ref[:gen] = Dict(x for x in ref[:gen] if (x.second["gen_status"] ≠ 0 && x.second["gen_bus"] in keys(ref[:bus])))
    ref[:storage] = Dict(x for x in ref[:storage] if (x.second["status"] ≠ 0 && x.second["storage_bus"] in keys(ref[:bus])))
    ref[:branch] = Dict(x for x in ref[:branch] if (x.second["br_status"] ≠ 0 && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))
    ref[:bus] = Dict(x for x in ref[:bus] if (x.second["bus_type"] ≠ 4))
    ref[:switch] = Dict(x for x in ref[:switch] if (x.second["status"] ≠ 0 && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))
    ref[:load] = Dict(x for x in ref[:load] if (x.second["status"] ≠ 0 && x.second["load_bus"] in keys(ref[:bus])))
    ref[:shunt] = Dict(x for x in ref[:shunt] if (x.second["status"] ≠ 0 && x.second["shunt_bus"] in keys(ref[:bus])))
    ref[:dcline] = Dict(x for x in ref[:dcline] if (x.second["br_status"] ≠ 0 && x.second["f_bus"] in keys(ref[:bus]) && x.second["t_bus"] in keys(ref[:bus])))
    return ref

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
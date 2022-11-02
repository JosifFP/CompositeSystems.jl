"maps component types to status parameters"
const pm_component_status = Dict(
    "bus" => "bus_type",
    "load" => "status",
    "shunt" => "status",
    "gen" => "gen_status",
    "storage" => "status",
    "switch" => "status",
    "branch" => "br_status",
    "dcline" => "br_status",
)

"maps component types to inactive status values"
const pm_component_status_inactive = Dict(
    "bus" => 4,
    "load" => 0,
    "shunt" => 0,
    "gen" => 0,
    "storage" => 0,
    "switch" => 0,
    "branch" => 0,
    "dcline" => 0,
)

"""
computes the connected components of the network graph
returns a set of sets of bus ids, each set is a connected component
"""
function calc_connected_components(pm::AbstractPowerModel, branches::Branches)

    active_bus_ids = assetgrouplist(topology(pm, :buses_idxs))
    active_branches_ids = assetgrouplist(topology(pm, :branches_idxs))
    neighbors = Dict(i => Int[] for i in active_bus_ids)

    for i in active_branches_ids
        edge_f_bus = field(branches, :f_bus)[i]
        edge_t_bus = field(branches, :t_bus)[i]
        if edge_f_bus in active_bus_ids && edge_t_bus in active_bus_ids
            push!(neighbors[edge_f_bus], edge_t_bus)
            push!(neighbors[edge_t_bus], edge_f_bus)
        end
    end

    component_lookup = Dict(i => Set{Int}([i]) for i in active_bus_ids)
    touched = Set{Int}()

    for i in active_bus_ids
        if !(i in touched)
            PowerModels._cc_dfs(i, neighbors, component_lookup, touched)
        end
    end

    ccs = Set(values(component_lookup))
    return ccs
    
end


""
function bus_asset!(tmp::Dict{Int, Vector{Int}}, key_assets::Vector{Int}, bus_assets::Vector{Int})
    for k in key_assets
        push!(tmp[bus_assets[k]], k)
    end
    return tmp
end





#"garbage-----------------------------------------------------------------------------------------------------------------"
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
    ref[:loads_nodes] = tmp

    tmp = Dict((i, Int[]) for (i,bus) in ref[:bus])
    for (i,shunt) in ref[:shunt]
        push!(tmp[shunt["shunt_bus"]], i)
    end
    ref[:shunts_nodes] = tmp

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
        @warn("multiple reference buses found, $(keys(ref_buses)), this can cause infeasibility if they are in the same connected component")
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
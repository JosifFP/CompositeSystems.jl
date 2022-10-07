function get_bus_components(arcs::Vector{Tuple{Int, Int, Int}}, buses::Buses, loads::Loads, shunts::Shunts, generators::Generators, storages::Storages)

    tmp = Dict((i, Tuple{Int,Int,Int}[]) for i in field(buses, :keys))
    for (l,i,j) in arcs
        push!(tmp[i], (l,i,j))
    end
    bus_arcs = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    for k in field(loads, :keys)
        if field(loads, :status)[k] ≠ 0 push!(tmp[field(loads, :buses)[k]], k) end
    end
    bus_loads = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    for k in field(shunts, :keys)
        if field(shunts, :status)[k] ≠ 0 push!(tmp[field(shunts, :buses)[k]], k) end
    end
    bus_shunts = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    for k in field(generators, :keys)
        if field(generators, :status)[k] ≠ 0 push!(tmp[field(generators, :buses)[k]], k) end
    end
    bus_gens = tmp

    tmp = Dict((i, Int[]) for i in field(buses, :keys))
    for k in field(storages, :keys)
        if field(storages, :status)[k] ≠ 0 push!(tmp[field(storages, :buses)[k]], k) end
    end
    bus_storage = tmp

    return (bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage)

end

"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses::Buses, branches::Branches)

    bus_lookup = [i for i in field(buses, :keys) if field(buses, :bus_type)[i] ≠ 4]
    branch_lookup = [i for i in field(branches, :keys) if field(branches, :status)[i] == 1 && field(branches, :f_bus)[i] in bus_lookup && field(branches, :t_bus)[i] in bus_lookup]
    
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
function makeidxlist(collectionidxs::Vector{Int}, n_collections::Int)

    if isempty(collectionidxs)
        idxlist = fill(1:0, n_collections)
    else

        n_assets = length(collectionidxs)

        idxlist = Vector{UnitRange{Int}}(undef, n_collections)
        active_collection = 1
        start_idx = 1
        a = 1

        while a <= n_assets
        if collectionidxs[a] > active_collection
                idxlist[active_collection] = start_idx:(a-1)       
                active_collection += 1
                start_idx = a
        else
            a += 1
        end
        end

        idxlist[active_collection] = start_idx:n_assets       
        active_collection += 1

        while active_collection <= n_collections
            idxlist[active_collection] = (n_assets+1):n_assets
            active_collection += 1
        end

    end

    return idxlist

end
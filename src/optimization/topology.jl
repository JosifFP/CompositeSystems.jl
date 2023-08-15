"""
    Topology(system::SystemModel{N}) where {N}

Construct a `Topology` type from a given `SystemModel`.

## Structure Description

- `branches_available`: Indicates if each branch is available.
- `branches_pasttransition`: Tracks past transitions for each branch.
- ... (similar descriptions for other fields) ...

## Function Description

This function initializes vectors to track various system components, like branches, generators, and buses. 
These vectors store information about the availability and past transition of the components. 
The function also computes the necessary indices for accessing the `SystemModel` fields, bounds, 
and other derived values like curtailed power and stored energy. The final output is a `Topology` object, 
which provides a structured way to access and modify the electrical system's state.

## Notes

- `branches_available` and similar vectors use a `Bool` type to indicate the availability. 
True means the component is available, and False means it's not.
- This function is optimized for `SystemModel` of any `N`.
"""
function Topology(system::SystemModel{N}) where {N}

    nbranches = length(system.branches)
    ncommonbranches = length(system.commonbranches)
    ngens = length(system.generators)
    nstors = length(system.storages)
    nbuses = length(system.buses)
    nloads = length(system.loads)
    nshunts = length(system.shunts)

    branches_available = fill(true, nbranches)
    branches_pasttransition = fill(true, nbranches)
    commonbranches_available = fill(true, ncommonbranches)
    commonbranches_pasttransition = fill(true, ncommonbranches)
    generators_available = fill(true, ngens)
    generators_pasttransition = fill(true, ngens)
    storages_available = fill(true, nstors)
    storages_pasttransition = fill(true, nstors)
    buses_available = fill(true, nbuses)
    buses_pasttransition = fill(true, nbuses)
    loads_available = fill(true, nloads)
    loads_pasttransition = fill(true, nloads)
    shunts_available = fill(true, nshunts)
    shunts_pasttransition = fill(true, nshunts)
    
    key_branches = field(system, :branches, :keys)
    key_buses = field(system, :buses, :keys)
    key_generators = field(system, :generators, :keys)
    key_storages = field(system, :storages, :keys)
    key_loads = field(system, :loads, :keys)
    key_shunts = field(system, :shunts, :keys)

    branches_idxs = makeidxlist(key_branches, nbranches)
    buses_idxs = makeidxlist(key_buses, nbuses)
    generators_idxs = makeidxlist(key_generators, ngens)
    storages_idxs = makeidxlist(key_storages, nstors)
    loads_idxs = makeidxlist(key_loads, nloads)
    shunts_idxs = makeidxlist(key_shunts, nshunts)

    buses_generators_available = Dict((i, Int[]) for i in key_buses)
    buses_asset!(buses_generators_available, key_generators, field(system, :generators, :buses))

    buses_storages_available = Dict((i, Int[]) for i in key_buses)
    buses_asset!(buses_storages_available, key_storages, field(system, :storages, :buses))

    buses_loads_base = Dict((i, Int[]) for i in key_buses)
    buses_asset!(buses_loads_base, key_loads, field(system, :loads, :buses))
    buses_loads_available = deepcopy(buses_loads_base)

    buses_shunts_available = Dict((i, Int[]) for i in key_buses)
    buses_asset!(buses_shunts_available, key_shunts, field(system, :shunts, :buses))

    f_bus = field(system, :branches, :f_bus)
    t_bus = field(system, :branches, :t_bus)

    arcs_from_base = Tuple{Int, Int, Int}[(j, f_bus[j], t_bus[j]) for j in key_branches]
    arcs_to_base = Tuple{Int, Int, Int}[(j, t_bus[j], f_bus[j]) for j in key_branches]

    arcs_from_available::Vector{Union{Missing, Tuple{Int, Int, Int}}} = deepcopy(arcs_from_base)
    arcs_to_available::Vector{Union{Missing, Tuple{Int, Int, Int}}} = deepcopy(arcs_to_base)
    arcs_available::Vector{Union{Missing, Tuple{Int, Int, Int}}} = [arcs_from_base; arcs_to_base]
    buspairs_available::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}} = calc_buspair_parameters(system.branches, key_branches)
    busarcs_available = Dict{Int, Vector{Tuple{Int, Int, Int}}}((i, Tuple{Int, Int, Int}[]) for i in eachindex(key_buses))
    buses_asset!(busarcs_available, arcs_available)

    vad_min,vad_max = calc_theta_delta_bounds(key_buses, key_branches, system.branches)
    delta_bounds = Float64[vad_min,vad_max]

    ref_buses = slack_buses(system.buses)

    branches_flow_from = zeros(Float64, nbranches)
    branches_flow_to = zeros(Float64, nbranches)
    buses_curtailed_pd = zeros(Float64, nbuses)
    buses_curtailed_qd = zeros(Float64, nbuses)
    stored_energy = zeros(Float64, nstors)

    failed_systemstate = fill(true, N)

    return Topology(
        branches_available, branches_pasttransition, commonbranches_available, 
        commonbranches_pasttransition, generators_available, generators_pasttransition,
        storages_available, storages_pasttransition, buses_available, buses_pasttransition,
        loads_available, loads_pasttransition, shunts_available, shunts_pasttransition,
        buses_generators_available, buses_storages_available, buses_loads_base, 
        buses_loads_available, buses_shunts_available,
        arcs_from_base, arcs_to_base, arcs_from_available, arcs_to_available,
        arcs_available, busarcs_available, buspairs_available, delta_bounds, ref_buses, 
        branches_idxs, generators_idxs, storages_idxs, buses_idxs, loads_idxs, 
        shunts_idxs, buses_curtailed_pd, buses_curtailed_qd, branches_flow_from, 
        branches_flow_to, stored_energy, failed_systemstate
    )
end

Base.:(==)(x::T, y::T) where {T <: Topology} =
        x.branches_available == y.branches_available &&
        x.branches_pasttransition == y.branches_pasttransition &&
        x.commonbranches_available == y.commonbranches_available &&
        x.commonbranches_pasttransition == y.commonbranches_pasttransition &&
        x.generators_available == y.generators_available &&
        x.generators_pasttransition == y.generators_pasttransition &&
        x.storages_available == y.storages_available &&
        x.storages_pasttransition == y.storages_pasttransition &&
        x.buses_available == y.buses_available &&
        x.buses_pasttransition == y.buses_pasttransition &&
        x.loads_available == y.loads_available &&
        x.loads_pasttransition == y.loads_pasttransition &&
        x.shunts_available == y.shunts_available &&
        x.shunts_pasttransition == y.shunts_pasttransition &&
        x.buses_generators_available == y.buses_generators_available &&
        x.buses_storages_available == y.buses_storages_available &&
        x.buses_loads_base == y.buses_loads_base &&
        x.buses_loads_available == y.buses_loads_available &&
        x.buses_shunts_available == y.buses_shunts_available &&
        x.arcs_from_base == y.arcs_from_base &&
        x.arcs_to_base == y.arcs_to_base &&
        x.arcs_from_available == y.arcs_from_available &&
        x.arcs_to_available == y.arcs_to_available &&
        x.arcs_available == y.arcs_available &&
        x.buspairs_available == y.buspairs_available &&
        x.delta_bounds == y.delta_bounds &&
        x.ref_buses == y.ref_buses &&
        x.branches_idxs == y.branches_idxs &&
        x.generators_idxs == y.generators_idxs &&
        x.storages_idxs == y.storages_idxs &&
        x.buses_idxs == y.buses_idxs &&
        x.loads_idxs == y.loads_idxs &&
        x.shunts_idxs == y.shunts_idxs &&
        x.buses_curtailed_pd == y.buses_curtailed_pd &&
        x.buses_curtailed_qd == y.buses_curtailed_qd &&
        x.branches_flow_from == y.branches_flow_from &&
        x.branches_flow_to == y.branches_flow_to &&
        x.stored_energy == y.stored_energy &&
        x.failed_systemstate == y.failed_systemstate



"""
`update_topology!` adapts the system's topology based on its current states and settings. 
This function:
1. Checks and updates the system topology if any branches are unavailable or transitioning.
2. Sets the stored energy of unavailable storage components to zero.
3. Flags the system state at the given timestep `t` as failed if there are unavailable generators, branches, or storages.

# Arguments
- `topology`: The system topology to be updated.
- `system`: The current system model.
- `settings`: The settings/configuration for the system.
- `t`: The current timestep.
"""
function update_topology!(topology::Topology, system::SystemModel, settings::Settings, t::Int)
    if any(topology.branches_available .== 0) || any(topology.branches_pasttransition .== 0)
        update_buses_assets!(topology, system)
        simplify!(topology, system, settings)
    end

    for key in field(system, :storages, :keys)
        if !topology.storages_available[key]
            topology.stored_energy[key] = 0.0
        end
    end

    topology.failed_systemstate[t] = any(topology.generators_available .== 0) || 
                                     any(topology.branches_available .== 0) || 
                                     any(topology.storages_available .== 0)
end



"""
`update_states!` synchronizes the power system's topology state with the given state transition.
The function:
1. Updates various assets of the system's topology (like branches, generators, storages) based on the provided state transition.
2. Ensures buses, loads, and shunts are available by default.
3. Initializes the `failed_systemstate` vector at the first timestep to track system state alterations.

# Arguments
- `topology`: The system topology to be updated.
- `statetransition`: The state transition details to synchronize with.
- `t`: The current timestep.
"""
function update_states!(topology::Topology, statetransition::StateTransition, t::Int)

    topology.branches_available .= statetransition.branches_available
    topology.commonbranches_available .= statetransition.commonbranches_available
    topology.generators_available .= statetransition.generators_available
    topology.storages_available .= statetransition.storages_available
    fill!(topology.buses_available, 1)
    fill!(topology.loads_available, 1)
    fill!(topology.shunts_available, 1)
    t==1 && fill!(topology.failed_systemstate, 1)
    return
end



"The functions update_states! are updating the state of the power system's topology 
according to the provided state transition."
function update_states!(topology::Topology, statetransition::StateTransition)

    topology.branches_available .= statetransition.branches_available
    topology.commonbranches_available .= statetransition.commonbranches_available
    topology.generators_available .= statetransition.generators_available
    topology.storages_available .= statetransition.storages_available
    fill!(topology.buses_available, 1)
    fill!(topology.loads_available, 1)
    fill!(topology.shunts_available, 1)
    fill!(topology.failed_systemstate, 1)
    return
end



"""
    record_states!(topology::Topology)

Save the current availability states of system components, such as branches, 
common branches, generators, storages, buses, loads, and shunts, into their 
respective 'pasttransition' fields within the topology. This function provides 
a way to keep track of recent state transitions of these components.

# Arguments
- `topology`: The system topology containing current and past states.
"""
function record_states!(topology::Topology)
    topology.branches_pasttransition .= topology.branches_available
    topology.commonbranches_pasttransition .= topology.commonbranches_available
    topology.generators_pasttransition .= topology.generators_available
    topology.storages_pasttransition .= topology.storages_available
    topology.buses_pasttransition .= topology.buses_available
    topology.loads_pasttransition .= topology.loads_available
    topology.shunts_pasttransition .= topology.shunts_available
    return
end



"""
The simplify! function is used to simplify the power system model by removing inactive elements from the model. 
This is done by checking the availability of generators, loads, shunts, and branches and removing any that are not active. 
The function starts by updating the indices of the active elements, and then iteratively checks if any buses can be deactivated 
due to having only one active incident edge and no generation, loads, storages, or shunts. 
If any buses are deactivated, the function also deactivates any branches that are connected to those buses. 
The function also checks for connected components of the system and deactivates any isolated sections of the network
"""
function simplify!(topology::Topology, system::SystemModel, settings::Settings)

    key_buses = field(system, :buses, :keys)
    key_branches = field(system, :branches, :keys)

    revised_branches = false
    revised_shunts = false
    revised_buses = true

    while revised_buses
        revised_buses = false

        for i in key_buses
            if topology.buses_available[i]
                incident_active_edge = 0
                busarcs_i = topology.busarcs_available[i]

                if !isempty(busarcs_i)
                    incident_active_edge = sum(topology.branches_available[l] for (l, u, v) in busarcs_i)
                end
                
                if incident_active_edge <= 1 &&
                    isempty(topology.buses_generators_available[i]) &&
                    isempty(topology.buses_loads_available[i]) &&
                    isempty(topology.buses_storages_available[i]) &&
                    isempty(topology.buses_shunts_available[i])
                    topology.buses_available[i] = 0
                    revised_buses = true
                    #@info("deactivating bus $(i) due to dangling bus without generation, load or storage")
                end
                
                if settings.deactivate_isolated_bus_gens_stors && incident_active_edge == 0
                    if !isempty(topology.buses_generators_available[i]) || !isempty(topology.buses_storages_available[i])
                        topology.buses_available[i] = 0
                        revised_buses = true
                    end
                end
            end
        end

        if revised_buses
            f_bus = field(system, :branches, :f_bus)
            t_bus = field(system, :branches, :t_bus)
            for l in key_branches
                if topology.branches_available[l]
                    f_bus_l = f_bus[l]
                    t_bus_l = t_bus[l]
                    if !topology.buses_available[f_bus_l] || !topology.buses_available[t_bus_l]
                        topology.branches_available[l] = 0
                        revised_branches = true
                    end
                end
            end
        end
    end

    ccs = calc_connected_components(topology, system.branches)
    ccs_order = sort(collect(ccs); by=length)
    largest_cc = ccs_order[end]

    # this step should be improved later. It ensures that the optimization algorithm solves the problem correctly.
    for i in field(system, :shunts, :buses)
        if !(i in largest_cc)
            for k in topology.buses_shunts_available[i]
                topology.shunts_available[k] = false
                revised_shunts = true
            end
        end
    end

    revised_shunts && update_idxs!(
        filter(i->topology.shunts_available[i], field(system, :shunts, :keys)), 
        topology.shunts_idxs, topology.buses_shunts_available, field(system, :shunts, :buses))

    if length(ccs) > 1 && settings.select_largest_splitnetwork
        if topology.ref_buses[1] in largest_cc && length(largest_cc) < length(system.buses)
            for i in key_buses
                if topology.buses_available[i] && !(i in largest_cc)
                    topology.buses_available[i] = 0
                    revised_buses = true
                    #@info("select_largest_splitnetwork section: deactivating bus $(i) due to dangling isolated network section")            
                end
            end
        end
    end

    for cc in ccs
        max_size = 50
        cc_active_loads = Int[]
        cc_active_shunts = Int[]
        cc_active_gens = Int[]
        cc_active_strg = Int[]
    
        sizehint!(cc_active_loads, max_size)
        sizehint!(cc_active_shunts, max_size)
        sizehint!(cc_active_gens, max_size)
        sizehint!(cc_active_strg, max_size)

        for i in cc
            buses_loads_i = topology.buses_loads_available[i]
            buses_shunts_i = topology.buses_shunts_available[i]
            buses_generators_i = topology.buses_generators_available[i]
            buses_storages_i = topology.buses_storages_available[i]
    
            push!(cc_active_loads, length(buses_loads_i))
            push!(cc_active_shunts, length(buses_shunts_i))
            push!(cc_active_gens, length(buses_generators_i))
            push!(cc_active_strg, length(buses_storages_i))
        end

        active_load_count = sum(cc_active_loads)
        active_shunt_count = sum(cc_active_shunts)
        active_gen_count = sum(cc_active_gens)
        active_strg_count = sum(cc_active_strg)

        if (active_load_count == 0 && active_shunt_count == 0 && active_strg_count == 0) || 
            (active_gen_count == 0 && active_strg_count == 0)
            #@info("deactivating connected component $(cc) due to isolation without 
            #generation, load, or storage, active_strg_count=$(active_strg_count)")
            topology.buses_available[collect(cc)] .= 0
            revised_buses = true
        end
    end

    for l in key_branches
        if topology.branches_available[l] ≠ 0
            f_bus = topology.buses_available[field(system, :branches, :f_bus)[l]]
            t_bus = topology.buses_available[field(system, :branches, :t_bus)[l]]
            if !f_bus || !t_bus
                topology.branches_available[l] = 0
                revised_branches = true
            end
        end
    end

    # Update arcs and buspairs
    revised_branches && update_arcs!(topology, system)

    # used to update states from components that don't have statistic information, but that might be disconnected from the grid.

    for i in key_buses
        if !topology.buses_available[i]
            for k in topology.buses_loads_available[i]
                if topology.loads_available[k] ≠ 0
                    topology.loads_available[k] = 0
                end
            end
            for k in topology.buses_shunts_available[i]
                if topology.shunts_available[k] ≠ 0
                    topology.shunts_available[k] = 0
                end
            end
            for k in topology.buses_generators_available[i]
                if topology.generators_available[k] ≠ 0
                    topology.generators_available[k] = 0
                end
            end
            for k in topology.buses_storages_available[i]
                if topology.storages_available[k] ≠ 0
                    topology.storages_available[k] = 0
                end
                topology.stored_energy[k] = 0  #ES is discharged once it gets disconnected from the grid.
            end
        end
    end
    return
end

"It calls update_arcs! to update the arcs in the topology.It filters available 
buses and updates their indices. It does the same for generators, storages, loads, 
and shunts - filtering the available ones and updating their indices and associated buses."
function update_buses_assets!(topology::Topology, system::SystemModel)

    # Update arcs and buspairs
    update_arcs!(topology, system)

    # Update buses indices
    update_idxs!(
        filter(i-> topology.buses_available[i], field(system, :buses, :keys)),
        topology.buses_idxs)

    # Update generators indices and their buses
    update_idxs!(
        filter(i->topology.generators_available[i], field(system, :generators, :keys)), 
        topology.generators_idxs, 
        topology.buses_generators_available, 
        field(system, :generators, :buses))

    # Update storages indices and their buses
    update_idxs!(
        filter(i->topology.storages_available[i], field(system, :storages, :keys)), 
        topology.storages_idxs, 
        topology.buses_storages_available, 
        field(system, :storages, :buses))

    # Update loads indices and their buses
    update_idxs!(
        filter(i->topology.loads_available[i], field(system, :loads, :keys)), 
        topology.loads_idxs, 
        topology.buses_loads_available, 
        field(system, :loads, :buses))

    # Update shunts indices and their buses
    update_idxs!(
        filter(i->topology.shunts_available[i], field(system, :shunts, :keys)), 
        topology.shunts_idxs, 
        topology.buses_shunts_available, 
        field(system, :shunts, :buses))
        
    return
end



"""
computes the connected components of the network graph
returns a set of sets of bus ids, each set is a connected component
"""
function calc_connected_components(topology::Topology, branches::Branches)

    active_bus_ids = assetgrouplist(topology.buses_idxs)
    active_branches_ids = assetgrouplist(topology.branches_idxs)
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
            _PM._cc_dfs(i, neighbors, component_lookup, touched)
        end
    end

    ccs = Set(values(component_lookup))
    return ccs
end

""
function update_idxs!(key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}})
    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
end

"Update asset_idxs and asset_nodes"
function update_idxs!(
    key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}}, 
    asset_dict_nodes::Dict{Int, Vector{Int}}, asset_buses::Vector{Int})

    # Update asset indices using the key_assets
    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
    
    # Clear existing values in asset_dict_nodes
    for (_,v) in asset_dict_nodes
        empty!(v)
    end

    # Update asset_dict_nodes with the buses of each asset
    buses_asset!(asset_dict_nodes, key_assets, asset_buses)
end

"This function updates the arcs of the power system model."
function update_arcs!(topology::Topology, system::SystemModel)

    # Update branches indices
    update_idxs!(filter(l-> topology.branches_available[l], field(system, :branches, :keys)), topology.branches_idxs)

    # Loop through each branch in the power system model
    for i in field(system, :branches, :keys)
        if !topology.branches_available[i]
            # If the branch is unavailable, set arcs_from and arcs_to to missing
            topology.arcs_from_available[i] = missing
            topology.arcs_to_available[i] = missing
        else
            # If the branch is available, update arcs_from and arcs_to with the appropriate values
            topology.arcs_from_available[i] = topology.arcs_from_base[i]
            topology.arcs_to_available[i] = topology.arcs_to_base[i]
        end
    end
   
    # Combine arcs_from and arcs_to to form the arcs and remove missing values
    topology.arcs_available[:] .= [topology.arcs_from_available; topology.arcs_to_available]

    arcs = filter(!ismissing, skipmissing(topology.arcs_available))

    # Clear existing values in busarcs
    map!(x -> Int[], topology.busarcs_available)
    
    # Update busarcs with the buses of each arc
    buses_asset!(topology.busarcs_available, arcs)
    # Update buspair parameters
    update_buspair_parameters!(topology.buspairs_available, system.branches, assetgrouplist(topology.branches_idxs))
    #vad_min,vad_max = calc_theta_delta_bounds(pm, system.branches)
    #topology(pm, :delta_bounds)[1] = vad_min
    #topology(pm, :delta_bounds)[2] = vad_max
    return
end

""
function buses_asset!(
    asset_dict_nodes::Dict{Int, Vector{Int}}, key_assets::Vector{Int}, asset_buses::Vector{Int})
    for k in key_assets
        push!(asset_dict_nodes[asset_buses[k]], k)
    end
    return asset_dict_nodes
end

""
function buses_asset!(
    busarcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}, arcs::Vector{Tuple{Int, Int, Int}})
    for (l,i,j) in arcs
        push!(busarcs[i], (l,i,j))
    end
    return busarcs
end

""
function buses_asset!(
    busarcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}, arcs::Vector{Union{Missing, Tuple{Int, Int, Int}}})
    for (l,i,j) in arcs
        push!(busarcs[i], (l,i,j))
    end
    return busarcs
end



"""
    update_buspair_parameters!(buspairs, branches, branch_lookup)

Update information related to bus pairs in the power grid.

This function modifies the `buspairs` dictionary to store connectivity and angle constraints 
for every pair of buses linked by an active branch. Memory efficiency is optimized using 
`sizehint!`, and the resulting dictionary will have missing values for non-active bus pairs.

# Arguments
- `buspairs`: Dictionary to update with bus pair data.
- `branches`: Data structure containing branch details.
- `branch_lookup`: Indices of active branches.
"""
function update_buspair_parameters!(
    buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}, 
    branches::Branches, 
    branch_lookup::Vector{Int})
    
    # Extract bus pairs from active branches.
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)
    
    # Initialize dictionaries for storing branch and angle information.
    bp_branch = Dict((bp, Int[]) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf32) for bp in buspair_indexes)
    bp_angmax = Dict((bp, Inf32) for bp in buspair_indexes)

    # Optimize memory usage by pre-allocating space.
    for (bp, arr) in bp_branch
        sizehint!(arr, length(branch_lookup))
    end
    
    # Update dictionaries with relevant branch and angle details.
    for l in branch_lookup
        i, j = branches.f_bus[l], branches.t_bus[l]
        bp_key = (i,j)

        bp_angmin[bp_key] = Float32(max(bp_angmin[bp_key], branches.angmin[l]))
        bp_angmax[bp_key] = Float32(min(bp_angmax[bp_key], branches.angmax[l]))
        push!(bp_branch[bp_key], l)
    end

    # Store the consolidated data in the main dictionary: buspairs.
    for bp in buspair_indexes
        i, j = bp
        bp_key = (i,j)

        if !(bp_key in buspair_indexes)
            buspairs[bp_key] = missing
        else
            buspairs[bp_key] = [bp_branch[bp_key], bp_angmin[bp_key], bp_angmax[bp_key]]
        end
    end

    return buspairs
end



"""
    calc_theta_delta_bounds(topology, branches)

Calculate the minimum and maximum bounds for the angle delta in the provided power system topology.

The function determines the angle bounds by aggregating the minimum and maximum angles of the branches. 
If there's more than one angle value, a summation over the relevant angles is performed, considering 
the presence of dclines or similar scenarios.

# Arguments
- `topology`: The power system's topology.
- `branches`: Data structure containing branch details.

# Returns
- `angle_min_val`: Minimum angle delta bound.
- `angle_max_val`: Maximum angle delta bound.
"""
function calc_theta_delta_bounds(topology::Topology, branches::Branches)

    bus_count = length(assetgrouplist(topology.buses_idxs))
    branches_idxs = assetgrouplist(topology.branches_idxs)
    
    angle_mins = sort!(Float32[field(branches, :angmin)[l] for l in branches_idxs])
    angle_maxs = sort!(Float32[field(branches, :angmax)[l] for l in branches_idxs], rev=true)
    
    # Handle case with multiple angles, typically when dclines are present.
    if length(angle_mins) > 1
        angle_count = min(bus_count-1, length(branches_idxs))
        angle_min_val = sum(angle_mins[1:angle_count])
        angle_max_val = sum(angle_maxs[1:angle_count])
    else
        angle_min_val = angle_mins[1]
        angle_max_val = angle_maxs[1]
    end

    return angle_min_val, angle_max_val
end



"""
    calc_theta_delta_bounds(key_buses, branches_idxs, branches)

Calculate the minimum and maximum bounds for the angle delta based on the provided bus keys and branch indices.

The function determines the angle bounds by aggregating the minimum and maximum angles of the branches. 
If there's more than one angle value, a summation over the relevant angles is performed, considering 
scenarios like the presence of dclines.

# Arguments
- `key_buses`: List of bus keys in the system.
- `branches_idxs`: Indices of the branches in the system.
- `branches`: Data structure containing branch details.

# Returns
- `angle_min_val`: Minimum angle delta bound.
- `angle_max_val`: Maximum angle delta bound.
"""
function calc_theta_delta_bounds(key_buses::Vector{Int}, branches_idxs::Vector{Int}, branches::Branches)

    bus_count = length(key_buses)
    
    angle_mins = sort!(Float32[field(branches, :angmin)[l] for l in branches_idxs])
    angle_maxs = sort!(Float32[field(branches, :angmax)[l] for l in branches_idxs], rev=true)
    
    # Handle multiple angle values, typically when dclines are present.
    if length(angle_mins) > 1
        angle_count = min(bus_count-1, length(branches_idxs))
        angle_min_val = sum(angle_mins[1:angle_count])
        angle_max_val = sum(angle_maxs[1:angle_count])
    else
        angle_min_val = angle_mins[1]
        angle_max_val = angle_maxs[1]
    end

    return angle_min_val, angle_max_val
end


"""
    calc_buspair_parameters(branches, branch_lookup)

Calculate bus pair parameters based on the provided branches and branch lookup. 

The function constructs dictionaries to represent the parameters of each bus pair: 
- `bp_branch`: Indices of branches corresponding to each bus pair.
- `bp_angmin`: Minimum angle constraints for each bus pair.
- `bp_angmax`: Maximum angle constraints for each bus pair.

# Arguments
- `branches`: Data structure containing branch details.
- `branch_lookup`: List of branch indices to consider.

# Returns
- `buspairs`: Dictionary with bus pairs as keys and their corresponding parameters as values.
"""
function calc_buspair_parameters(branches::Branches, branch_lookup::Vector{Int})
 
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)

    bp_branch = Dict((bp, Int[]) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf32) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf32) for bp in buspair_indexes)
    
    for l in branch_lookup
        i, j = branches.f_bus[l], branches.t_bus[l]
        bp_angmin[(i,j)] = Float32(max(bp_angmin[(i,j)], branches.angmin[l]))
        bp_angmax[(i,j)] = Float32(min(bp_angmax[(i,j)], branches.angmax[l]))
        push!(bp_branch[(i,j)], l)
    end
    
    # Construct the buspairs dictionary directly using a comprehension
    buspairs = Dict((i,j) => [bp_branch[(i,j)], bp_angmin[(i,j)], bp_angmax[(i,j)]] for (i,j) in buspair_indexes)

    # Additional optional parameters can be appended if needed in the future

    return buspairs
end


"""
    slack_buses(buses::Buses)

Identify slack (or reference) buses within the given buses dataset. Slack buses 
are identified based on their type (bus_type == 3). In power systems, only one 
slack bus is allowed per connected component.

# Arguments
- `buses`: Data structure containing bus details.

# Returns
- `ref_buses`: A list of reference (or slack) bus IDs.

# Raises
- An error if multiple reference buses are found in the same connected component.
"""
function slack_buses(buses::Buses)

    ref_buses = Int[]
    for i in buses.keys
        if buses.bus_type[i] == 3
            push!(ref_buses, i)
        end
    end

    if length(ref_buses) > 1
        @error("Multiple reference buses found, $(ref_buses). This can cause infeasibility if they are in the same connected component.")
    end

    return ref_buses
end



"""
    _reset!(topology::Topology)

Reset the availability and flows of various assets within the topology to 
their default states. This prepares the topology for a new round of 
calculations or simulations.

# Arguments
- `topology`: The topology data structure to reset.
"""
function _reset!(topology::Topology)

    fill!(topology.branches_available, 1)
    fill!(topology.branches_flow_from, 0)
    fill!(topology.branches_flow_to, 0)
    fill!(topology.generators_available, 1)
    fill!(topology.storages_available, 1)
    fill!(topology.buses_curtailed_pd, 0)
    fill!(topology.buses_curtailed_qd, 0)
    fill!(topology.loads_available, 1)
    fill!(topology.shunts_available, 1)
    fill!(topology.commonbranches_available, 1)
    fill!(topology.buses_available, 1)

    return
end
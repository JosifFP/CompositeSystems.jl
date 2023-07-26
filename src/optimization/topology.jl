""
function Topology(system::SystemModel{N}) where {N}

    nbranches = length(system.branches)
    ncommonbranches = length(system.commonbranches)
    ngens = length(system.generators)
    nstors = length(system.storages)
    nbuses = length(system.buses)
    nloads = length(system.loads)
    nshunts = length(system.shunts)

    branches_available = Vector{Bool}(undef, nbranches)
    branches_pasttransition = Vector{Bool}(undef, nbranches)
    commonbranches_available = Vector{Bool}(undef, ncommonbranches)
    commonbranches_pasttransition = Vector{Bool}(undef, ncommonbranches)
    generators_available = Vector{Bool}(undef, ngens)
    generators_pasttransition = Vector{Bool}(undef, ngens)
    storages_available = Vector{Bool}(undef, nstors)
    storages_pasttransition = Vector{Bool}(undef, nstors)
    buses_available = Vector{Bool}(undef, nbuses)
    buses_pasttransition = Vector{Bool}(undef, nbuses)
    loads_available = Vector{Bool}(undef, nloads)
    loads_pasttransition = Vector{Bool}(undef, nloads)
    shunts_available = Vector{Bool}(undef, nshunts)
    shunts_pasttransition = Vector{Bool}(undef, nshunts)
    
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

    branches_flow_from = Vector{Float64}(undef, nbranches) # Active power withdrawn at the from bus
    branches_flow_to = Vector{Float64}(undef, nbranches) # Active power withdrawn at the from bus
    buses_curtailed_pd = Vector{Float64}(undef, nbuses) #curtailed load in p.u. (active power)
    buses_curtailed_qd = Vector{Float64}(undef, nbuses) #curtailed load in p.u. (reactive power)
    stored_energy = Vector{Float64}(undef, nstors) #stored energy

    failed_systemstate = Vector{Bool}(undef, N) #this vector represents the system state's history

    fill!(branches_available, 1)
    fill!(branches_pasttransition, 1)
    fill!(commonbranches_available, 1)
    fill!(commonbranches_pasttransition, 1)
    fill!(generators_available, 1)
    fill!(generators_pasttransition, 1)
    fill!(storages_available, 1)
    fill!(storages_pasttransition, 1)
    fill!(buses_available, 1)
    fill!(buses_pasttransition, 1)
    fill!(loads_available, 1)
    fill!(loads_pasttransition, 1)
    fill!(shunts_available, 1)
    fill!(shunts_pasttransition, 1)
    fill!(failed_systemstate, 1)

    fill!(branches_flow_from, 0.0)
    fill!(branches_flow_to, 0.0)
    fill!(buses_curtailed_pd, 0.0)
    fill!(buses_curtailed_qd, 0.0)
    fill!(stored_energy, 0.0)

    return Topology(
        branches_available::Vector{Bool},
        branches_pasttransition::Vector{Bool},
        commonbranches_available::Vector{Bool},
        commonbranches_pasttransition::Vector{Bool},
        generators_available::Vector{Bool},
        generators_pasttransition::Vector{Bool},
        storages_available::Vector{Bool},
        storages_pasttransition::Vector{Bool},
        buses_available::Vector{Bool},
        buses_pasttransition::Vector{Bool},
        loads_available::Vector{Bool},
        loads_pasttransition::Vector{Bool},
        shunts_available::Vector{Bool},
        shunts_pasttransition::Vector{Bool},
        buses_generators_available::Dict{Int, Vector{Int}}, 
        buses_storages_available::Dict{Int, Vector{Int}}, 
        buses_loads_base::Dict{Int, Vector{Int}}, 
        buses_loads_available::Dict{Int, Vector{Int}}, 
        buses_shunts_available::Dict{Int, Vector{Int}},
        arcs_from_base::Vector{Tuple{Int, Int, Int}},
        arcs_to_base::Vector{Tuple{Int, Int, Int}},
        arcs_from_available::Vector{Union{Missing, Tuple{Int, Int, Int}}},
        arcs_to_available::Vector{Union{Missing, Tuple{Int, Int, Int}}},
        arcs_available::Vector{Union{Missing, Tuple{Int, Int, Int}}},
        busarcs_available::Dict{Int, Vector{Tuple{Int, Int, Int}}},
        buspairs_available::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}},
        delta_bounds::Vector{Float64},
        ref_buses::Vector{Int},
        branches_idxs::Vector{UnitRange{Int}},  
        generators_idxs::Vector{UnitRange{Int}}, 
        storages_idxs::Vector{UnitRange{Int}},
        buses_idxs::Vector{UnitRange{Int}}, 
        loads_idxs::Vector{UnitRange{Int}}, 
        shunts_idxs::Vector{UnitRange{Int}},
        buses_curtailed_pd::Vector{Float64},
        buses_curtailed_qd::Vector{Float64},
        branches_flow_from::Vector{Float64},
        branches_flow_to::Vector{Float64},
        stored_energy::Vector{Float64},
        failed_systemstate::Vector{Bool}
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
    x.buses_curtailed_pd == x.buses_curtailed_pd &&
    x.buses_curtailed_qd == x.buses_curtailed_qd &&
    x.branches_flow_from == x.branches_flow_from &&
    x.branches_flow_to == x.branches_flow_to &&
    x.stored_energy == x.stored_energy &&
    x.failed_systemstate == x.failed_systemstate
#

"""
The update_topology! function modifies the system topology based on the current system states and settings.
Firstly, it checks for any unavailable or transitioning branches in the system. If such outaged branches are found, 
it updates the bus assets and simplifies the system topology accordingly. Next, for each storage component in the 
system, if it's not available, it sets its stored energy to 0. Finally, it flags the system state at timestep t 
as failed if any of the generators, branches, or storages are unavailable.
"""
function update_topology!(topology::Topology, system::SystemModel, settings::Settings, t::Int)

    if any(iszero, topology.branches_available) || any(iszero, topology.branches_pasttransition)
        update_buses_assets!(topology, system)
        simplify!(topology, system, settings)
    end

    foreach(
        i -> topology.storages_available[i] || (topology.stored_energy[i] = 0.0), 
        field(system, :storages, :keys)) 

    topology.failed_systemstate[t] = any(iszero, topology.generators_available) || 
                                     any(iszero, topology.branches_available) || 
                                     any(iszero, topology.storages_available)
    return
end

"The functions update_states! are updating the state of the power system's topology 
according to the provided state transition. It also initializes the failed_systemstate
vector to record system state changes"
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
    return
end

"The record_states! function is saving the current availability states of various system components 
(like branches, common branches, generators, storages, buses, loads, and shunts) into their respective 
'pasttransition' fields in the topology. This is used to keep limited track of the state transitions of 
these components over time."
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
In the function update_buspair_parameters!, we're updating the information related to bus pairs in the power grid. 
For each active branch (connection between buses), we record the branch indices, and the minimum and maximum angles.
We use sizehint! to preallocate memory for these recordings. This reduces the time spent on memory allocation when 
arrays grow, leading to more efficient code execution, especially when the number of active branches is large.
Finally, we update our main dictionary, buspairs, with this information for each bus pair, and set the value as missing 
for non-active bus pairs. This way, we efficiently organize the grid's connectivity information for further use.
"""
function update_buspair_parameters!(
    buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}, branches::Branches, branch_lookup::Vector{Int})
 
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)
    bp_branch = Dict((bp, Int[]) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf32) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf32) for bp in buspair_indexes)
    #bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)

    # Applying sizehint!
    for (bp, arr) in bp_branch
        sizehint!(arr, length(branch_lookup))
    end
    
    for l in branch_lookup
        i = branches.f_bus[l]
        j = branches.t_bus[l]
        bp_angmin[(i,j)] = Float32(max(bp_angmin[(i,j)], branches.angmin[l]))
        bp_angmax[(i,j)] = Float32(min(bp_angmax[(i,j)], branches.angmax[l]))
        push!(bp_branch[(i,j)], l)
    end

    for bp in buspair_indexes
        i,j = bp
        if !((i,j) in buspair_indexes)
            buspairs[bp] = missing
        else
            buspairs[bp] = [bp_branch[bp], bp_angmin[bp], bp_angmax[bp]]
        end
    end
 
    return buspairs
end

""
function calc_theta_delta_bounds(topology::Topology, branches::Branches)

    bus_count = length(assetgrouplist(topology.buses_idxs))
    branches_idxs = assetgrouplist(topology.branches_idxs)
    angle_min = Real[]
    angle_max = Real[]
    angle_mins = Float32[field(branches, :angmin)[l] for l in branches_idxs]
    angle_maxs = Float32[field(branches, :angmax)[l] for l in branches_idxs]
    sort!(angle_mins)
    sort!(angle_maxs, rev=true)
    
    if length(angle_mins) > 1
        # note that, this can occur when dclines are present
        angle_count = min(bus_count-1, length(branches_idxs))
        angle_min_val = sum(angle_mins[1:angle_count])
        angle_max_val = sum(angle_maxs[1:angle_count])
    else
        angle_min_val = angle_mins[1]
        angle_max_val = angle_maxs[1]
    end
    push!(angle_min, angle_min_val)
    push!(angle_max, angle_max_val)

    return angle_min[1], angle_max[1]
end

""
function calc_theta_delta_bounds(key_buses::Vector{Int}, branches_idxs::Vector{Int}, branches::Branches)

    bus_count = length(key_buses)
    angle_min = Real[]
    angle_max = Real[]
    angle_mins = Float32[field(branches, :angmin)[l] for l in branches_idxs]
    angle_maxs = Float32[field(branches, :angmax)[l] for l in branches_idxs]
    sort!(angle_mins)
    sort!(angle_maxs, rev=true)
    
    if length(angle_mins) > 1
        # note that, this can occur when dclines are present
        angle_count = min(bus_count-1, length(branches_idxs))
        angle_min_val = sum(angle_mins[1:angle_count])
        angle_max_val = sum(angle_maxs[1:angle_count])
    else
        angle_min_val = angle_mins[1]
        angle_max_val = angle_maxs[1]
    end
    push!(angle_min, angle_min_val)
    push!(angle_max, angle_max_val)
    return angle_min[1], angle_max[1]
end

""
function calc_buspair_parameters(branches::Branches, branch_lookup::Vector{Int})
 
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)
    bp_branch = Dict((bp, Int[]) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf32) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf32) for bp in buspair_indexes)
    #bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    
    for l in branch_lookup
        i = branches.f_bus[l]
        j = branches.t_bus[l]
        bp_angmin[(i,j)] = Float32(max(bp_angmin[(i,j)], branches.angmin[l]))
        bp_angmax[(i,j)] = Float32(min(bp_angmax[(i,j)], branches.angmax[l]))
        push!(bp_branch[(i,j)], l)
        #bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    
    buspairs = Dict((i,j) => [bp_branch[(i,j)],bp_angmin[(i,j)],bp_angmax[(i,j)]] for (i,j) in buspair_indexes)
        #"tap"=>Float32(branches.tap[bp_branch[(i,j)]]),
        #"vm_fr_min"=>Float32(field(buses, :vmin)[i]),
        #"vm_fr_max"=>Float32(field(buses, :vmax)[i]),
        #"vm_to_min"=>Float32(field(buses, :vmin)[j]),
        #"vm_to_max"=>Float32(field(buses, :vmax)[j]),
    
    # add optional parameters
    #for bp in buspair_indexes
    #    buspairs[bp]["rate_a"] = branches.rate_a[bp_branch[bp]]
    #end
    return buspairs
end

""
function slack_buses(buses::Buses)

    ref_buses = Int[]
    for i in buses.keys
        if buses.bus_type[i] == 3
            push!(ref_buses, i)
        end
    end

    if length(ref_buses) > 1
        @error("multiple reference buses found, $(keys(ref_buses)), this can 
        cause infeasibility if they are in the same connected component")
    end

    return ref_buses

end

""
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
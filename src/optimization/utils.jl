topology(pm::AbstractPowerModel, subfield::Symbol) = getfield(getfield(pm, :topology), subfield)
topology(pm::AbstractPowerModel, subfield::Symbol, indx::Int) = getfield(getfield(pm, :topology), subfield)[indx]
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol) = getfield(getfield(getfield(pm, :topology), field), subfield)
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol, nw::Int) = getindex(getfield(getfield(getfield(pm, :topology), field), subfield), nw)

var(pm::AbstractPowerModel) = getfield(pm, :var)
var(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(pm, :var), field)
var(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(pm, :var), field), nw)
var(pm::AbstractPowerModel, field::Symbol, ::Colon) = getindex(getindex(getfield(pm, :var), field), 1)

con(pm::AbstractPowerModel) = getfield(pm, :con)
con(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(pm, :con), field)
con(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(pm, :con), field), nw)

BaseModule.field(topology::Topology, field::Symbol) = getfield(topology, field)
BaseModule.field(topology::Topology, field::Symbol, subfield::Symbol) = getfield(getfield(topology, field), subfield)
BaseModule.field(settings::Settings, field::Symbol) = getfield(settings, field)

""
function initialize_pm_containers!(pm::AbstractDCPowerModel, system::SystemModel; timeseries=false)

    @assert !timeseries "Timeseries containers not supported"
    #add_var_container!(pm.var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    add_var_container!(pm.var, :pg, field(system, :generators, :keys))
    add_var_container!(pm.var, :va, field(system, :buses, :keys))
    add_var_container!(pm.var, :z_branch, field(system, :branches, :keys))
    add_var_container!(pm.var, :z_demand, field(system, :loads, :keys))
    add_var_container!(pm.var, :z_shunt, field(system, :shunts, :keys))
    add_var_container!(pm.var, :p, field(pm.topology, :arcs))

    add_con_container!(pm.con, :power_balance_p, field(system, :buses, :keys))
    add_con_container!(pm.con, :ohms_yt_from_lower_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_from_upper_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_to_lower_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_to_upper_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :voltage_angle_diff_upper, field(system, :branches, :keys))
    add_con_container!(pm.con, :voltage_angle_diff_lower, field(system, :branches, :keys))
    add_con_container!(pm.con, :thermal_limit_from, field(system, :branches, :keys))
    add_con_container!(pm.con, :thermal_limit_to, field(system, :branches, :keys))

    add_var_container!(pm.var, :ps, field(system, :storages, :keys))
    add_var_container!(pm.var, :stored_energy, field(system, :storages, :keys))
    add_var_container!(pm.var, :sc, field(system, :storages, :keys))
    add_var_container!(pm.var, :sd, field(system, :storages, :keys))
    add_var_container!(pm.var, :sc_on, field(system, :storages, :keys))
    add_var_container!(pm.var, :sd_on, field(system, :storages, :keys))

    add_con_container!(pm.con, :storage_state, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_1, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_2, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_3, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_thermal_lower_limit, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_thermal_upper_limit, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    return
end

""
function initialize_pm_containers!(pm::AbstractLPACModel, system::SystemModel; timeseries=false)

    @assert !timeseries "Timeseries containers not supported"
    #add_var_container!(pm.var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    add_var_container!(pm.var, :pg, field(system, :generators, :keys))
    add_var_container!(pm.var, :qg, field(system, :generators, :keys))
    add_var_container!(pm.var, :va, field(system, :buses, :keys))
    add_var_container!(pm.var, :phi, field(system, :buses, :keys))
    add_var_container!(pm.var, :z_branch, field(system, :branches, :keys))
    add_var_container!(pm.var, :phi_fr, field(system, :branches, :keys))
    add_var_container!(pm.var, :phi_to, field(system, :branches, :keys))
    add_var_container!(pm.var, :td, field(system, :branches, :keys))
    add_var_container!(pm.var, :cs, field(system, :branches, :keys))
    add_var_container!(pm.var, :z_demand, field(system, :loads, :keys))
    add_var_container!(pm.var, :z_shunt, field(system, :shunts, :keys))
    add_var_container!(pm.var, :p, field(pm.topology, :arcs))
    add_var_container!(pm.var, :q, field(pm.topology, :arcs))

    add_con_container!(pm.con, :power_balance_p, field(system, :buses, :keys))
    add_con_container!(pm.con, :power_balance_q, field(system, :buses, :keys))
    add_con_container!(pm.con, :ohms_yt_from_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_to_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_from_q, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_to_q, field(system, :branches, :keys))
    add_con_container!(pm.con, :voltage_angle_diff_upper, field(system, :branches, :keys))
    add_con_container!(pm.con, :voltage_angle_diff_lower, field(system, :branches, :keys))

    add_con_container!(pm.con, :model_voltage, keys(field(system, :buspairs)))
    add_con_container!(pm.con, :model_voltage_upper, field(system, :branches, :keys))
    add_con_container!(pm.con, :model_voltage_lower, field(system, :branches, :keys))
    add_con_container!(pm.con, :relaxation_cos_upper, field(system, :branches, :keys))
    add_con_container!(pm.con, :relaxation_cos_lower, field(system, :branches, :keys))
    add_con_container!(pm.con, :relaxation_cos, field(system, :branches, :keys))
    add_con_container!(pm.con, :thermal_limit_from, field(system, :branches, :keys))
    add_con_container!(pm.con, :thermal_limit_to, field(system, :branches, :keys))

    add_var_container!(pm.var, :ccms, field(system, :storages, :keys))
    add_var_container!(pm.var, :ps, field(system, :storages, :keys))
    add_var_container!(pm.var, :qs, field(system, :storages, :keys))
    add_var_container!(pm.var, :qsc, field(system, :storages, :keys))
    add_var_container!(pm.var, :stored_energy, field(system, :storages, :keys))
    add_var_container!(pm.var, :sc, field(system, :storages, :keys))
    add_var_container!(pm.var, :sd, field(system, :storages, :keys))
    add_var_container!(pm.var, :sc_on, field(system, :storages, :keys))
    add_var_container!(pm.var, :sd_on, field(system, :storages, :keys))

    add_con_container!(pm.con, :storage_state, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_1, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_2, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_3, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_thermal_limit, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses_p, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses_q, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    return
end

""
function reset_model!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, settings::Settings, s)
    if iszero(s%100) && settings.optimizer == Gurobi
        JuMP.set_optimizer(pm.model, deepcopy(settings.optimizer); add_bridges = false)
        initialize_pm_containers!(pm, system)
        OPF.initialize_powermodel!(pm, system, states)
    else
        MOIU.reset_optimizer(pm.model)
    end
    return
end

""
function update_topology!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, settings::Settings, t::Int)
    if !check_availability(states.branches, t, t-1)
        simplify!(pm, system, states, settings, t)
        update_arcs!(pm, system, states.branches, t)
    end
    update_all_idxs!(pm, system, states, t)
    return
end

""
function bus_asset!(
    asset_dict_nodes::Dict{Int, Vector{Int}}, key_assets::Vector{Int}, asset_buses::Vector{Int})
    for k in key_assets
        push!(asset_dict_nodes[asset_buses[k]], k)
    end
    return asset_dict_nodes
end

""
function bus_asset!(busarcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}, arcs::Vector{Tuple{Int, Int, Int}})
    for (l,i,j) in arcs
        push!(busarcs[i], (l,i,j))
    end
    return busarcs
end

"""
Returns the container specification for the selected type of JuMP Model
"""
function _container_spec(::Type{T}, axs...) where {T <: Any}
    return DenseAxisArray{T}(undef, axs...)
end

""
function _container_spec(::Type{Float64}, axs...)
    cont = DenseAxisArray{Float64}(undef, axs...)
    #cont.data .= fill(NaN, size(cont.data))
    fill!(cont.data, 0.0)
    return cont
end

""
function container_spec(array::T, timesteps::UnitRange{Int}) where T <: AbstractArray
    tmp = DenseAxisArray{T}(undef, [i for i in timesteps])
    cont = fill!(tmp, array)
    return cont
end

""
function container_spec(dictionary::Dict{Tuple{Int, Int}, Any}, timesteps::UnitRange{Int})
    tmp = DenseAxisArray{Dict}(undef, [i for i in timesteps])
    cont = fill!(tmp, dictionary)
    return cont
end

""
function container_spec(
    dictionary::Dict{Tuple{Int, Int, Int}, Any}, timesteps::UnitRange{Int})
    tmp = DenseAxisArray{Dict}(undef, [i for i in timesteps])
    cont = fill!(tmp, dictionary)
    return cont
end

""
function add_sol_container!(
    container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: Matrix{Float64}}

    var_container = _container_spec(Float64, keys, timesteps)
    _assign_container!(container, var_key, var_container)
    return
end

""
function add_con_container!(
    container::Dict{Symbol, T}, con_key::Symbol, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_con_container!(
    container::Dict{Symbol, T}, con_key::Symbol, keys::Base.KeySet{Tuple{Int, Int}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_con_container!(
    container::Dict{Symbol, T}, con_key::Symbol, keys::Vector{Tuple{Int, Int}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_var_container!(
    container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.VariableRef, keys)
    var_container = container_spec(value, timesteps)
    _assign_container!(container, var_key, var_container)
    return
end


""
function add_var_container!(
    container::Dict{Symbol, T}, con_key::Symbol, keys::Base.KeySet{Tuple{Int, Int}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.VariableRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_var_container!(
    container::Dict{Symbol, T}, var_key::Symbol, dict_keys::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = Dict{Tuple{Int, Int}, Any}(((i,j), undef) for (i,j) in keys(dict_keys))
    var_container = container_spec(value, timesteps)
    _assign_container!(container, var_key, var_container)
    return var_container
end

""
function add_var_container!(
    container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Union{Missing, Tuple{Int, Int, Int}}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in keys)
    var_container = container_spec(value, timesteps)
    _assign_container!(container, var_key, var_container)
    return var_container
end

""
function _assign_container!(container::Dict, key::Symbol, value)
    #if haskey(container, key)
        #@error "$(key) is already stored"
    #end
    container[key] = value
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
function Base.getproperty(e::AbstractPowerModel, s::Symbol) 
    if s === :model 
        getfield(e, :model)::JuMP.Model
    elseif s===:topology 
        getfield(e, :topology)::Topology
    elseif s === :var
        getfield(e, :var)
    elseif s === :con
        getfield(e, :con) 
    elseif s === :sol
        getfield(e, :sol) 
    end
end

""
function Base.getproperty(e::Settings, s::Symbol) 
    if s === :optimizer 
        getfield(e, :optimizer)::MOI.OptimizerWithAttributes
    elseif s === :jump_modelmode 
        getfield(e, :jump_modelmode)::JuMP.ModelMode
    elseif s === :powermodel_formulation
        getfield(e, :powermodel_formulation)::Type
    elseif s === :select_largest_splitnetwork
        getfield(e, :select_largest_splitnetwork)::Bool
    elseif s === :deactivate_isolated_bus_gens_stors
        getfield(e, :deactivate_isolated_bus_gens_stors)::Bool
    elseif s === :min_generators_off
        getfield(e, :min_generators_off)::Int        
    elseif s === :set_string_names_on_creation
        getfield(e, :set_string_names_on_creation)::Bool
    elseif s === :count_samples
        getfield(e, :count_samples)::Bool
    elseif s === :record_branch_flow
        getfield(e, :record_branch_flow)::Bool        
    else
        @error("Configuration $(s) not supported")
    end
end

""
function reset_var_container!(container::DenseAxisArray{T}, keys::Vector{Union{Missing, Tuple{Int, Int, Int}}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: Dict}

    value = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in keys)
    for i in timesteps
        container[i] = value
    end
    return
end

""
function reset_var_container!(container::DenseAxisArray{T}, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.VariableRef, keys)
    for i in timesteps
        container[i] = value
    end
    return
end

""
function reset_con_container!(container::DenseAxisArray{T}, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    for i in timesteps
        container[i] = value
    end
    return
end

""
function update_idxs!(key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}})
    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
end

"Update asset_idxs and asset_nodes"
function update_idxs!(
    key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}}, 
    asset_dict_nodes::Dict{Int, Vector{Int}}, asset_buses::Vector{Int})

    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
    #map!(x -> Int[], asset_dict_nodes)
    for (_,v) in asset_dict_nodes
        empty!(v)
    end
    bus_asset!(asset_dict_nodes, key_assets, asset_buses)
end

"This function updates the arcs of the power system model."
function update_arcs!(pm::AbstractPowerModel, system::SystemModel, asset_states::Matrix{Bool}, t::Int)
    
    key_branches = assetgrouplist(topology(pm, :branches_idxs))

    for i in field(system, :branches, :keys)
        if asset_states[i,t] == false
            topology(pm, :arcs_from)[i] = missing
            topology(pm, :arcs_to)[i] = missing
        else
            topology(pm, :arcs_from)[i] = field(system, :arcs_from)[i]
            topology(pm, :arcs_to)[i] = field(system, :arcs_to)[i]
        end
    end
   
    topology(pm, :arcs)[:] = [topology(pm, :arcs_from); topology(pm, :arcs_to)]

    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))
    map!(x -> Int[], topology(pm, :busarcs))
    bus_asset!(topology(pm, :busarcs), arcs)

    update_buspair_parameters!(topology(pm, :buspairs), system.branches, key_branches)
    #vad_min,vad_max = calc_theta_delta_bounds(pm, system.branches)
    #topology(pm, :delta_bounds)[1] = vad_min
    #topology(pm, :delta_bounds)[2] = vad_max
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
function simplify!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, settings::Settings, t::Int)

    update_all_idxs!(pm, system, states, t)
    update_arcs!(pm, system, states.branches, t)

    revised = false
    changed = true

    while changed
        changed = false
        for i in field(system, :buses, :keys)
            if states.buses[i,t] ≠ 4
                incident_active_edge = 0
                busarcs_i = topology(pm, :busarcs)[i]
                if length(busarcs_i) > 0
                    incident_branch_count = sum([0; [states.branches[l,t] for (l,u,v) in busarcs_i]])
                    incident_active_edge = incident_branch_count
                end
                if incident_active_edge <= 1 && length(topology(pm, :bus_generators)[i]) == 0 && 
                    length(topology(pm, :bus_loads)[i]) == 0 && length(topology(pm, :bus_storages)[i]) == 0 && 
                    length(topology(pm, :bus_shunts)[i]) == 0
                    states.buses[i,t] = 4
                    changed = true
                    #@info("deactivating bus $(i) due to dangling bus without generation, load or storage")
                end
                if settings.deactivate_isolated_bus_gens_stors == true && incident_active_edge == 0 && 
                    length(topology(pm, :bus_generators)[i]) > 0
                    states.buses[i,t] = 4
                    changed = true
                end
            end
        end

        if changed
            for i in field(system, :branches, :keys)
                if states.branches[i,t] ≠ 0
                    f_bus = states.buses[field(system, :branches, :f_bus)[i], t]
                    t_bus = states.buses[field(system, :branches, :t_bus)[i], t]
                    if f_bus == 4 || t_bus == 4
                        states.branches[i,t] = 0
                        revised = true
                    end
                end
            end
            revised == true && update_idxs!(
                filter(i-> states.branches[i,t], field(system, :branches, :keys)), 
                topology(pm, :branches_idxs))

            changed == true && update_idxs!(
                filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), 
                topology(pm, :buses_idxs))
        end
    end

    ccs = calc_connected_components(pm.topology, system.branches)
    ccs_order = sort(collect(ccs); by=length)
    largest_cc = ccs_order[end]

    for i in field(system, :shunts, :buses)     # this step should be improved later. It ensures that the optimization algorithm solves the problem correctly.
        if !(i in largest_cc)
            for k in topology(pm, :bus_shunts)[i]
                states.shunts[k,t] = false
            end
        end
    end

    if length(ccs) > 1 && settings.select_largest_splitnetwork == true
        if system.ref_buses[1] in largest_cc && length(largest_cc) < length(system.buses)
            for i in field(system, :buses, :keys)
                if states.buses[i,t] ≠ 4 && !(i in largest_cc)
                    states.buses[i,t] = 4
                    #@info("select_largest_splitnetwork section: deactivating bus $(i) due to dangling isolated network section")            
                end
            end
        end
    end

    for cc in ccs
        cc_active_loads = [0]
        cc_active_shunts = [0]
        cc_active_gens = [0]
        cc_active_strg = [0]

        for i in cc
            cc_active_loads = push!(cc_active_loads, length(topology(pm, :bus_loads)[i]))
            cc_active_shunts = push!(cc_active_shunts, length(topology(pm, :bus_shunts)[i]))
            cc_active_gens = push!(cc_active_gens, length(topology(pm, :bus_generators)[i]))
            cc_active_strg = push!(cc_active_strg, length(topology(pm, :bus_storages)[i]))
        end

        active_load_count = sum(cc_active_loads)
        active_shunt_count = sum(cc_active_shunts)
        active_gen_count = sum(cc_active_gens)
        active_strg_count = sum(cc_active_strg)

        if (active_load_count == 0 && active_shunt_count == 0) || (active_gen_count == 0 && active_strg_count == 0)
            #@info("deactivating connected component $(cc) due to isolation without generation, load or storage, active_strg_count=$(active_strg_count)")
            for i in cc
                states.buses[i,t] = 4
                changed = true
            end
        end
    end

    for i in field(system, :branches, :keys)
        if states.branches[i,t] ≠ 0
            f_bus = states.buses[field(system, :branches, :f_bus)[i], t]
            t_bus = states.buses[field(system, :branches, :t_bus)[i], t]
            if f_bus == 4 || t_bus == 4
                states.branches[i,t] = 0
                revised = true
            end
        end
    end
    
    revised == true && update_idxs!(
        filter(i-> states.branches[i,t], field(system, :branches, :keys)), topology(pm, :branches_idxs)
    )
    changed == true && update_idxs!(
        filter(i-> states.buses[i,t] ≠ 4, field(system, :buses, :keys)), topology(pm, :buses_idxs)
    )

    for i in field(system, :buses, :keys)
        if states.buses[i,t] == 4
            for k in topology(pm, :bus_loads)[i]
                if states.loads[k,t] ≠ 0
                    states.loads[k,t] = 0
                end
            end
            for k in topology(pm, :bus_shunts)[i]
                if states.shunts[k,t] ≠ 0
                    states.shunts[k,t] = 0
                end
            end
            for k in topology(pm, :bus_generators)[i]
                if states.generators[k,t] ≠ 0
                    states.generators[k,t] = 0
                end
            end
            for k in topology(pm, :bus_storages)[i]
                if states.storages[k,t] ≠ 0
                    states.storages[k,t] = 0
                    if t > 1 
                        states.stored_energy[k,t] = states.stored_energy[k,t-1] 
                    end
                end
            end
        end
    end
    return
end

""
function update_all_idxs!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int)

    update_idxs!(filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), 
        topology(pm, :buses_idxs))

    update_idxs!(filter(i->states.branches[i,t], field(system, :branches, :keys)), 
        topology(pm, :branches_idxs))
    
    update_idxs!(
        filter(i->states.generators[i,t], field(system, :generators, :keys)), 
        topology(pm, :generators_idxs), topology(pm, :bus_generators), field(system, :generators, :buses))

    update_idxs!(
        filter(i->states.storages[i,t], field(system, :storages, :keys)), 
        topology(pm, :storages_idxs), topology(pm, :bus_storages), field(system, :storages, :buses))

    update_idxs!(
        filter(i->states.loads[i,t], field(system, :loads, :keys)), 
        topology(pm, :loads_idxs), topology(pm, :bus_loads), field(system, :loads, :buses))

    update_idxs!(
        filter(i->states.shunts[i,t], field(system, :shunts, :keys)), 
        topology(pm, :shunts_idxs), topology(pm, :bus_shunts), field(system, :shunts, :buses))

    return

end

""
function calc_branch_y(branches::Branches, i::Int)
    y = pinv(field(branches, :r)[i] + im * field(branches, :x)[i])
    g, b = real(y), imag(y)
    return g, b
end

""
function calc_branch_t(branches::Branches, i::Int)
    tr = field(branches, :tap)[i] .* cos.(field(branches, :shift)[i])
    ti = field(branches, :tap)[i] .* sin.(field(branches, :shift)[i])
    return tr, ti
end

"checks of any of the given keys are missing from the given dict"
function _check_missing_keys(dict, keys, type)
    missing = []
    for key in keys
        if !haskey(dict, key)
            push!(missing, key)
        end
    end
    if length(missing) > 0
        @error("the formulation $(type) requires the following varible(s) $(keys) 
                but the $(missing) variable(s) were not found in the model")
    end
end

""
function _phi_to_vm(solution::Dict)
    vm = Dict{Int, Float32}()
    for (i, phi) in solution
        get!(vm, i, 1.0 + phi)
    end
    return vm
end

""
function objective_value(opf_model::Model)
    obj_val = NaN
    try
        obj_val = JuMP.objective_value(opf_model)
    catch
    end
    return obj_val
end

""
function update!(pm::AbstractPowerModel, system::SystemModel{N}, states::ComponentStates, settings::Settings, t::Int; force_pmin::Bool=true) where N
    
    update_topology!(pm, system, states, settings, t)
    update_problem!(pm, system, states, t)
    
    JuMP.optimize!(pm.model)

    changes = any([
        length(system.storages) ≠ 0, 
        all(states.branches[:, t]) ≠ true,
        sum(states.generators[:, t]) < length(system.generators) - settings.min_generators_off])

    build_result!(pm, system, states, settings, t; changes=changes)
    return
end

""
function update_buspair_parameters!(buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}, branches::Branches, branch_lookup::Vector{Int})
 
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
    end
    
    dict = Dict((i,j) => [bp_branch[(i,j)],bp_angmin[(i,j)],bp_angmax[(i,j)]] for (i,j) in buspair_indexes)

    for bp in eachindex(buspairs)
        i,j = bp
        if !((i,j) in buspair_indexes)
            buspairs[bp] = missing
        else
            buspairs[bp] = dict[bp]
        end
    end
    
    return dict

end

""
function calc_theta_delta_bounds(pm::AbstractPowerModel, branches::Branches)

    bus_count = length(assetgrouplist(topology(pm, :buses_idxs)))
    branches_idxs = assetgrouplist(topology(pm, :branches_idxs))
    angle_min = Real[]
    angle_max = Real[]
    angle_mins = [field(branches, :angmin)[l] for l in branches_idxs]
    angle_maxs = [field(branches, :angmax)[l] for l in branches_idxs]
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
    angle_mins = [field(branches, :angmin)[l] for l in branches_idxs]
    angle_maxs = [field(branches, :angmax)[l] for l in branches_idxs]
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
function fill_curtailed_load!(
    pm::AbstractDCPowerModel, system::SystemModel, states::ComponentStates, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :z_demand, nw)
        for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0.0)
            if states.buses[i,t] != 4
                p_curtailed_factor = _IM.build_solution_values(var[i])
                states.p_curtailed[i] = bus_pd*(1.0 - p_curtailed_factor)
            else
                states.p_curtailed[i] = bus_pd
            end
        end
    else
        fill!(states.p_curtailed, 0.0)
    end
end

""
function fill_curtailed_load!(
    pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :z_demand, nw)
        for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0.0)
            bus_qd = sum(field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in topology(pm, :bus_loads_init)[i]; init=0)
            if states.buses[i,t] != 4
                p_curtailed_factor = _IM.build_solution_values(var[i])
                states.p_curtailed[i] = bus_pd*(1.0 - p_curtailed_factor)
                states.q_curtailed[i] = bus_qd*(1.0 - p_curtailed_factor)
            else
                states.p_curtailed[i] = bus_pd
                states.q_curtailed[i] = bus_qd
            end
        end
    else
        fill!(states.p_curtailed, 0.0)
        fill!(states.q_curtailed, 0.0)
    end
end

""
function fill_stored_energy!(
    pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; nw::Int=1, is_solved::Bool=true)

    for i in field(system, :storages, :keys)
        if is_solved
            var = OPF.var(pm, :stored_energy, nw)
            axs =  axes(var)[1]
            if i in axs
                states.stored_energy[i,t] = _IM.build_solution_values(var[i])
            else
                states.stored_energy[i,t] = states.stored_energy[i,t-1]
            end
        else
            states.stored_energy[i,t] = states.stored_energy[i,t-1]
        end
    end
end

""
function fill_flow_branch!(
    pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :p, nw)
        tuples = keys(var)
        for (l,i,j) in tuples
            if states.branches[l,t] == 0
                states.flow_from[l] = 0.0
                states.flow_to[l] = 0.0
            else
                f_bus = system.branches.f_bus[l]
                t_bus = system.branches.t_bus[l]
                #k = string((l,i,j))
                if f_bus == i && t_bus == j
                    states.flow_from[l] = _IM.build_solution_values(var[(l,i,j)]) # Active power withdrawn at the from bus
                elseif f_bus == j && t_bus == i
                    states.flow_to[l] = _IM.build_solution_values(var[(l,i,j)]) # Active power withdrawn at the to bus
                end
            end
        end
    else
        fill!(states.flow_from, 0.0)
        fill!(states.flow_to, 0.0)
    end
end

""
function fill_curtailed_load!(
    pm::AbstractDCPowerModel, system::SystemModel, states::ComponentStates, p_curtailed_factor::Dict{Int, Any}, t::Int)
    for i in field(system, :buses, :keys)
        bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0.0)
        if states.buses[i,t] == 4
            states.p_curtailed[i] = bus_pd
        else
            states.p_curtailed[i] = bus_pd*(1 - get(p_curtailed_factor, i, 1.0))
        end
    end
end

""
function fill_curtailed_load!(
    pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, p_curtailed_factor::Dict{Int, Any}, t::Int)
    for i in field(system, :buses, :keys)
        bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0)
        bus_qd = sum(field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in topology(pm, :bus_loads_init)[i]; init=0)
        if states.buses[i,t] == 4
            states.p_curtailed[i] = bus_pd
            states.q_curtailed[i] = bus_qd
        else
            states.p_curtailed[i] = bus_pd*(1 - get(p_curtailed_factor, i, 1.0))
            states.q_curtailed[i] = bus_qd*(1 - get(p_curtailed_factor, i, 1.0))
        end
    end
end

""
function fill_flow_branch!(system::SystemModel, states::ComponentStates, flow_branch::Dict{Int, Any}, t::Int)

    for l in field(system, :branches, :keys)
        if states.branches[l,t] == 0
            states.flow_from[l] = 0.0
            states.flow_to[l] = 0.0
        else
            flow_branch_dict = get(flow_branch, l, Dict{String, Any}("from"=>0.0, "to"=>0.0))
            states.flow_from[l] = flow_branch_dict["from"]
            states.flow_to[l] = flow_branch_dict["to"]
        end
    end
end

""
function fill_stored_energy!(storages::Storages, states::ComponentStates, stored_energy::Dict, t::Int; is_solved::Bool=true)
    for i in field(storages, :keys)
        if is_solved
            states.stored_energy[i,t] = get(stored_energy, i, 0.0)
        else
            states.stored_energy[i,t] = states.stored_energy[i,t-1]
        end
    end
end

"Build solution dictionary of the argunment of type DenseAxisArray"
function build_sol_values(var::DenseAxisArray)

    axs =  axes(var)[1]

    if typeof(axs) == Vector{Tuple{Int, Int}}
        sol = Dict{Tuple{Int, Int}, Any}()
    elseif typeof(axs) == Vector{Int}
        sol = Dict{Int, Any}()
    else
        typeof(axs) == Union{Vector{Tuple{Int, Int}}, Vector{Int}}
    end

    for key in axs
        sol[key] = _IM.build_solution_values(var[key])
    end

    return sol
end

""
build_sol_values(var::Dict{Tuple{Int, Int, Int}, Any}) = _IM.build_solution_values(var)

"Build solution dictionary of active flows per branch"
function build_sol_values(var::Dict{Tuple{Int, Int, Int}, JuMP.VariableRef}, branches::Branches)

    dict_p = sort(_IM.build_solution_values(var))
    tuples = keys(sort(var))
    sol = Dict{Int, Any}()

    for (l,i,j) in tuples
        k = string((l,i,j))
        if !haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol, l, Dict{String, Any}("from"=>dict_p[k])) # Active power withdrawn at the from bus
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol, l, Dict{String, Any}("to"=>dict_p[k])) # Active power withdrawn at the to bus
            end
        elseif haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol[l], "from", dict_p[k])
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol[l], "to", dict_p[k])
            end
        end
    end
    return sol
end

"Build solution dictionary of active flows per branch"
function build_sol_values(var::Dict{Tuple{Int, Int, Int}, Any}, branches::Branches)

    dict_p = sort(_IM.build_solution_values(var))
    tuples = keys(sort(var))
    sol = Dict{Int, Any}()

    for (l,i,j) in tuples
        k = string((l,i,j))
        if !haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol, l, Dict{String, Any}("from"=>dict_p[k])) # Active power withdrawn at the from bus
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol, l, Dict{String, Any}("to"=>dict_p[k])) # Active power withdrawn at the to bus
            end
        elseif haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol[l], "from", dict_p[k])
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol[l], "to", dict_p[k])
            end
        end
    end
    return sol
end

"It checks if all elements in the matrix are true for both the current time step and the previous time step, 
and returns false if this condition is not met."
function check_availability(asset_states::Matrix{Bool}, t_now::Int, t_previous::Int)::Bool
    @views t_now_view = asset_states[:, t_now]
    if t_previous ≠ 0
        @views t_previous_view = asset_states[:, t_previous]
        return !any(t_now_view .== 0) && !any(t_previous_view .== 0)
    else
        #return !any(t_now_view .== 0) && !any(t_now_view .== 0)
        return false
    end
end

""
function check_availability(asset_states::Matrix{Int}, t_now::Int, t_previous::Int)::Bool
    @views t_now_view = asset_states[:, t_now]
    if t_previous ≠ 0
        @views t_previous_view = asset_states[:, t_previous]
        return !any(t_now_view .== 4) && !any(t_previous_view .== 4)
    else
        #return !any(t_now_view .== 4) && !any(t_now_view .== 4)
        return false
    end
end
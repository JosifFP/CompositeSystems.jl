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
    if s === :gurobi_env 
        getfield(e, :gurobi_env)::Union{Gurobi.Env, Nothing}
    elseif s === :optimizer 
        getfield(e, :optimizer)::Union{MOI.OptimizerWithAttributes, Nothing}
    elseif s === :jump_modelmode 
        getfield(e, :jump_modelmode)::JuMP.ModelMode
    elseif s === :powermodel_formulation
        getfield(e, :powermodel_formulation)::Type
    elseif s === :select_largest_splitnetwork
        getfield(e, :select_largest_splitnetwork)::Bool
    elseif s === :deactivate_isolated_bus_gens_stors
        getfield(e, :deactivate_isolated_bus_gens_stors)::Bool  
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


"update_topology! function updates the whole topology after outages have been identified.
This process requires to simplify the grid (disconnect buses and other components) in case 
of extreme events, using an iterative approach. simplify! function is not required without
transmission outages."
function update_topology!(
    pm::AbstractPowerModel, system::SystemModel, states::States, settings::Settings, t::Int)

    any([states.branches_available; states.branches_pasttransition].== 0
    ) && simplify!(pm, system, states, settings)
    
    update_all_buses_assets!(pm, system, states)

    update_stored_energy!(topology(pm, :stored_energy), states.storages_available, system.storages)

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
function simplify!(pm::AbstractPowerModel, system::SystemModel, states::States, settings::Settings)

    update_all_buses_assets!(pm, system, states)
    update_arcs!(pm, system, states.branches_available)
    key_buses = field(system, :buses, :keys)
    key_branches = field(system, :branches, :keys)

    revised = false
    changed = true

    while changed

        changed = false

        for i in key_buses
            if states.buses_available[i] ≠ 4
                incident_active_edge = 0
                busarcs_i = topology(pm, :busarcs)[i]
                if length(busarcs_i) > 0
                    incident_branch_count = sum([0; [states.branches_available[l] for (l,u,v) in busarcs_i]])
                    incident_active_edge = incident_branch_count
                end
                if incident_active_edge <= 1 && length(topology(pm, :buses_generators_available)[i]) == 0 && 
                    length(topology(pm, :buses_loads_available)[i]) == 0 && length(topology(pm, :buses_storages_available)[i]) == 0 && 
                    length(topology(pm, :buses_shunts_available)[i]) == 0
                    states.buses_available[i] = 4
                    changed = true
                    #@info("deactivating bus $(i) due to dangling bus without generation, load or storage")
                end
                if settings.deactivate_isolated_bus_gens_stors == true && incident_active_edge == 0 && 
                    length(topology(pm, :buses_generators_available)[i]) > 0
                    states.buses_available[i] = 4
                    changed = true
                end
            end
        end

        if changed
            for l in key_branches
                if states.branches_available[l] ≠ 0
                    f_bus = states.buses_available[field(system, :branches, :f_bus)[l]]
                    t_bus = states.buses_available[field(system, :branches, :t_bus)[l]]
                    if f_bus == 4 || t_bus == 4
                        states.branches_available[l] = 0
                        revised = true
                    end
                end
            end
            
            revised == true && update_idxs!(
                filter(l-> states.branches_available[l], key_branches), topology(pm, :branches_idxs))

            changed == true && update_idxs!(
                filter(i->states.buses_available[i] ≠ 4, key_buses), topology(pm, :buses_idxs))
        end
    end

    ccs = calc_connected_components(pm.topology, system.branches)
    ccs_order = sort(collect(ccs); by=length)
    largest_cc = ccs_order[end]

    for i in field(system, :shunts, :buses)     # this step should be improved later. It ensures that the optimization algorithm solves the problem correctly.
        if !(i in largest_cc)
            for k in topology(pm, :buses_shunts_available)[i]
                states.shunts_available[k] = false
            end
        end
    end

    if length(ccs) > 1 && settings.select_largest_splitnetwork == true
        if system.ref_buses[1] in largest_cc && length(largest_cc) < length(system.buses)
            for i in key_buses
                if states.buses_available[i] ≠ 4 && !(i in largest_cc)
                    states.buses_available[i] = 4
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
            cc_active_loads = push!(cc_active_loads, length(topology(pm, :buses_loads_available)[i]))
            cc_active_shunts = push!(cc_active_shunts, length(topology(pm, :buses_shunts_available)[i]))
            cc_active_gens = push!(cc_active_gens, length(topology(pm, :buses_generators_available)[i]))
            cc_active_strg = push!(cc_active_strg, length(topology(pm, :buses_storages_available)[i]))
        end

        active_load_count = sum(cc_active_loads)
        active_shunt_count = sum(cc_active_shunts)
        active_gen_count = sum(cc_active_gens)
        active_strg_count = sum(cc_active_strg)

        if (active_load_count == 0 && active_shunt_count == 0) || (active_gen_count == 0 && active_strg_count == 0)
            #@info("deactivating connected component $(cc) due to isolation without 
            #generation, load or storage, active_strg_count=$(active_strg_count)")
            for i in cc
                states.buses_available[i] = 4
                changed = true
            end
        end
    end

    for l in key_branches
        if states.branches_available[l] ≠ 0
            f_bus = states.buses_available[field(system, :branches, :f_bus)[l]]
            t_bus = states.buses_available[field(system, :branches, :t_bus)[l]]
            if f_bus == 4 || t_bus == 4
                states.branches_available[l] = 0
                revised = true
            end
        end
    end
    
    revised == true && update_idxs!(
        filter(l-> states.branches_available[l], key_branches), topology(pm, :branches_idxs))

    changed == true && update_idxs!(
        filter(i-> states.buses_available[i] ≠ 4, key_buses), topology(pm, :buses_idxs))

    revised == true && update_arcs!(pm, system, states.branches_available)

    for i in key_buses
        if states.buses_available[i] == 4
            for k in topology(pm, :buses_loads_available)[i]
                if states.loads_available[k] ≠ 0
                    states.loads_available[k] = 0
                end
            end
            for k in topology(pm, :buses_shunts_available)[i]
                if states.shunts_available[k] ≠ 0
                    states.shunts_available[k] = 0
                end
            end
            for k in topology(pm, :buses_generators_available)[i]
                if states.generators_available[k] ≠ 0
                    states.generators_available[k] = 0
                end
            end
            for k in topology(pm, :buses_storages_available)[i]
                if states.storages_available[k] ≠ 0
                    states.storages_available[k] = 0
                end
                topology(pm, :stored_energy)[k] = 0  #ES is discharged once it gets disconnected from the grid.
            end
        end
    end
    return
end

""
function update_all_buses_assets!(
    pm::AbstractPowerModel, system::SystemModel, states::States)

    update_idxs!(
        filter(i->states.branches_available[i], field(system, :branches, :keys)), 
        topology(pm, :branches_idxs))

    update_idxs!(
        filter(i->states.buses_available[i] ≠ 4, field(system, :buses, :keys)), 
        topology(pm, :buses_idxs))

    update_idxs!(
        filter(i->states.generators_available[i], field(system, :generators, :keys)), 
        topology(pm, :generators_idxs), 
        topology(pm, :buses_generators_available), 
        field(system, :generators, :buses))

    update_idxs!(
        filter(i->states.storages_available[i], field(system, :storages, :keys)), 
        topology(pm, :storages_idxs), 
        topology(pm, :buses_storages_available), 
        field(system, :storages, :buses))

    update_idxs!(
        filter(i->states.loads_available[i], field(system, :loads, :keys)), 
        topology(pm, :loads_idxs), 
        topology(pm, :buses_loads_available), 
        field(system, :loads, :buses))

    update_idxs!(
        filter(i->states.shunts_available[i], field(system, :shunts, :keys)), 
        topology(pm, :shunts_idxs), 
        topology(pm, :buses_shunts_available), 
        field(system, :shunts, :buses))
    return
end

"This function is required in case reconnected storage devices are completely discharged."
function update_stored_energy!(
    stored_energy::Vector{Float64}, storages_available::Vector{Bool}, asset::Storages)

    for i in field(asset, :keys)
        if !storages_available[i]
            stored_energy[i] = 0.0
        end
    end
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

    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
    #map!(x -> Int[], asset_dict_nodes)
    for (_,v) in asset_dict_nodes
        empty!(v)
    end
    buses_asset!(asset_dict_nodes, key_assets, asset_buses)
end

"This function updates the arcs of the power system model."
function update_arcs!(pm::AbstractPowerModel, system::SystemModel, asset_states::Vector{Bool})

    for i in field(system, :branches, :keys)
        if asset_states[i] == false
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

    buses_asset!(topology(pm, :busarcs), arcs)

    update_buspair_parameters!(
        topology(pm, :buspairs), system.branches, assetgrouplist(topology(pm, :branches_idxs)))
    #vad_min,vad_max = calc_theta_delta_bounds(pm, system.branches)
    #topology(pm, :delta_bounds)[1] = vad_min
    #topology(pm, :delta_bounds)[2] = vad_max
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
function update_buspair_parameters!(
    buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}, branches::Branches, branch_lookup::Vector{Int})
 
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

"This function is used to build the results of the optimization problem for the DC Power Model. 
It first checks if the optimization problem has been solved optimally or locally, and if so, 
it retrieves the values of the variables z_demand and stored_energy from the solution and updates 
the corresponding fields in the states struct."
function build_result!(
    pm::AbstractPowerModel, system::SystemModel, 
    states::States, settings::Settings, t::Int; nw::Int=1)

    is_solved = any([
        JuMP.termination_status(pm.model) == JuMP.LOCALLY_SOLVED, 
        JuMP.termination_status(pm.model) == JuMP.OPTIMAL]) 
        # Check if the problem was solved optimally or locally

    settings.record_branch_flow && fill_flow_branch!(pm, system, states, t, is_solved=is_solved)

    record_curtailed_load!(pm, system, states, t, is_solved=is_solved)

    record_stored_energy!(pm, system, states, t, is_solved=is_solved)

    return
end

""
function record_curtailed_load!(pm::AbstractDCPowerModel, 
    system::SystemModel, states::States, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :z_demand, nw)
        for i in field(system, :buses, :keys)
            
            topology(pm, :buses_curtailed_pd)[i] = sum(
                field(system, :loads, :pd)[k,t]*(1.0 - _IM.build_solution_values(var[k])) 
                for k in topology(pm, :buses_loads_base)[i]; init=0.0)

        end
    else
        fill!(topology(pm, :buses_curtailed_pd), 0.0)
    end
end

""
function record_curtailed_load!(pm::AbstractPowerModel, 
    system::SystemModel, states::States, t::Int; nw::Int=1, is_solved::Bool=true)


    if is_solved
        var = OPF.var(pm, :z_demand, nw)
        for i in field(system, :buses, :keys)
            
            topology(pm, :buses_curtailed_pd)[i] = sum(
                field(system, :loads, :pd)[k,t]*(1.0 - _IM.build_solution_values(var[k])) 
                for k in topology(pm, :buses_loads_base)[i]; init=0.0)

            topology(pm, :buses_curtailed_qd)[i] = sum(
                field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k]*
                (1.0 - _IM.build_solution_values(var[k])) 
                for k in topology(pm, :buses_loads_base)[i]; init=0.0)

        end
    else
        fill!(topology(pm, :buses_curtailed_pd), 0.0)
        fill!(topology(pm, :buses_curtailed_qd), 0.0)
    end
end

""
function record_stored_energy!(pm::AbstractPowerModel, 
    system::SystemModel, states::States, t::Int; nw::Int=1, is_solved::Bool=true)
    
    if is_solved
        for i in field(system, :storages, :keys)
            if states.storages_available[i]
                var = OPF.var(pm, :stored_energy, nw)
                axs =  axes(var)[1]
                if i in axs
                    topology(pm, :stored_energy)[i] = _IM.build_solution_values(var[i])
                end
            else
                topology(pm, :stored_energy)[i] = 0.0
            end
        end
    else
        fill!(topology(pm, :stored_energy), 0.0)
    end
end

""
function fill_flow_branch!(pm::AbstractPowerModel, 
    system::SystemModel, states::States, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :p, nw)
        for (l,i,j) in keys(var)
            if states.branches_available[l] ≠ 0
                f_bus = system.branches.f_bus[l]
                t_bus = system.branches.t_bus[l]
                if f_bus == i && t_bus == j
                    topology(pm, :branches_flow_from)[l] = _IM.build_solution_values(var[(l,i,j)]) # Active power withdrawn at the from bus
                elseif f_bus == j && t_bus == i
                    topology(pm, :branches_flow_to)[l] = _IM.build_solution_values(var[(l,i,j)]) # Active power withdrawn at the to bus
                end
            else
                topology(pm, :branches_flow_from)[l] = 0.0
                topology(pm, :branches_flow_to)[l] =  0.0
            end
        end
    else
        fill(topology(pm, :branches_flow_from), 0.0)
        fill(topology(pm, :branches_flow_to), 0.0)
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

""
function peakload(loads::Loads{N}, buses::Buses) where {N}
    
    key_buses = field(buses, :keys)
    buses_loads_base = Dict{Int, Vector{Float64}}((i, Float64[]) for i in key_buses)
    
    for k in field(loads, :keys)
        push!(buses_loads_base[field(loads, :buses)[k]], maximum(loads.pd[k,:]))
    end

    bus_peakload = Array{Float64}(undef, length(buses))

    for (k,v) in buses_loads_base
        if !isempty(v)
            bus_peakload[k] = sum(v)
        else
            bus_peakload[k] = 0.0
        end
    end

    system_peakload = Float64(maximum(sum(loads.pd, dims=1)))
    return system_peakload, bus_peakload
end

""
function finalize_model!(pm::AbstractPowerModel, env::Gurobi.Env)

    Base.finalize(JuMP.backend(pm.model).optimizer)
    Base.finalize(env)
    return
end

""
function finalize_model!(pm::AbstractPowerModel, settings::Settings)

    Base.finalize(JuMP.backend(pm.model).optimizer)
    Base.finalize(settings.env)
    return
end

function _reset!(
    pm::AbstractPowerModel, state::States, system::SystemModel)

    fill!(state.branches_available, 1)
    fill!(topology(pm, :branches_flow_from), 0)
    fill!(topology(pm, :branches_flow_to), 0)
    fill!(state.generators_available, 1)
    fill!(state.storages_available, 1)
    fill!(topology(pm, :buses_curtailed_pd), 0)
    fill!(topology(pm, :buses_curtailed_qd), 0)
    fill!(state.loads_available, 1)
    fill!(state.shunts_available, 1)
    fill!(state.commonbranches_available, 1)

    for k in 1:length(system.buses)
        state.buses_available[k] = field(system, :buses, :bus_type)[k]
    end
    return
end
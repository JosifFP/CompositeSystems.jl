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

#sol(pm::AbstractPowerModel) = getfield(pm, :sol)
#sol(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(pm, :sol), field)
#sol(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(pm, :sol), field), :, nw)

BaseModule.field(topology::Topology, field::Symbol) = getfield(topology, field)
BaseModule.field(topology::Topology, field::Symbol, subfield::Symbol) = getfield(getfield(topology, field), subfield)
BaseModule.field(settings::Settings, field::Symbol) = getfield(settings, field)

""
function bus_asset!(asset_dict_nodes::Dict{Int, Vector{Int}}, key_assets::Vector{Int}, asset_buses::Vector{Int})
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
function container_spec(dictionary::Dict{Tuple{Int, Int, Int}, Any}, timesteps::UnitRange{Int})
    tmp = DenseAxisArray{Dict}(undef, [i for i in timesteps])
    cont = fill!(tmp, dictionary)
    return cont
end

""
function add_sol_container!(container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Int}; timesteps::UnitRange{Int}=1:1) where {T <: Matrix{Float64}}

    var_container = _container_spec(Float64, keys, timesteps)
    _assign_container!(container, var_key, var_container)
    return
end

""
function add_var_container!(container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Int}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.VariableRef, keys)
    var_container = container_spec(value, timesteps)
    _assign_container!(container, var_key, var_container)
    return
end

""
function add_con_container!(container::Dict{Symbol, T}, con_key::Symbol, keys::Vector{Int}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_con_container!(container::Dict{Symbol, T}, con_key::Symbol, keys::Base.KeySet{Tuple{Int, Int}}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_con_container!(container::Dict{Symbol, T}, con_key::Symbol, keys::Vector{Tuple{Int, Int}}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_var_container!(container::Dict{Symbol, T}, var_key::Symbol, dict_keys::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = Dict{Tuple{Int, Int}, Any}(((i,j), undef) for (i,j) in keys(dict_keys))
    var_container = container_spec(value, timesteps)
    _assign_container!(container, var_key, var_container)
    return var_container
end

""
function add_var_container!(container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Union{Missing, Tuple{Int, Int, Int}}}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

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
            PowerModels._cc_dfs(i, neighbors, component_lookup, touched)
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
    elseif s===:modelmode 
        getfield(e, :modelmode)::JuMP.ModelMode
    elseif s === :powermodel
        getfield(e, :powermodel)::Type
    end
end

""
function reset_var_container!(container::DenseAxisArray{T}, keys::Vector{Union{Missing, Tuple{Int, Int, Int}}}; timesteps::UnitRange{Int}=1:1) where {T <: Dict}

    value = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in keys)
    for i in timesteps
        container[i] = value
    end
    return
end

""
function reset_var_container!(container::DenseAxisArray{T}, keys::Vector{Int}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.VariableRef, keys)
    for i in timesteps
        container[i] = value
    end
    return
end

""
function reset_con_container!(container::DenseAxisArray{T}, keys::Vector{Int}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

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
function update_idxs!(key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}}, asset_dict_nodes::Dict{Int, Vector{Int}}, asset_buses::Vector{Int})

    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
    map!(x -> Int[], asset_dict_nodes)
    bus_asset!(asset_dict_nodes, key_assets, asset_buses)

end

""
function update_arcs!(pm::AbstractPowerModel, system::SystemModel, asset_states::Matrix{Bool}, t::Int)
    
    key_branches = assetgrouplist(topology(pm, :branches_idxs))

    for i in eachindex(key_branches)
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

    buspairs = BaseModule.calc_buspair_parameters(field(system, :branches), key_branches)
    for (i,j) in eachindex(field(system, :buspairs))
        if !haskey(buspairs,(i,j))
            topology(pm, :buspairs)[(i,j)] = missing
        else
            topology(pm, :buspairs)[(i,j)] = buspairs[(i,j)]
        end
    end
    return

end

""
function simplify!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; isolated::Bool=false)

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
                if incident_active_edge == 1 && length(topology(pm, :bus_generators)[i]) == 0 && 
                    length(topology(pm, :bus_loads)[i]) == 0 && length(topology(pm, :bus_storages)[i]) == 0 &&
                    length(topology(pm, :bus_shunts)[i]) == 0
                    states.buses[i,t] = 4
                    changed = true
                    #@info("deactivating bus $(i) due to dangling bus without generation, load or storage")
                elseif incident_active_edge == 0 && isolated == true
                    states.buses[i,t] = 4
                    changed = true
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
                        end
                    end
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
            revised == true && update_idxs!(filter(i-> states.branches[i,t], field(system, :branches, :keys)), topology(pm, :branches_idxs))
            changed == true && update_idxs!(filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), topology(pm, :buses_idxs))
        end
    end

    ccs = OPF.calc_connected_components(pm.topology, field(system, :branches))

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

        if (active_load_count == 0 && active_shunt_count == 0 && active_strg_count == 0) || active_gen_count == 0
            #@info("deactivating connected component $(cc) due to isolation without generation, load or storage")
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
                #revised = true
            end
        end
    end
    
    changed == true && update_idxs!(filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), topology(pm, :buses_idxs))

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
                end
            end
        end
    end

    return

end

""
function update_all_idxs!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    update_idxs!(filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), topology(pm, :buses_idxs))
    update_idxs!(filter(i->states.branches[i,t], field(system, :branches, :keys)), topology(pm, :branches_idxs))
    
    update_idxs!(
        filter(i->states.generators[i,t], field(system, :generators, :keys)), 
        topology(pm, :generators_idxs), topology(pm, :bus_generators), field(system, :generators, :buses)
    )

    update_idxs!(
        filter(i->states.storages[i,t], field(system, :storages, :keys)), 
        topology(pm, :storages_idxs), topology(pm, :bus_storages), field(system, :storages, :buses)
    )

    update_idxs!(
        filter(i->states.loads[i,t], field(system, :loads, :keys)), 
        topology(pm, :loads_idxs), topology(pm, :bus_loads), field(system, :loads, :buses)
    )

    update_idxs!(
        filter(i->states.shunts[i,t], field(system, :shunts, :keys)), 
        topology(pm, :shunts_idxs), topology(pm, :bus_shunts), field(system, :shunts, :buses)
    )

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
        @error("the formulation $(type) requires the following varible(s) $(keys) but the $(missing) variable(s) were not found in the model")
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
function _update!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; force_pmin::Bool=false)  

    _update_topology!(pm, system, states, t)
    _update_method!(pm, system, states, t, force_pmin=force_pmin)
    optimize_method!(pm)
    build_result!(pm, system, states, t)
    return

end
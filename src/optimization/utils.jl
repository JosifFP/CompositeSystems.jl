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

con(pm::AbstractPowerModel) = getfield(pm, :con)
con(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(pm, :con), field)
con(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(pm, :con), field), nw)

sol(pm::AbstractPowerModel) = getfield(pm, :sol)
sol(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(pm, :sol), field)
sol(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(pm, :sol), field), :, nw)

BaseModule.field(topology::Topology, field::Symbol) = getfield(topology, field)
BaseModule.field(topology::Topology, field::Symbol, subfield::Symbol) = getfield(getfield(topology, field), subfield)
BaseModule.field(settings::Settings, field::Symbol) = getfield(settings, field)

""
function bus_asset!(tmp::Dict{Int, Vector{Int}}, key_assets::Vector{Int}, bus_assets::Vector{Int})
    for k in key_assets
        push!(tmp[bus_assets[k]], k)
    end
    return tmp
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
function add_var_container!(container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Tuple{Int, Int, Int}}; timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

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
function calc_buspair_parameters(branches::Branches, branch_lookup::Vector{Int})
 
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)
    
    for l in branch_lookup
        i = branches.f_bus[l]
        j = branches.t_bus[l]
        bp_angmin[(i,j)] = Float16(max(bp_angmin[(i,j)], branches.angmin[l]))
        bp_angmax[(i,j)] = Float16(min(bp_angmax[(i,j)], branches.angmax[l]))
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    
    buspairs = Dict((i,j) => [bp_branch[(i,j)],bp_angmin[(i,j)],bp_angmax[(i,j)]] for (i,j) in buspair_indexes)
        #"tap"=>Float16(branches.tap[bp_branch[(i,j)]]),
        #"vm_fr_min"=>Float16(field(buses, :vmin)[i]),
        #"vm_fr_max"=>Float16(field(buses, :vmax)[i]),
        #"vm_to_min"=>Float16(field(buses, :vmin)[j]),
        #"vm_to_max"=>Float16(field(buses, :vmax)[j]),
    
    # add optional parameters
    #for bp in buspair_indexes
    #    buspairs[bp]["rate_a"] = branches.rate_a[bp_branch[bp]]
    #end
    
    return buspairs

end

"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses, branches)

    bus_lookup = Dict(bus["index"] => bus for (i,bus) in buses if bus["bus_type"] ≠ 4)
    branch_lookup = Dict(branch["index"] => branch for (i,branch) in branches if branch["br_status"] == 1 && 
        haskey(bus_lookup, branch["f_bus"]) && haskey(bus_lookup, branch["t_bus"]))
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
        #"vm_fr_min"=>bus_lookup[i]["vmin"],
        #"vm_fr_max"=>bus_lookup[i]["vmax"],
        #"vm_to_min"=>bus_lookup[j]["vmin"],
        #"vm_to_max"=>bus_lookup[j]["vmax"]
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
function reset_var_container!(container::DenseAxisArray{T}, keys::Vector{Tuple{Int, Int, Int}}; timesteps::UnitRange{Int}=1:1) where {T <: Dict}

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
function empty_model!(pm::AbstractDCPowerModel)

    JuMP.empty!(pm.model)
    MOIU.reset_optimizer(pm.model)
    fill!(sol(pm, :plc), 0.0)

    return
end

""
function reset_containers!(pm::AbstractDCPowerModel, system::SystemModel{N}) where {N}

    reset_var_container!(var(pm, :pg), field(system, :generators, :keys))
    reset_var_container!(var(pm, :va), field(system, :buses, :keys))
    reset_var_container!(var(pm, :plc), field(system, :loads, :keys))
    reset_var_container!(var(pm, :p), topology(pm, :arcs))
    reset_con_container!(con(pm, :power_balance), field(system, :buses, :keys))
    reset_con_container!(con(pm, :ohms_yt_from), field(system, :branches, :keys))
    reset_con_container!(con(pm, :ohms_yt_to), field(system, :branches, :keys))
    reset_con_container!(con(pm, :voltage_angle_diff_upper), field(system, :branches, :keys))
    reset_con_container!(con(pm, :voltage_angle_diff_lower), field(system, :branches, :keys))
    return

end

""
function reset_model!(pm::AbstractDCPowerModel, system::SystemModel, settings::Settings, s)


    if iszero(s%10) && settings.optimizer == Ipopt
        JuMP.set_optimizer(pm.model, deepcopy(settings.optimizer); add_bridges = false)
    elseif iszero(s%50) && settings.optimizer == Gurobi
        JuMP.set_optimizer(pm.model, deepcopy(settings.optimizer); add_bridges = false)
    else
        MOIU.reset_optimizer(pm.model)
    end

    fill!(sol(pm, :plc), 0.0)

    return

end

""
function update_asset_nodes!(key_assets::Vector{Int}, bus_assets::Dict{Int, Vector{Int}}, buses::Vector{Int})
    @inbounds for k in key_assets
        push!(bus_assets[buses[k]], k)
    end
end

""
function update_idxs!(key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}})
    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
end

"Update asset_idxs and asset_nodes"
function update_idxs!(key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}}, bus_assets::Dict{Int, Vector{Int}}, buses::Vector{Int})
    
    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
    map!(x -> Int[], bus_assets)
    update_asset_nodes!(key_assets, bus_assets, buses)

end

""
function update_arcs!(branches::Branches, actual_topology::Topology, initial_topology::Topology, asset_states::Matrix{Bool}, t::Int)
    
    state = view(asset_states, :, t)
    
    for i in eachindex(state)

        f_bus = field(branches, :f_bus)[i]
        t_bus = field(branches, :t_bus)[i]

        if state[i] == false
            field(actual_topology, :busarcs)[:,i] = Array{Missing}(undef, size(field(actual_topology, :busarcs),1))
            field(actual_topology, :arcs_from)[i] = missing
            field(actual_topology, :arcs_to)[i] = missing
            field(actual_topology, :buspairs)[(f_bus, t_bus)] = missing
        else
            field(actual_topology, :busarcs)[:,i] = field(initial_topology, :busarcs)[:,i]
            field(actual_topology, :arcs_from)[i] = field(initial_topology, :arcs_from)[i]
            field(actual_topology, :arcs_to)[i] = field(initial_topology, :arcs_to)[i]
            field(actual_topology, :buspairs)[(f_bus, t_bus)] = field(initial_topology, :buspairs)[(f_bus, t_bus)]
        end
    end
   
    field(actual_topology, :arcs)[:] = [field(actual_topology, :arcs_from); field(actual_topology, :arcs_to)]

end
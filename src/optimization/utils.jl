field(topology::Topology, field::Symbol) = getfield(topology, field)
field(topology::Topology, field::Symbol, subfield::Symbol) = getfield(getfield(topology, field), subfield)
field(settings::Settings, field::Symbol) = getfield(settings, field)

topology(pm::AbstractPowerModel, subfield::Symbol) = getfield(getfield(pm, :topology), subfield)
topology(pm::AbstractPowerModel, subfield::Symbol, indx::Int) = getfield(getfield(pm, :topology), subfield)[indx]
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol) = getfield(getfield(getfield(pm, :topology), field), subfield)
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol, nw::Int) = getindex(getfield(getfield(getfield(pm, :topology), field), subfield), nw)

var(pm::AbstractPowerModel) = getfield(pm, :var)
var(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(getfield(pm, :var), :object), field)
var(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(getfield(pm, :var), :object), field), nw)

sol(pm::AbstractPowerModel) = getfield(pm, :sol)
sol(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(getfield(pm, :sol), :object), field)
sol(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(getfield(pm, :sol), :object), field), :, nw)

""
function JumpModel(modelmode::JuMP.ModelMode, optimizer)
    if modelmode == JuMP.AUTOMATIC
        jumpmodel = Model(optimizer; add_bridges = false)
    elseif modelmode == JuMP.DIRECT
        @warn("Direct Mode is unsafe")
        jumpmodel = direct_model(optimizer)
    else
        @warn("Manual Mode not supported")
    end
    JuMP.set_string_names_on_creation(jumpmodel, false)
    JuMP.set_silent(jumpmodel)
    #GC.gc()
    return jumpmodel
end

"Constructor for an AbstractPowerModel modeling object"
function Initialize_model(system::SystemModel{N}, topology::Topology, settings::Settings) where {N}
    
    model = JumpModel(field(settings, :modelmode), field(settings, :optimizer))
    
    var = DatasetContainer{AbstractArray}()
    add_object_container!(var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    add_object_container!(var, :va, field(system, :buses, :keys), timesteps = 1:N)
    add_object_container!(var, :plc, field(system, :loads, :keys), timesteps = 1:N)
    add_object_container!(var, :p, field(system, :arcs, :arcs), timesteps = 1:N)

    sol = DatasetContainer{Matrix{Float64}}()
    add_object_container!(sol, :plc, field(system, :loads, :keys), timesteps = 1:N)

    return DCPPowerModel(model, topology, var, sol)

end

""
function empty_model!(system::SystemModel{N}, pm::AbstractDCPowerModel) where {N}

    empty!(pm.model)
    MathOptInterface.Utilities.reset_optimizer(pm.model)
    reset_object_container!(var(pm, :pg), field(system, :generators, :keys), timesteps=1:N)
    reset_object_container!(var(pm, :va), field(system, :buses, :keys), timesteps=1:N)
    reset_object_container!(var(pm, :plc), field(system, :loads, :keys), timesteps=1:N)
    reset_object_container!(var(pm, :p), field(system, :arcs, :arcs), timesteps=1:N)
    fill!(sol(pm, :plc), 0.0)

    return
end

""
function bus_asset!(tmp::Dict{Int, Vector{Int}}, key_assets::Vector{Int}, bus_assets::Vector{Int})
    for k in key_assets
        push!(tmp[bus_assets[k]], k)
    end
    return tmp
end


""
function add_object_container!(container::DatasetContainer{T}, var_key::Symbol, keys::Vector{Int}; timesteps::UnitRange{Int}) where {T <: Matrix{Float64}}

    var_container = _container_spec(Float64, keys, timesteps)
    _assign_container!(container.object, var_key, var_container)
    return
end

""
function add_object_container!(container::DatasetContainer{T}, var_key::Symbol, keys::Vector{Int}; timesteps::UnitRange{Int}) where {T <: AbstractArray}

    value = _container_spec(VariableRef, keys)
    var_container = container_spec(value, timesteps)
    _assign_container!(container.object, var_key, var_container)
    return
end

""
function add_object_container!(container::DatasetContainer{T}, var_key::Symbol, keys::Vector{Union{Missing, Tuple{Int, Int, Int}}}; timesteps::UnitRange{Int}) where {T <: AbstractArray}

    value = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in keys)
    var_container = container_spec(value, timesteps)
    _assign_container!(container.object, var_key, var_container)
    return var_container
end

""
function _assign_container!(container::Dict, key::Symbol, value)
    if haskey(container, key)
        @error "$(key) is already stored"
    end
    container[key] = value
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
function container_spec(dictionary::Dict{Tuple{Int, Int, Int}, Any}, timesteps::UnitRange{Int})
    tmp = DenseAxisArray{Dict}(undef, [i for i in timesteps])
    cont = fill!(tmp, dictionary)
    return cont
end


""
function reset_object_container!(container::DenseAxisArray{T}, keys::Vector{Union{Missing, Tuple{Int, Int, Int}}}; timesteps::UnitRange{Int}) where {T <: Dict}

    value = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in keys)

    @inbounds for i in timesteps
        container[i] = value
    end

    return
end

""
function reset_object_container!(container::DenseAxisArray{T}, keys::Vector{Int}; timesteps::UnitRange{Int}) where {T <: AbstractArray}

    value = _container_spec(VariableRef, keys)

    @inbounds for i in timesteps
        container[i] = value
    end

    return
end

""
function type(pmodel::String)

    if pmodel == "AbstractDCPModel"
        apm = DCPPowerModel
    elseif pmodel == "AbstractDCMPPModel" 
        apm = DCMPPowerModel
    elseif pmodel == "AbstractNFAModel" 
        apm = NFAPowerModel
    elseif pmodel == "PM_AbstractDCPModel"
        apm = PM_DCPPowerModel
    else
        error("AbstractPowerModel = $(pmodel) not supported, DCPPowerModel has been selected")
        apm = DCPPowerModel
    end
    return apm
end

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


#"garbage-----------------------------------------------------------------------------------------------------------------"
# "computes flow bounds on branches from ref data"
# function ref_calc_branch_flow_bounds(branches::Branches)
#     flow_lb = Dict() 
#     flow_ub = Dict()

#     for i in field(branches, :keys)
#         flow_lb[i] = -Inf
#         flow_ub[i] = Inf

#         if hasfield(Branches, :rate_a)
#             flow_lb[i] = max(flow_lb[i], -field(branches, :rate_a)[i])
#             flow_ub[i] = min(flow_ub[i],  field(branches, :rate_a)[i])
#         end
#     end

#     return flow_lb, flow_ub
# end

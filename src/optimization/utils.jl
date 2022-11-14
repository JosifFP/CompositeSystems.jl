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

BaseModule.field(topology::Topology, field::Symbol) = getfield(topology, field)
BaseModule.field(topology::Topology, field::Symbol, subfield::Symbol) = getfield(getfield(topology, field), subfield)
BaseModule.field(settings::Settings, field::Symbol) = getfield(settings, field)

topology(pm::AbstractPowerModel, subfield::Symbol) = getfield(getfield(pm, :topology), subfield)
topology(pm::AbstractPowerModel, subfield::Symbol, indx::Int) = getfield(getfield(pm, :topology), subfield)[indx]
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol) = getfield(getfield(getfield(pm, :topology), field), subfield)
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol, nw::Int) = getindex(getfield(getfield(getfield(pm, :topology), field), subfield), nw)

var(pm::AbstractPowerModel) = getfield(pm, :var)
var(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(getfield(pm, :var), :object), field)
var(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(getfield(pm, :var), :object), field), nw)

con(pm::AbstractPowerModel) = getfield(pm, :con)
con(pm::AbstractPowerModel, field::Symbol) = getindex(getfield(getfield(pm, :con), :object), field)
con(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getindex(getfield(getfield(pm, :con), :object), field), nw)

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
function PowerModel(system::SystemModel{N}, topology::Topology, settings::Settings; timeseries=false) where {N}
    
    model = JumpModel(field(settings, :modelmode), deepcopy(field(settings, :optimizer)))
    var = DatasetContainer{AbstractArray}()
    con = DatasetContainer{AbstractArray}()

    if timeseries == true
        add_object_container!(var, :pg, field(system, :generators, :keys), timesteps = 1:N)
        add_object_container!(var, :va, field(system, :buses, :keys), timesteps = 1:N)
        add_object_container!(var, :plc, field(system, :loads, :keys), timesteps = 1:N)
        add_object_container!(var, :p, field(topology, :arcs), timesteps = 1:N)
    else
        add_object_container!(var, :pg, field(system, :generators, :keys), timesteps = 1:1)
        add_object_container!(var, :va, field(system, :buses, :keys), timesteps = 1:1)
        add_object_container!(var, :plc, field(system, :loads, :keys), timesteps = 1:1)
        add_object_container!(var, :p, field(topology, :arcs), timesteps = 1:1)
        add_con_object_container!(con, :power_balance, field(system, :buses, :keys), timesteps = 1:1)
        add_con_object_container!(con, :ohms_yt, field(system, :branches, :keys), timesteps = 1:1)
        add_con_object_container!(con, :voltage_angle_diff, field(system, :branches, :keys), timesteps = 1:1)
    end

    sol = DatasetContainer{Matrix{Float64}}()
    add_object_container!(sol, :plc, field(system, :loads, :keys), timesteps = 1:N)

    return DCPPowerModel(model, topology, var, con, sol)

end

""
function empty_model!(system::SystemModel{N}, pm::AbstractDCPowerModel, settings::Settings; timeseries=false) where {N}

    empty!(pm.model)
    MOIU.reset_optimizer(pm.model)
    #OPF.set_optimizer(pm.model, deepcopy(field(settings, :optimizer)); add_bridges = false)
    if timeseries == true
        reset_object_container!(var(pm, :pg), field(system, :generators, :keys), timesteps=1:N)
        reset_object_container!(var(pm, :va), field(system, :buses, :keys), timesteps=1:N)
        reset_object_container!(var(pm, :plc), field(system, :loads, :keys), timesteps=1:N)
        reset_object_container!(var(pm, :p), topology(pm, :arcs), timesteps=1:N)
    else
        reset_object_container!(var(pm, :pg), field(system, :generators, :keys), timesteps=1:1)
        reset_object_container!(var(pm, :va), field(system, :buses, :keys), timesteps=1:1)
        reset_object_container!(var(pm, :plc), field(system, :loads, :keys), timesteps=1:1)
        reset_object_container!(var(pm, :p), topology(pm, :arcs), timesteps=1:1)
    end 
    fill!(sol(pm, :plc), 0.0)

    return
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
function add_con_object_container!(container::DatasetContainer{T}, con_key::Symbol, keys::Vector{Int}; timesteps::UnitRange{Int}) where {T <: AbstractArray}

    value = _container_spec(ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container.object, con_key, con_container)
    return
end

""
function add_object_container!(container::DatasetContainer{T}, var_key::Symbol, keys::Vector{Tuple{Int, Int, Int}}; timesteps::UnitRange{Int}) where {T <: AbstractArray}

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
function reset_object_container!(container::DenseAxisArray{T}, keys::Vector{Tuple{Int, Int, Int}}; timesteps::UnitRange{Int}) where {T <: Dict}

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
function bus_asset!(tmp::Dict{Int, Vector{Int}}, key_assets::Vector{Int}, bus_assets::Vector{Int})
    for k in key_assets
        push!(tmp[bus_assets[k]], k)
    end
    return tmp
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

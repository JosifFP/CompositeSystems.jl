field(system::SystemModel, field::Symbol) = getfield(system, field)
field(system::SystemModel, buses::Type{Buses}, subfield::Symbol) = getfield(getfield(system, :buses), subfield)
field(system::SystemModel, loads::Type{Loads}, subfield::Symbol) = getfield(getfield(system, :loads), subfield)
field(system::SystemModel, branches::Type{Branches}, subfield::Symbol) = getfield(getfield(system, :branches), subfield)
field(system::SystemModel, shunts::Type{Shunts}, subfield::Symbol) = getfield(getfield(system, :shunts), subfield)
field(system::SystemModel, generators::Type{Generators}, subfield::Symbol) = getfield(getfield(system, :generators), subfield)
field(system::SystemModel, storages::Type{Storages}, subfield::Symbol) = getfield(getfield(system, :storages), subfield)
field(system::SystemModel, generatorstorages::Type{GeneratorStorages}, subfield::Symbol) = getfield(getfield(system, :generatorstorages), subfield)

field(buses::Buses, subfield::Symbol) = getfield(buses, subfield)
field(loads::Loads, subfield::Symbol) = getfield(loads, subfield)
field(branches::Branches, subfield::Symbol) = getfield(branches, subfield)
field(shunts::Shunts, subfield::Symbol) = getfield(shunts, subfield)
field(generators::Generators, subfield::Symbol) = getfield(generators, subfield)
field(storages::Storages, subfield::Symbol) = getfield(storages, subfield)
field(generatorstorages::GeneratorStorages, subfield::Symbol) = getfield(generatorstorages, subfield)

field(states::SystemStates, field::Symbol) = getfield(states, field)
field(states::SystemStates, field::Symbol, t::Int) = view(getfield(states, field), :, t)
field(field::Matrix{Bool}, t::Int) = view(field, :, t)
field(field::Union{BitVector, Vector{Bool}}, t::Int) = view(field, t)

field(settings::Settings, field::Symbol) = getfield(settings, field)

field(method::SimulationSpec, field::Symbol) = getfield(method, field)
field(method::SimulationSpec, settings::Type{Settings}, subfield::Symbol) = getfield(getfield(method, :settings), subfield)

field(powermodel::AbstractPowerModel, subfield::Symbol) = getfield(powermodel, subfield)
field(powermodel::AbstractPowerModel, topology::Type{Topology}, subfield::Symbol) = getfield(getfield(powermodel, :topology), subfield)
field(topology::Topology, subfield::Symbol) = getfield(topology, subfield)

var(powermodel::AbstractPowerModel) = getfield(powermodel, :var)
var(powermodel::AbstractPowerModel, subfield::Symbol) = getfield(getfield(powermodel, :var), subfield)
var(powermodel::AbstractPowerModel, subfield::Symbol, nw::Int) = getindex(getfield(getfield(powermodel, :var), subfield), nw)

sol(pm::AbstractPowerModel, args...) = _sol(pm.sol, args...)
sol(pm::AbstractPowerModel, key::Symbol) = pm.sol[key]


""
function check_status(a::Vector{Bool})
    i_idx = @inbounds findfirst(isequal(0), a)
    if i_idx === nothing i_idx=SUCCESSFUL else i_idx=FAILED end
    return i_idx
end

""
function check_status(a::SubArray)
    i_idx = findfirst(isequal(0), a)
    if i_idx === nothing i_idx=SUCCESSFUL else i_idx=FAILED end
    return i_idx
end

""
function findfirstunique_directional(a::AbstractVector{<:Pair}, i::Pair)
    i_idx = findfirst(isequal(i), a)
    if isnothing(i_idx)
        i_idx = findfirstunique(a, last(i) => first(i))
        reverse = true
    else
        reverse = false
    end
    return i_idx, reverse
end

""
function findfirstunique(a::AbstractVector{T}, i::T) where T
    i_idx = findfirst(isequal(i), a)
    i_idx === nothing && throw(BoundsError(a))
    return i_idx
end

""
function assetgrouplist(idxss::Vector{UnitRange{Int}})
    
    if isempty(idxss)
        results = Int[]
    else
        results = Vector{Int}(undef, last(idxss[end]))
        for (g, idxs) in enumerate(idxss)
            results[idxs] .= g
        end
    end
    return results

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

""
function colsum(x::Matrix{T}, col::Integer) where {T}
    result = zero(T)
    for i in 1:size(x, 1)
        result += x[i, col]
    end
    return result
end

""
function _sol(sol::Dict, args...)
    for arg in args
        if haskey(sol, arg)
            sol = sol[arg]
        else
            sol = sol[arg] = Dict()
        end
    end

    return sol
end

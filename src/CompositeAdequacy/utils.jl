
"Extract a field from a composite value by name or position."
field(system::SystemModel, field::Symbol) = getfield(system, field)
field(system::SystemModel, field::Symbol, subfield::Symbol) = getfield(getfield(system, field), subfield)

field(buses::Buses, subfield::Symbol) = getfield(buses, subfield)
field(loads::Loads, subfield::Symbol) = getfield(loads, subfield)
field(branches::Branches, subfield::Symbol) = getfield(branches, subfield)
field(shunts::Shunts, subfield::Symbol) = getfield(shunts, subfield)
field(generators::Generators, subfield::Symbol) = getfield(generators, subfield)
field(storages::Storages, subfield::Symbol) = getfield(storages, subfield)
field(generatorstorages::GeneratorStorages, subfield::Symbol) = getfield(generatorstorages, subfield)
field(arcs::Arcs, subfield::Symbol) = getfield(arcs, subfield)

field(states::SystemStates, field::Symbol) = getfield(states, field)
field(states::SystemStates, field::Symbol, t::Int) = getfield(states, field)[:,t]
field(settings::Settings, field::Symbol) = getfield(settings, field)
field(method::SimulationSpec, field::Symbol) = getfield(method, field)

field(topology::Topology, field::Symbol) = getfield(topology, field)
field(topology::Topology, field::Symbol, subfield::Symbol) = getfield(getfield(topology, field), subfield)

topology(pm::AbstractPowerModel, subfield::Symbol) = getfield(getfield(pm, :topology), subfield)
topology(pm::AbstractPowerModel, subfield::Symbol, indx::Int) = getfield(getfield(pm, :topology), subfield)[indx]
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol) = getfield(getfield(getfield(pm, :topology), field), subfield)
topology(pm::AbstractPowerModel, field::Symbol, subfield::Symbol, nw::Int) = getindex(getfield(getfield(getfield(pm, :topology), field), subfield), nw)

var(pm::AbstractPowerModel) = getfield(pm, :var)
var(pm::AbstractPowerModel, field::Symbol) = getfield(getfield(pm, :var), field)
var(pm::AbstractPowerModel, field::Symbol, nw::Int) = getindex(getfield(getfield(pm, :var), field), nw)

sol(pm::AbstractPowerModel, field::Symbol) = getfield(pm, :sol)
#sol(pm::AbstractPowerModel, field::Symbol) = getfield(getfield(pm, :sol), field)

cache(pm::AbstractPowerModel) = getfield(pm, :cache)
cache(pm::AbstractPowerModel, field::Symbol) = getfield(getfield(pm, :cache), field)

#sol(pm::AbstractPowerModel, args...) = _sol(pm.sol, args...)
#sol(pm::AbstractPowerModel, key::Symbol) = pm.sol[key]

function Base.map!(f, dict::Dict)

    vals = dict.vals
    # @inbounds is here so that it gets propagated to isslotfilled
    @inbounds for i = dict.idxfloor:lastindex(vals)
        if Base.isslotfilled(dict, i)
            vals[i] = f(vals[i])
        end
    end
    return
end

""
function check_status(a::SubArray{Bool, 1, Matrix{Bool}, Tuple{Base.Slice{Base.OneTo{Int}}, Int}, true})
    i_idx = @inbounds findfirst(isequal(0), a)
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

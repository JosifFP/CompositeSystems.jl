meanvariance() = Series(Mean(), Variance())

function mean_std(x::MeanVariance)
    m, v = value(x)
    return m, sqrt(v)
end

function mean_std(x::AbstractArray{<:MeanVariance})

    means = similar(x, Float64)
    vars = similar(means)

    for i in eachindex(x)
        m, v = mean_std(x[i])
        means[i] = m
        vars[i] = v
    end

    return means, vars

end

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

function findfirstunique(a::AbstractVector{T}, i::T) where T
    i_idx = findfirst(isequal(i), a)
    i_idx === nothing && throw(BoundsError(a))
    return i_idx
end

function assetgrouplist(idxss::Vector{UnitRange{Int}})
    results = Vector{Int}(undef, last(idxss[end]))
    for (g, idxs) in enumerate(idxss)
        results[idxs] .= g
    end
    return results
end

function colsum(x::Matrix{T}, col::Integer) where {T}
    result = zero(T)
    for i in 1:size(x, 1)
        result += x[i, col]
    end
    return result
end

field(system::SystemModel, field::Symbol) = getfield(system, field)
field(system::SystemModel, buses::Type{Buses}, subfield::Symbol) = getfield(getfield(system, :buses), subfield)
field(system::SystemModel, loads::Type{Loads}, subfield::Symbol) = getfield(getfield(system, :loads), subfield)
field(system::SystemModel, branches::Type{Branches}, subfield::Symbol) = getfield(getfield(system, :branches), subfield)
field(system::SystemModel, shunts::Type{Shunts}, subfield::Symbol) = getfield(getfield(system, :shunts), subfield)
field(system::SystemModel, generators::Type{Generators}, subfield::Symbol) = getfield(getfield(system, :generators), subfield)
field(system::SystemModel, storages::Type{Storages}, subfield::Symbol) = getfield(getfield(system, :storages), subfield)
field(system::SystemModel, generatorstorages::Type{GeneratorStorages}, subfield::Symbol) = getfield(getfield(system, :generatorstorages), subfield)
field(system::SystemModel, topology::Type{Topology}, subfield::Symbol) = getfield(getfield(system, :topology), subfield)

field(buses::Buses, subfield::Symbol) = getfield(buses, subfield)
field(loads::Loads, subfield::Symbol) = getfield(loads, subfield)
field(branches::Branches, subfield::Symbol) = getfield(branches, subfield)
field(shunts::Shunts, subfield::Symbol) = getfield(shunts, subfield)
field(generators::Generators, subfield::Symbol) = getfield(generators, subfield)
field(storages::Storages, subfield::Symbol) = getfield(storages, subfield)
field(generatorstorages::GeneratorStorages, subfield::Symbol) = getfield(generatorstorages, subfield)
field(topology::Topology, subfield::Symbol) = getfield(topology, subfield)

field(state::SystemState, field::Symbol) = getfield(state, field)
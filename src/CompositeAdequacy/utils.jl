
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

field(states::SystemStates, field::Symbol) = getfield(states, field)::Matrix{Bool}
field(states::SystemStates, field::Symbol, ::Colon, t::Int) = getindex(getfield(states, field),:, t)
field(states::SystemStates, field::Symbol, i::Int, t::Int) = getindex(getfield(states, field),i, t)

field(method::SimulationSpec, field::Symbol) = getfield(method, field)

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
    if i_idx === nothing i_idx=true else i_idx=false end
    return i_idx
end

""
function check_status(a::Vector{Bool})
    i_idx = @inbounds findfirst(isequal(0), a)
    if i_idx === nothing i_idx=true else i_idx=false end
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

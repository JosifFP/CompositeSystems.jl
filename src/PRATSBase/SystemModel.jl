
struct SystemModel{N,L,T<:Period,U<:PerUnit}

    #buses::Buses{N,P}
    generators::Generators{N,L,T,U}
    loads::Loads{N,L,T,U}
    storages::Storages{N,L,T,U}
    generatorstorages::GeneratorStorages{N,L,T,U}
    branches::Branches{N,L,T,U}
    network::Network{N,L,T,U}
    timestamps::StepRange{ZonedDateTime,T}

    function SystemModel{}(
        generators::Generators{N,L,T,U}, loads::Loads{N,L,T,U}, storages::Storages{N,L,T,U},
        generatorstorages::GeneratorStorages{N,L,T,U}, branches::Branches{N,L,T,U},
        network::Network{N,L,T,U}, timestamps::StepRange{ZonedDateTime,T}
    ) where {N,L,T<:Period,U<:PerUnit}

    # n_gens = length(generators)
    # n_stors = length(storages)
    # n_genstors = length(generatorstorages)
    # n_branches = length(branches)

    @assert step(timestamps) == T(L)
    @assert length(timestamps) == N

    new{N,L,T,U}(
        generators, loads, storages, generatorstorages, branches, network, timestamps)
    end

end

# No time zone constructor
function SystemModel(
    generators, loads, storages, generatorstorages, branches, network, timestamps::StepRange{DateTime,T}
) where {N,L,T<:Period,U<:PerUnit}

    #@warn "No time zone data provided - defaulting to UTC. To specify a " *
    #      "time zone for the system timestamps, provide a range of " *
    #      "`ZonedDateTime` instead of `DateTime`."

    utc = TimeZone("UTC")
    time_start = ZonedDateTime(first(timestamps), utc)
    time_end = ZonedDateTime(last(timestamps), utc)
    timestamps_tz = time_start:step(timestamps):time_end

    return SystemModel(
        generators, loads, storages, generatorstorages, branches, network, timestamps_tz)

end

Base.:(==)(x::T, y::T) where {T <: SystemModel} =
    x.generators == y.generators &&
    x.loads == y.bus_gen_idxs &&
    x.storages == y.storages &&
    x.generatorstorages == y.generatorstorages &&
    x.branches == y.branches &&
    x.network == y.bus_branch_idxs &&
    x.timestamps == y.timestamps

broadcastable(x::SystemModel) = Ref(x)

unitsymbol(::SystemModel{N,L,T,U}) where {N,L,T<:Period,U<:PerUnit} = unitsymbol(T), unitsymbol(U)
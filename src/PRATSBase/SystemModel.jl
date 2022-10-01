
"SystemModel structure"
struct SystemModel{N,L,T<:Period,U<:PerUnit}

    buses::Buses{N,L,T,U}
    generators::Generators{N,L,T,U}
    loads::Loads{N,L,T,U}
    storages::Storages{N,L,T,U}
    generatorstorages::GeneratorStorages{N,L,T,U}
    branches::Branches{N,L,T,U}
    shunts::Shunts{N,L,T,U}
    timestamps::StepRange{ZonedDateTime,T}

    function SystemModel{}(
        buses::Buses{N,L,T,U}, 
        generators::Generators{N,L,T,U}, 
        loads::Loads{N,L,T,U}, 
        storages::Storages{N,L,T,U}, 
        generatorstorages::GeneratorStorages{N,L,T,U}, 
        branches::Branches{N,L,T,U}, 
        shunts::Shunts{N,L,T,U}, 
        timestamps::StepRange{ZonedDateTime,T}
    ) where {N,L,T<:Period,U<:PerUnit}

    # n_gens = length(generators)
    # n_stors = length(storages)
    # n_genstors = length(generatorstorages)
    # n_branches = length(branches)

    @assert step(timestamps) == T(L)
    @assert length(timestamps) == N

    new{N,L,T,U}(
        buses, generators, loads, storages, generatorstorages, branches, shunts, timestamps)
    end

end

# No time zone constructor
function SystemModel(
    buses, generators, loads, storages, generatorstorages, branches, shunts, timestamps::StepRange{DateTime,T}
) where {N,L,T<:Period,U<:PerUnit}

    #@warn "No time zone data provided - defaulting to UTC. To specify a " *
    #      "time zone for the system timestamps, provide a range of " *
    #      "`ZonedDateTime` instead of `DateTime`."

    utc = TimeZone("UTC")
    time_start = ZonedDateTime(first(timestamps), utc)
    time_end = ZonedDateTime(last(timestamps), utc)
    timestamps_tz = time_start:step(timestamps):time_end

    return SystemModel(
        buses, generators, loads, storages, generatorstorages, branches, shunts, timestamps_tz)

end

Base.:(==)(x::T, y::T) where {T <: SystemModel} =
    x.buses == y.buses &&
    x.generators == y.generators &&
    x.loads == y.loads &&
    x.storages == y.storages &&
    x.generatorstorages == y.generatorstorages &&
    x.branches == y.branches &&
    x.shunts == y.shunts &&
    x.timestamps == y.timestamps

broadcastable(x::SystemModel) = Ref(x)

unitsymbol(::SystemModel{N,L,T,U}) where {N,L,T<:Period,U<:PerUnit} = unitsymbol(T), unitsymbol(U)
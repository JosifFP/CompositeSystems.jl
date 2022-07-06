
struct SystemModel{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit}

    buses::Buses{N,P}
    generators::Generators{N,L,T,P}
    storages::Storages{N,L,T,P,E}
    generatorstorages::GeneratorStorages{N,L,T,P,E}
    branches::Branches{N,L,T,P}
    # network::Dict{String, Any}()
    bus_gen_idxs::Vector{UnitRange{Int}}
    bus_stor_idxs::Vector{UnitRange{Int}}
    bus_genstor_idxs::Vector{UnitRange{Int}}
    bus_branch_idxs::Vector{UnitRange{Int}}
    timestamps::StepRange{ZonedDateTime,T}

    function SystemModel{}(
        buses::Buses{N,P}, generators::Generators{N,L,T,P}, bus_gen_idxs::Vector{UnitRange{Int}},
        storages::Storages{N,L,T,P,E}, bus_stor_idxs::Vector{UnitRange{Int}},
        generatorstorages::GeneratorStorages{N,L,T,P,E}, bus_genstor_idxs::Vector{UnitRange{Int}},
        branches::Branches{N,L,T,P}, bus_branch_idxs::Vector{UnitRange{Int}},
        timestamps::StepRange{ZonedDateTime,T}
    ) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit}

    n_buses = length(buses)
    n_gens = length(generators)
    n_stors = length(storages)
    n_genstors = length(generatorstorages)
    n_branches = length(branches)

    @assert consistent_idxs(bus_gen_idxs, n_gens, n_buses)
    @assert consistent_idxs(bus_stor_idxs, n_stors, n_buses)
    @assert consistent_idxs(bus_genstor_idxs, n_genstors, n_buses)
    @assert consistent_idxs(bus_branch_idxs, n_branches, n_buses)

        @assert step(timestamps) == T(L)
        @assert length(timestamps) == N

             new{N,L,T,P,E}(
            buses, generators, bus_gen_idxs, storages, bus_stor_idxs,
            generatorstorages, bus_genstor_idxs, branches, bus_branch_idxs,
            timestamps)
    end

end

# No time zone constructor
function SystemModel(
    buses, generators, bus_gen_idxs,
    storages, bus_stor_idxs,
    generatorstorages, bus_genstor_idxs,
    branches, bus_branch_idxs,
    timestamps::StepRange{DateTime,T}
) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit}

    @warn "No time zone data provided - defaulting to UTC. To specify a " *
          "time zone for the system timestamps, provide a range of " *
          "`ZonedDateTime` instead of `DateTime`."

    utc = TimeZone("UTC")
    time_start = ZonedDateTime(first(timestamps), utc)
    time_end = ZonedDateTime(last(timestamps), utc)
    timestamps_tz = time_start:step(timestamps):time_end

    return SystemModel(
        buses, generators, bus_gen_idxs,
        storages, bus_stor_idxs,
        generatorstorages, bus_genstor_idxs,
        branches, bus_branch_idxs,
        timestamps_tz)

end

Base.:(==)(x::T, y::T) where {T <: SystemModel} =
    x.buses == y.buses &&
    x.interfaces == y.interfaces &&
    x.generators == y.generators &&
    x.bus_gen_idxs == y.bus_gen_idxs &&
    x.storages == y.storages &&
    x.bus_stor_idxs == y.bus_stor_idxs &&
    x.generatorstorages == y.generatorstorages &&
    x.bus_genstor_idxs == y.bus_genstor_idxs &&
    x.branches == y.branches &&
    x.bus_branch_idxs == y.bus_branch_idxs &&
    x.timestamps == y.timestamps

broadcastable(x::SystemModel) = Ref(x)

unitsymbol(::SystemModel{N,L,T,P,E}) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit} = unitsymbol(T), unitsymbol(P), unitsymbol(E)

function consistent_idxs(idxss::Vector{UnitRange{Int}}, nitems::Int, ngroups::Int)

    length(idxss) == ngroups || return false

    expected_next = 1
    for idxs in idxss
        first(idxs) == expected_next || return false
        expected_next = last(idxs) + 1
    end

    expected_next == nitems + 1 || return false
    return true

end

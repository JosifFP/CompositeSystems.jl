
struct SystemModel{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit,V<:VoltageUnit}

    #buses::Buses{N,P}
    generators::Generators{N,L,T,P}
    loads::Loads{N,L,T,P}
    storages::Storages{N,L,T,P,E}
    generatorstorages::GeneratorStorages{N,L,T,P,E}
    branches::Branches{N,L,T,P}
    network::Network{N,L,T,P,E,V}
    timestamps::StepRange{ZonedDateTime,T}

    function SystemModel{}(
        generators::Generators{N,L,T,P}, loads::Loads{N,L,T,P}, storages::Storages{N,L,T,P,E},
        generatorstorages::GeneratorStorages{N,L,T,P,E}, branches::Branches{N,L,T,P},
        network::Network{N,L,T,P,E,V}, timestamps::StepRange{ZonedDateTime,T}
    ) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit,V<:VoltageUnit}

    # n_gens = length(generators)
    # n_stors = length(storages)
    # n_genstors = length(generatorstorages)
    # n_branches = length(branches)

    @assert step(timestamps) == T(L)
    @assert length(timestamps) == N

    new{N,L,T,P,E,V}(
        generators, loads, storages, generatorstorages, branches, network, timestamps)
    end

end

# No time zone constructor
function SystemModel(
    generators, loads, storages, generatorstorages, branches, network, timestamps::StepRange{DateTime,T}
) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit,V<:VoltageUnit}

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

unitsymbol(::SystemModel{N,L,T,P,E,V}) where {N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit,V<:VoltageUnit} = unitsymbol(T), unitsymbol(P), unitsymbol(E), unitsymbol(V)
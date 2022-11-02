"SystemModel structure"
struct SystemModel{N,L,T<:Period}

    loads::Loads{N,L,T}
    generators::Generators{N,L,T}
    storages::Storages{N,L,T}
    generatorstorages::GeneratorStorages{N,L,T}
    buses::Buses
    branches::Branches
    shunts::Shunts
    arcs::Arcs
    ref_buses::Vector{Int}
    baseMVA::Float16
    timestamps::StepRange{ZonedDateTime,T}

    function SystemModel{}(
        loads::Loads{N,L,T},
        generators::Generators{N,L,T},
        storages::Storages{N,L,T},
        generatorstorages::GeneratorStorages{N,L,T},
        buses::Buses,
        branches::Branches,
        shunts::Shunts,
        arcs::Arcs,
        ref_buses::Vector{Int},
        baseMVA::Float16,
        timestamps::StepRange{ZonedDateTime,T}
    ) where {N,L,T<:Period}
    
    @assert step(timestamps) == T(L)
    @assert length(timestamps) == N

    new{N,L,T}(loads, generators, storages, generatorstorages, buses, branches, shunts, arcs, ref_buses, baseMVA, timestamps)
    end

end

# No time zone constructor
function SystemModel(
    loads::Loads{N,L,T},
    generators::Generators{N,L,T},
    storages::Storages{N,L,T},
    generatorstorages::GeneratorStorages{N,L,T},
    buses::Buses,
    branches::Branches,
    shunts::Shunts,
    arcs::Arcs,
    ref_buses::Vector{Int},
    baseMVA::Float16
) where {N,L,T<:Period}

    @warn "No time zone data provided - defaulting to UTC. To specify a " *
          "time zone for the system timestamps, provide a range of " *
          "`ZonedDateTime` instead of `DateTime`."

    start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))
    timezone = "UTC"
    timestamps_tz = timestamps(start_timestamp, N, L, T, timezone)

    return SystemModel(loads, generators, storages, generatorstorages, buses, branches, shunts, arcs, ref_buses, baseMVA, timestamps_tz)

end



Base.:(==)(x::T, y::T) where {T <: SystemModel} =
    x.loads == y.loads &&
    x.generators == y.generators &&
    x.storages == y.storages &&
    x.generatorstorages == y.generatorstorages &&
    x.buses == y.buses &&
    x.branches == y.branches &&
    x.shunts == y.shunts &&
    x.arcs == y.arcs &&
    x.ref_buses == y.ref_buses &&
    x.baseMVA == y.baseMVA &&
    x.timestamps == y.timestamps

Base.broadcastable(x::SystemModel) = Ref(x)

unitsymbol(::SystemModel{N,L,T}) where {N,L,T<:Period} = unitsymbol(T)
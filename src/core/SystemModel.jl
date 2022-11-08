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
    
    if timestamps !== nothing
        @assert step(timestamps) == T(L)
        @assert length(timestamps) == N
    end

    new{N,L,T}(loads, generators, storages, generatorstorages, buses, branches, shunts, arcs, ref_buses, baseMVA, timestamps)
    end

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
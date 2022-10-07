
"SystemModel structure"
struct SystemModel{N,L,T<:Period,S} #S=baseMVA as Integer

    buses::Buses{N,L,T,S}
    loads::Loads{N,L,T,S}
    branches::Branches{N,L,T,S}
    shunts::Shunts{N,L,T,S}
    generators::Generators{N,L,T,S}
    storages::Storages{N,L,T,S}
    generatorstorages::GeneratorStorages{N,L,T,S}
    timestamps::StepRange{ZonedDateTime,T}

    function SystemModel{}(
        buses::Buses{N,L,T,S},
        loads::Loads{N,L,T,S},
        branches::Branches{N,L,T,S},
        shunts::Shunts{N,L,T,S},
        generators::Generators{N,L,T,S},
        storages::Storages{N,L,T,S},
        generatorstorages::GeneratorStorages{N,L,T,S},
        timestamps::StepRange{ZonedDateTime,T}
    ) where {N,L,T<:Period,S}

    # n_gens = length(generators)
    # n_stors = length(storages)
    # n_genstors = length(generatorstorages)
    # n_branches = length(branches)
    @assert step(timestamps) == T(L)
    @assert length(timestamps) == N

    new{N,L,T,S}(
        buses, loads, branches, shunts, generators, storages, generatorstorages, timestamps)
    end

end

Base.:(==)(x::T, y::T) where {T <: SystemModel} =
    x.buses == y.buses &&
    x.loads == y.loads &&
    x.branches == y.branches &&
    x.shunts == y.shunts &&
    x.generators == y.generators &&
    x.storages == y.storages &&
    x.generatorstorages == y.generatorstorages &&
    x.timestamps == y.timestamps

broadcastable(x::SystemModel) = Ref(x)

unitsymbol(::SystemModel{N,L,T,S}) where {N,L,T<:Period,S} = unitsymbol(S), unitsymbol(T)
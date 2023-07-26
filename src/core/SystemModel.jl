"SystemModel structure"
struct SystemModel{N,L,T<:Period}

    loads::Loads{N,L,T}
    generators::Generators{N,L,T}
    storages::Storages{N,L,T}
    #generatorstorages::GeneratorStorages{N,L,T}
    buses::Buses
    branches::Branches
    commonbranches::CommonBranches
    shunts::Shunts
    baseMVA::Float64
    timestamps::StepRange{ZonedDateTime,T}

    function SystemModel{}(
        loads::Loads{N,L,T},
        generators::Generators{N,L,T},
        storages::Storages{N,L,T},
        buses::Buses,
        branches::Branches,
        commonbranches::CommonBranches,
        shunts::Shunts,
        baseMVA::Float64,
        timestamps::StepRange{ZonedDateTime,T}
    ) where {N,L,T<:Period}
    
    if timestamps ≠ nothing
        @assert step(timestamps) == T(L)
        @assert length(timestamps) == N
    end

    new{N,L,T}(
        loads, generators, storages, buses, branches, commonbranches, shunts, baseMVA, timestamps)
    end

end

Base.:(==)(x::T, y::T) where {T <: SystemModel} =
    x.loads == y.loads &&
    x.generators == y.generators &&
    x.storages == y.storages &&
    x.buses == y.buses &&
    x.branches == y.branches &&
    x.commonbranches == y.commonbranches &&
    x.shunts == y.shunts &&
    x.baseMVA == y.baseMVA &&
    x.timestamps == y.timestamps

Base.broadcastable(x::SystemModel) = Ref(x)

unitsymbol(::SystemModel{N,L,T}) where {N,L,T<:Period} = unitsymbol(T)
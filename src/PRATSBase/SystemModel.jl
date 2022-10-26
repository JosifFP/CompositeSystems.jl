"SystemModel structure"
struct SystemModel{N,L,T<:Period,B} #B=baseMVA as Integer

    buses::Buses{N,L,T,B}
    loads::Loads{N,L,T,B}
    branches::Branches{N,L,T,B}
    shunts::Shunts{N,L,T,B}
    generators::Generators{N,L,T,B}
    storages::Storages{N,L,T,B}
    generatorstorages::GeneratorStorages{N,L,T,B}
    arcs::Arcs
    ref_buses::Vector{Int}
    timestamps::Union{StepRange{ZonedDateTime,T}, Nothing}

    function SystemModel{N,L,T,B}(
        buses::Buses{N,L,T,B},
        loads::Loads{N,L,T,B},
        branches::Branches{N,L,T,B},
        shunts::Shunts{N,L,T,B},
        generators::Generators{N,L,T,B},
        storages::Storages{N,L,T,B},
        generatorstorages::GeneratorStorages{N,L,T,B},
        arcs::Arcs,
        ref_buses::Vector{Int},
        timestamps::Union{StepRange{ZonedDateTime,T}, Nothing}
    ) where {N,L,T<:Period,B}
    
    if N > 1
        @assert step(timestamps) == T(L)
        @assert length(timestamps) == N
    else
        @assert N==1
    end

    new{N,L,T,B}(buses, loads, branches, shunts, generators, storages, generatorstorages, arcs, ref_buses, timestamps)
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
    x.arcs == y.arcs &&
    x.buspairs == y.buspairs &&
    x.ref_buses == y.ref_buses &&
    x.timestamps == y.timestamps

Base.broadcastable(x::SystemModel) = Ref(x)

unitsymbol(::SystemModel{N,L,T,B}) where {N,L,T<:Period,B} = unitsymbol(B), unitsymbol(T)
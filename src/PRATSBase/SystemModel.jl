
"SystemModel structure"
struct SystemModel{N,L,T<:Period,S} #S=baseMVA as Integer

    buses::Buses{N,L,T,S}
    loads::Loads{N,L,T,S}
    branches::Branches{N,L,T,S}
    shunts::Shunts{N,L,T,S}
    generators::Generators{N,L,T,S}
    storages::Storages{N,L,T,S}
    generatorstorages::GeneratorStorages{N,L,T,S}
    arcs_from::Vector{Tuple{Int, Int, Int}}
    arcs_to::Vector{Tuple{Int, Int, Int}}
    arcs::Vector{Tuple{Int, Int, Int}}
    ref_buses::Vector{Int}
    timestamps::Union{StepRange{ZonedDateTime,T}, Nothing}

    function SystemModel{}(
        buses::Buses{N,L,T,S},
        loads::Loads{N,L,T,S},
        branches::Branches{N,L,T,S},
        shunts::Shunts{N,L,T,S},
        generators::Generators{N,L,T,S},
        storages::Storages{N,L,T,S},
        generatorstorages::GeneratorStorages{N,L,T,S},
        arcs_from::Vector{Tuple{Int, Int, Int}},
        arcs_to::Vector{Tuple{Int, Int, Int}},
        arcs::Vector{Tuple{Int, Int, Int}},
        ref_buses::Vector{Int},
        timestamps::Union{StepRange{ZonedDateTime,T}, Nothing}
    ) where {N,L,T<:Period,S}
    
    if N > 1
        @assert step(timestamps) == T(L)
        @assert length(timestamps) == N
    else
        @assert N==1
    end

    new{N,L,T,S}(buses, loads, branches, shunts, generators, storages, generatorstorages, arcs_from, arcs_to, arcs, ref_buses, timestamps)
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
    x.arcs_from == y.arcs_from &&
    x.arcs_to == y.arcs_to &&
    x.arcs == y.arcs &&
    x.ref_buses == y.ref_buses &&
    x.timestamps == y.timestamps

Base.broadcastable(x::SystemModel) = Ref(x)

unitsymbol(::SystemModel{N,L,T,S}) where {N,L,T<:Period,S} = unitsymbol(S), unitsymbol(T)
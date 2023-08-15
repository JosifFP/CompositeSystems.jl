
"""
Define a "SystemModel" structure to represent a power system model.
The structure is parametrized by:
 - N - The number of time steps or periods
 - L - Duration or related parameter
 - T - Period (i.e., a time-based unit such as second, minute, etc.)
Fields:
- `loads`: Load profile of the system across various nodes and time periods.
- `generators`: Generators in the system, defined across nodes and periods.
- `storages`: Energy storage units in the system, across nodes and periods.
- `buses`: Bus structure defining connection points in the network.
- `branches`: Branches defining interconnections or transmission lines.
- `commonbranches`: Specialized set of branches with shared/common attributes or behavior.
- `shunts`: Shunts, usually devices used to adjust voltage or to phase-shift load currents.
- `baseMVA`: Base apparent power (used for per unit system calculations in power systems).
- `timestamps`: Timestamps defining the different time periods the system is modeled over.

Constructor:
Ensures that provided timestamps, if any, match the expected step and count before creating an instance.
"""
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
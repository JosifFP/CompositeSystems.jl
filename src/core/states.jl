"""
`StateTransition` structure represents the transition states of various components in the power system.

Fields:
- `branches_available`: A boolean vector indicating the availability status of branches (true if available).
- `branches_nexttransition`: An integer vector indicating the next transition time of branches.
- `interfaces_available`: A boolean vector indicating the availability status of interfaces.
- `interfaces_nexttransition`: An integer vector indicating the next transition time of interfaces.
- `generators_available`: A boolean vector indicating the availability status of generators.
- `generators_nexttransition`: An integer vector indicating the next transition time of generators.
- `storages_available`: A boolean vector indicating the availability status of storage units.
- `storages_nexttransition`: An integer vector indicating the next transition time of storage units.

Constructor:
Initializes the structure using a given `SystemModel`. The lengths of vectors are determined by the lengths of 
respective components in the `SystemModel`. The vectors are uninitialized (filled with undefined values), 
and will need to be updated to reflect the actual system state.
"""
struct StateTransition

    branches_available::Vector{Bool}
    branches_nexttransition::Vector{Int}
    interfaces_available::Vector{Bool}
    interfaces_nexttransition::Vector{Int}
    generators_available::Vector{Bool}
    generators_nexttransition::Vector{Int}
    storages_available::Vector{Bool}
    storages_nexttransition::Vector{Int}

    function StateTransition(system::SystemModel{N}) where {N}

        nbranches = length(system.branches)
        branches_available = Vector{Bool}(undef, nbranches)
        branches_nexttransition = Vector{Int}(undef, nbranches)

        ninterfaces = length(system.interfaces)
        interfaces_available = Vector{Bool}(undef, ninterfaces)
        interfaces_nexttransition = Vector{Int}(undef, ninterfaces)

        ngens = length(system.generators)
        generators_available = Vector{Bool}(undef, ngens)
        generators_nexttransition = Vector{Int}(undef, ngens)

        nstors = length(system.storages)
        storages_available = Vector{Bool}(undef, nstors)
        storages_nexttransition = Vector{Int}(undef, nstors)

        return new(
            branches_available,
            branches_nexttransition,
            interfaces_available,
            interfaces_nexttransition,
            generators_available,
            generators_nexttransition,
            storages_available,
            storages_nexttransition)
    end
end
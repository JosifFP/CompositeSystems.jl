"Structure strictly used to record random events."

struct StateTransition

    branches_available::Vector{Bool}
    branches_nexttransition::Vector{Int}
    commonbranches_available::Vector{Bool}
    commonbranches_nexttransition::Vector{Int}
    generators_available::Vector{Bool}
    generators_nexttransition::Vector{Int}
    storages_available::Vector{Bool}
    storages_nexttransition::Vector{Int}

    function StateTransition(system::SystemModel{N}) where {N}

        nbranches = length(system.branches)
        branches_available = Vector{Bool}(undef, nbranches)
        branches_nexttransition = Vector{Int}(undef, nbranches)

        ncommonbranches = length(system.commonbranches)
        commonbranches_available = Vector{Bool}(undef, ncommonbranches)
        commonbranches_nexttransition = Vector{Int}(undef, ncommonbranches)

        ngens = length(system.generators)
        generators_available = Vector{Bool}(undef, ngens)
        generators_nexttransition = Vector{Int}(undef, ngens)

        nstors = length(system.storages)
        storages_available = Vector{Bool}(undef, nstors)
        storages_nexttransition = Vector{Int}(undef, nstors)

        return new(
            branches_available,
            branches_nexttransition,
            commonbranches_available,
            commonbranches_nexttransition,
            generators_available,
            generators_nexttransition,
            storages_available,
            storages_nexttransition)
    end
end
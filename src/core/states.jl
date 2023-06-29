"Structure strictly used to record random events.
Too many changes within it might affect random number generators. 
For instance, using component availability vectors to update changes 
from the update_topology! function will result in weird behaviour."

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

        fill!(branches_available, 1)
        fill!(commonbranches_available, 1)
        fill!(generators_available, 1)
        fill!(storages_available, 1)

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


"state structure with arrays for Sequential MCS"
struct States

    branches_available::Vector{Bool}
    branches_pasttransition::Vector{Bool}
    commonbranches_available::Vector{Bool}
    commonbranches_pasttransition::Vector{Bool}
    generators_available::Vector{Bool}
    generators_pasttransition::Vector{Bool}
    storages_available::Vector{Bool}
    storages_pasttransition::Vector{Bool}
    buses_available::Vector{Int}
    buses_pasttransition::Vector{Int}
    loads_available::Vector{Bool}
    loads_pasttransition::Vector{Bool}
    shunts_available::Vector{Bool}
    shunts_pasttransition::Vector{Bool}

    function States(system::SystemModel{N}) where {N}

        nbranches = length(system.branches)
        ncommonbranches = length(system.commonbranches)
        ngens = length(system.generators)
        nstors = length(system.storages)
        nbuses = length(system.buses)

        branches_available = Vector{Bool}(undef, nbranches)
        branches_pasttransition = Vector{Bool}(undef, nbranches)
        commonbranches_available = Vector{Bool}(undef, ncommonbranches)
        commonbranches_pasttransition = Vector{Bool}(undef, ncommonbranches)
        generators_available = Vector{Bool}(undef, ngens)
        generators_pasttransition = Vector{Bool}(undef, ngens)
        storages_available = Vector{Bool}(undef, nstors)
        storages_pasttransition = Vector{Bool}(undef, nstors)
        buses_available = Vector{Int}(undef, nbuses)
        buses_pasttransition = Vector{Int}(undef, nbuses)

        for k in 1:nbuses
            buses_available[k] = field(system, :buses, :bus_type)[k]
            buses_pasttransition[k] = field(system, :buses, :bus_type)[k]
        end

        nloads = length(system.loads)
        loads_available = Vector{Bool}(undef, nloads)
        loads_pasttransition = Vector{Bool}(undef, nloads)

        nshunts = length(system.shunts)
        shunts_available = Vector{Bool}(undef, nshunts)
        shunts_pasttransition = Vector{Bool}(undef, nshunts)

        fill!(branches_available, 1)
        fill!(branches_pasttransition, 1)
        fill!(commonbranches_available, 1)
        fill!(commonbranches_pasttransition, 1)
        fill!(generators_available, 1)
        fill!(generators_pasttransition, 1)
        fill!(storages_available, 1)
        fill!(storages_pasttransition, 1)
        fill!(loads_available, 1)
        fill!(loads_pasttransition, 1)
        fill!(shunts_available, 1)
        fill!(shunts_pasttransition, 1)

        return new(
            branches_available::Vector{Bool},
            branches_pasttransition::Vector{Bool},
            commonbranches_available::Vector{Bool},
            commonbranches_pasttransition::Vector{Bool},
            generators_available::Vector{Bool},
            generators_pasttransition::Vector{Bool},
            storages_available::Vector{Bool},
            storages_pasttransition::Vector{Bool},
            buses_available::Vector{Int},
            buses_pasttransition::Vector{Int},
            loads_available::Vector{Bool},
            loads_pasttransition::Vector{Bool},
            shunts_available::Vector{Bool},
            shunts_pasttransition::Vector{Bool}
        )
    end
end

""
function update_other_states!(states::States, statetransition::StateTransition, system::SystemModel)

    states.branches_available .= statetransition.branches_available
    states.commonbranches_available .= statetransition.commonbranches_available
    states.generators_available .= statetransition.generators_available
    states.storages_available .= statetransition.storages_available
    states.buses_available .= field(system, :buses, :bus_type)
    fill!(states.commonbranches_available, 1)
    fill!(states.loads_available, 1)
    fill!(states.shunts_available, 1)

    return
end

""
function record_other_states!(states::States)
    
    states.branches_pasttransition .= states.branches_available
    states.commonbranches_pasttransition .= states.commonbranches_available
    states.generators_pasttransition .= states.generators_available
    states.storages_pasttransition .= states.storages_available
    states.buses_pasttransition .= states.buses_available
    states.loads_pasttransition .= states.loads_available
    states.shunts_pasttransition .= states.shunts_available
    return
end
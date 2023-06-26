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
    branches_flow_from::Vector{Float64}
    branches_flow_to::Vector{Float64}

    commonbranches_available::Vector{Bool}
    commonbranches_pasttransition::Vector{Bool}

    generators_available::Vector{Bool}
    generators_pasttransition::Vector{Bool}

    storages_available::Vector{Bool}
    storages_pasttransition::Vector{Bool}
    stored_energy::Vector{Float64}

    buses_available::Vector{Int}
    buses_pasttransition::Vector{Int}
    buses_cap_curtailed_p::Vector{Float64}
    buses_cap_curtailed_q::Vector{Float64}

    loads_available::Vector{Bool}
    loads_pasttransition::Vector{Bool}

    shunts_available::Vector{Bool}
    shunts_pasttransition::Vector{Bool}

    function States(system::SystemModel{N}) where {N}

        nbranches = length(system.branches)
        branches_available = Vector{Bool}(undef, nbranches)
        branches_pasttransition = Vector{Bool}(undef, nbranches)
        branches_flow_from = Vector{Float64}(undef, nbranches) # Active power withdrawn at the from bus
        branches_flow_to = Vector{Float64}(undef, nbranches) # Active power withdrawn at the from bus

        ncommonbranches = length(system.commonbranches)
        commonbranches_available = Vector{Bool}(undef, ncommonbranches)
        commonbranches_pasttransition = Vector{Bool}(undef, ncommonbranches)

        ngens = length(system.generators)
        generators_available = Vector{Bool}(undef, ngens)
        generators_pasttransition = Vector{Bool}(undef, ngens)

        nstors = length(system.storages)
        storages_available = Vector{Bool}(undef, nstors)
        storages_pasttransition = Vector{Bool}(undef, nstors)
        stored_energy = Vector{Float64}(undef, nstors) #stored energy

        nbuses = length(system.buses)
        buses_available = Vector{Int}(undef, nbuses)
        buses_pasttransition = Vector{Int}(undef, nbuses)

        for k in 1:nbuses
            buses_available[k] = field(system, :buses, :bus_type)[k]
            buses_pasttransition[k] = field(system, :buses, :bus_type)[k]
        end

        buses_cap_curtailed_p = Vector{Float64}(undef, nbuses) #curtailed load in p.u. (active power)
        buses_cap_curtailed_q = Vector{Float64}(undef, nbuses) #curtailed load in p.u. (reactive power)

        nloads = length(system.loads)
        loads_available = Vector{Bool}(undef, nloads)
        loads_pasttransition = Vector{Bool}(undef, nloads)

        nshunts = length(system.shunts)
        shunts_available = Vector{Bool}(undef, nshunts)
        shunts_pasttransition = Vector{Bool}(undef, nshunts)

        fill!(branches_available, 1)
        fill!(branches_pasttransition, 1)
        fill!(branches_flow_from, 0.0)
        fill!(branches_flow_to, 0.0)
        fill!(commonbranches_available, 1)
        fill!(commonbranches_pasttransition, 1)
        fill!(generators_available, 1)
        fill!(generators_pasttransition, 1)
        fill!(storages_available, 1)
        fill!(storages_pasttransition, 1)
        fill!(stored_energy, 0.0)
        fill!(buses_cap_curtailed_p, 0.0)
        fill!(buses_cap_curtailed_q, 0.0)
        fill!(loads_available, 1)
        fill!(loads_pasttransition, 1)
        fill!(shunts_available, 1)
        fill!(shunts_pasttransition, 1)

        return new(
            branches_available,
            branches_pasttransition,
            branches_flow_from,
            branches_flow_to,
            commonbranches_available,
            commonbranches_pasttransition,
            generators_available,
            generators_pasttransition,
            storages_available,
            storages_pasttransition,
            stored_energy,
            buses_available,
            buses_pasttransition,
            buses_cap_curtailed_p,
            buses_cap_curtailed_q,
            loads_available,
            loads_pasttransition,
            shunts_available,
            shunts_pasttransition
        )
    end
end
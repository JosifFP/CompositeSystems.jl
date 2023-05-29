
"ComponentStates structure with matrices for Sequential MCS"
struct ComponentStates

    buses::Matrix{Int}
    loads::Matrix{Bool}
    branches::Matrix{Bool}
    commonbranches::Matrix{Bool}
    shunts::Matrix{Bool}
    generators::Matrix{Bool}
    storages::Matrix{Bool}
    stored_energy::Matrix{Float64}
    p_curtailed::Vector{Float64}
    q_curtailed::Vector{Float64}
    flow_from::Vector{Float64}
    flow_to::Vector{Float64}

end

"ComponentStates structure with matrices for Sequential MCS"
function ComponentStates(system::SystemModel{N}; available::Bool=false) where {N}

    bus_type = field(system, :buses, :bus_type)
    buses = Array{Int, 2}(undef, length(system.buses), N)

    for j in 1:N
        for i in eachindex(system.buses.keys)
            buses[i,j] = bus_type[i]
        end
    end

    loads = Array{Bool, 2}(undef, length(system.loads), N)
    branches = Array{Bool, 2}(undef, length(system.branches), N)
    shunts = Array{Bool, 2}(undef, length(system.shunts), N)
    commonbranches = Array{Bool, 2}(undef, length(system.commonbranches), N)
    generators = Array{Bool, 2}(undef, length(system.generators), N)
    storages = Array{Bool, 2}(undef, length(system.storages), N)

    stored_energy = Array{Float64, 2}(undef, length(system.storages), N) #stored energy
    p_curtailed = Array{Float64}(undef, length(system.buses)) #curtailed load in p.u. (active power)
    q_curtailed = Array{Float64}(undef, length(system.buses)) #curtailed load in p.u. (reactive power)
    flow_from = Array{Float64}(undef, length(system.branches)) # Active power withdrawn at the from bus
    flow_to = Array{Float64}(undef, length(system.branches)) # Active power withdrawn at the from bus

    fill!(loads, 1)
    fill!(shunts, 1)
    fill!(stored_energy, 0)
    fill!(p_curtailed, 0)
    fill!(q_curtailed, 0)
    fill!(flow_from, 0)
    fill!(flow_to, 0)
    
    if available==true
        fill!(branches, 1)
        fill!(commonbranches, 1)
        fill!(generators, 1)
        fill!(storages, 1)
    end

    return ComponentStates(
        buses, loads, branches, commonbranches, shunts, generators, 
        storages, stored_energy, p_curtailed, q_curtailed, flow_from, flow_to
    )
end

""
struct StateTransition

    branches_available::Vector{Bool}
    branches_nexttransition::Vector{Int}
    shunts_available::Vector{Bool}
    shunts_nexttransition::Vector{Int}
    generators_available::Vector{Bool}
    generators_nexttransition::Vector{Int}
    commonbranches_available::Vector{Bool}
    commonbranches_nexttransition::Vector{Int}
    storages_available::Vector{Bool}
    storages_nexttransition::Vector{Int}

    function StateTransition(system::SystemModel)

        nbranches = length(system.branches)
        branches_available = Vector{Bool}(undef, nbranches)
        branches_nexttransition= Vector{Int}(undef, nbranches)

        nshunts = length(system.shunts)
        shunts_available = Vector{Bool}(undef, nshunts)
        shunts_nexttransition= Vector{Int}(undef, nshunts)

        ngens = length(system.generators)
        generators_available = Vector{Bool}(undef, ngens)
        generators_nexttransition= Vector{Int}(undef, ngens)

        ncommonbranches = length(system.commonbranches)
        commonbranches_available = Vector{Bool}(undef, ncommonbranches)
        commonbranches_nexttransition= Vector{Int}(undef, ncommonbranches)

        nstors = length(system.storages)
        storages_available = Vector{Bool}(undef, nstors)
        storages_nexttransition = Vector{Int}(undef, nstors)
        
        return new(
            branches_available, branches_nexttransition,
            shunts_available, shunts_nexttransition,
            generators_available, generators_nexttransition,
            commonbranches_available, commonbranches_nexttransition,
            storages_available, storages_nexttransition
        )
    end
end
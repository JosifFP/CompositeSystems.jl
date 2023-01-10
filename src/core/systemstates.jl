"Definition of States"
abstract type AbstractState end

"SystemStates structure with matrices for Sequential MCS"
struct SystemStates <: AbstractState

    buses::Matrix{Int}
    loads::Matrix{Bool}
    branches::Matrix{Bool}
    commonbranches::Matrix{Bool}
    shunts::Matrix{Bool}
    generators::Matrix{Float32}
    storages::Matrix{Bool}
    generatorstorages::Matrix{Bool}
    se::Matrix{Float64}
    gse::Matrix{Float64}
    plc::Matrix{Float64}
    qlc::Matrix{Float64}
    system::Vector{Bool}
    #loads_nexttransition::Vector{Int}
    #branches_nexttransition::Vector{Int}
    #shunts_nexttransition::Vector{Int}
    #generators_nexttransition::Vector{Int}
    #storages_nexttransition::Vector{Int}
    #generatorstorages_nexttransition::Vector{Int}
end

"SystemStates structure with matrices for Sequential MCS"
function SystemStates(system::SystemModel{N}; available::Bool=false) where {N}

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
    generators = Array{Float32, 2}(undef, length(system.generators), N)
    storages = Array{Bool, 2}(undef, length(system.storages), N)
    generatorstorages = Array{Bool, 2}(undef, length(system.generatorstorages), N)
    sys = Array{Bool, 1}(undef, N)

    se = Array{Float64, 2}(undef, length(system.storages), N) #stored energy
    gse = Array{Float64, 2}(undef, length(system.generatorstorages), N) #stored energy
    plc = Array{Float64, 2}(undef, length(system.buses), N)
    qlc = Array{Float64, 2}(undef, length(system.buses), N)

    fill!(loads, 1)
    fill!(shunts, 1)
    fill!(se, 0)
    fill!(gse, 0)
    fill!(plc, 0)
    fill!(qlc, 0)
    fill!(sys, 1)

    if available==true
        fill!(branches, 1)
        fill!(commonbranches, 1)
        fill!(shunts, 1)
        fill!(generators, 1)
        fill!(storages, 1)
        fill!(generatorstorages, 1)
    end

    return SystemStates(buses, loads, branches, commonbranches, shunts, generators, storages, generatorstorages, se, gse, plc, qlc, sys)
    
end

""
struct NextTransition <: AbstractState

    generators_available::Vector{Bool}
    generators_nexttransition::Vector{Int}

    branches_available::Vector{Bool}
    branches_nexttransition::Vector{Int}

    commonbranches_available::Vector{Bool}
    commonbranches_nexttransition::Vector{Int}

    storages_available::Vector{Bool}
    storages_nexttransition::Vector{Int}

    function NextTransition(system::SystemModel)

        ngens = length(system.generators)
        generators_available = Vector{Bool}(undef, ngens)
        generators_nexttransition= Vector{Int}(undef, ngens)

        nbranches = length(system.branches)
        branches_available = Vector{Bool}(undef, nbranches)
        branches_nexttransition= Vector{Int}(undef, nbranches)

        ncommonbranches = length(system.commonbranches)
        commonbranches_available = Vector{Bool}(undef, ncommonbranches)
        commonbranches_nexttransition= Vector{Int}(undef, ncommonbranches)

        nstors = length(system.storages)
        storages_available = Vector{Bool}(undef, nstors)
        storages_nexttransition = Vector{Int}(undef, nstors)

        #nshunts = length(system.shunts)
        #shunts_available = Vector{Bool}(undef, nshunts)
        #shunts_nexttransition= Vector{Int}(undef, nshunts)
        #nstors = length(system.storages)
        #generatorstorages_available = Vector{Bool}(undef, nstors)
        #generatorstorages_nexttransition = Vector{Int}(undef, nstors)

        return new(
            generators_available, generators_nexttransition,
            branches_available, branches_nexttransition,
            commonbranches_available, commonbranches_nexttransition,
            storages_available, storages_nexttransition
        )

    end

end
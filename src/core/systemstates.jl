"Definition of States"
abstract type AbstractState end

struct SystemStates <: AbstractState

    buses::Matrix{Int}
    loads::Matrix{Bool}
    branches::Matrix{Bool}
    shunts::Matrix{Bool}
    interfaces::Matrix{Bool}
    generators::Matrix{Bool}
    generators_de::Matrix{Float32}
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

"SystemStates structure for Sequential MCS"
function SystemStates(system::SystemModel{N}; available::Bool=false) where {N}

    bus_type = field(system, :buses, :bus_type)
    buses = Array{Int, 2}(undef, length(system.buses), N)

    for j in 1:N
        for i in eachindex(system.buses.keys)
            buses[i,j] = bus_type[i]
        end
    end

    loads = Array{Bool, 2}(undef, length(system.loads), N)
    #loads_nexttransition = Int[]
    branches = Array{Bool, 2}(undef, length(system.branches), N)
    #branches_nexttransition = Int[]
    shunts = Array{Bool, 2}(undef, length(system.shunts), N)
    #shunts_nexttransition = Int[]
    interfaces = Array{Bool, 2}(undef, length(system.interfaces), N)
    #interfaces_nexttransition = Int[]
    generators = Array{Bool, 2}(undef, length(system.generators), N)
    generators_de = Array{Float32, 2}(undef, length(system.generators), N)
    #generators_nexttransition = Int[]
    storages = Array{Bool, 2}(undef, length(system.storages), N)
    #storages_nexttransition = Int[]
    generatorstorages = Array{Bool, 2}(undef, length(system.generatorstorages), N)
    #generatorstorages_nexttransition = Int[]

    se = Array{Float64, 2}(undef, length(system.storages), N) #stored energy
    gse = Array{Float64, 2}(undef, length(system.generatorstorages), N) #stored energy
    plc = Array{Float64, 2}(undef, length(system.loads), N)
    qlc = Array{Float64, 2}(undef, length(system.loads), N)
    sys = Array{Bool, 1}(undef, N)

    fill!(loads, 1)
    fill!(se, 0)
    fill!(gse, 0)
    fill!(plc, 0)
    fill!(qlc, 0)
    fill!(sys, 1)

    if available==true
        fill!(loads, 1)
        fill!(branches, 1)
        fill!(shunts, 1)
        fill!(interfaces, 1)
        fill!(generators, 1)
        fill!(generators_de, 1)
        fill!(storages, 1)
        fill!(generatorstorages, 1)
    end

    return SystemStates(buses, loads, branches, shunts, interfaces, generators, generators_de, storages, generatorstorages, se, gse, plc, qlc, sys)
    
end
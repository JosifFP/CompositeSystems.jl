"Definition of States"
abstract type AbstractState end

struct SystemStates <: AbstractState

    buses::Matrix{Int}
    loads::Matrix{Bool}
    branches::Matrix{Bool}
    commonbranches::Matrix{Bool}
    shunts::Matrix{Bool}
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
    branches = Array{Bool, 2}(undef, length(system.branches), N)
    shunts = Array{Bool, 2}(undef, length(system.shunts), N)
    commonbranches = Array{Bool, 2}(undef, length(system.commonbranches), N)
    generators = Array{Bool, 2}(undef, length(system.generators), N)
    generators_de = Array{Float32, 2}(undef, length(system.generators), N)
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
        fill!(generators_de, 1)
        fill!(storages, 1)
        fill!(generatorstorages, 1)
    end

    return SystemStates(buses, loads, branches, commonbranches, shunts, generators, generators_de, storages, generatorstorages, se, gse, plc, qlc, sys)
    
end
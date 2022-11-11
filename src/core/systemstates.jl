"Definition of States"
abstract type AbstractState end

struct SystemStates <: AbstractState

    buses::Matrix{Int}
    loads::Matrix{Bool}
    branches::Matrix{Bool}
    shunts::Matrix{Bool}
    generators::Matrix{Bool}
    storages::Matrix{Bool}
    generatorstorages::Matrix{Bool}
    storages_energy::Matrix{Float16}
    generatorstorages_energy::Matrix{Float16}
    system::Vector{Bool}
    #loads_nexttransition::Vector{Int}
    #branches_nexttransition::Vector{Int}
    #shunts_nexttransition::Vector{Int}
    #generators_nexttransition::Vector{Int}
    #storages_nexttransition::Vector{Int}
    #generatorstorages_nexttransition::Vector{Int}
end

"SystemStates structure for Sequential MCS"
function SystemStates(system::SystemModel{N}; sequential::Bool=true) where {N}

    bus_type = field(system, :buses, :bus_type)
    buses = Array{Int, 2}(undef, length(system.buses), N)

    @inbounds for j in 1:N
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
    generators = Array{Bool, 2}(undef, length(system.generators), N)
    #generators_nexttransition = Int[]
    storages = Array{Bool, 2}(undef, length(system.storages), N)
    #storages_nexttransition = Int[]
    generatorstorages = Array{Bool, 2}(undef, length(system.generatorstorages), N)
    #generatorstorages_nexttransition = Int[]
    storages_energy = zeros(Float16, Base.length(system.storages), N)
    generatorstorages_energy = zeros(Float16, Base.length(system.generatorstorages), N)
    
    sys = Array{Bool, 1}(undef, N)
    fill!(sys, 1)

    return SystemStates(
        buses, loads, branches, shunts, generators, storages, generatorstorages,
        storages_energy, generatorstorages_energy, sys)
end

# "SystemStates structure for NonSequential MCS"
# function SystemStates(system::SystemModel{N}, method::NonSequentialMCS) where {N}

#     @inbounds buses = field(system, :buses, :bus_type)

#     @inbounds loads = Array{Bool, 1}(undef, length(system.loads))
#     @inbounds loads_nexttransition = Array{Int, 1}(undef, length(system.loads))
        
#     @inbounds branches = Array{Bool, 1}(undef, length(system.branches))
#     @inbounds branches_nexttransition = Array{Int, 1}(undef, length(system.branches))

#     @inbounds shunts = Array{Bool, 1}(undef, length(system.shunts))
#     @inbounds shunts_nexttransition = Array{Int, 1}(undef, length(system.shunts))

#     @inbounds generators = Array{Bool, 1}(undef, length(system.generators))
#     @inbounds generators_nexttransition = Array{Int, 1}(undef, length(system.generators))

#     @inbounds storages = Array{Bool, 1}(undef, length(system.storages))
#     @inbounds storages_nexttransition = Array{Int, 1}(undef, length(system.storages))

#     @inbounds generatorstorages = Array{Bool, 1}(undef, length(system.generatorstorages))
#     @inbounds generatorstorages_nexttransition = Array{Int, 1}(undef, length(system.generatorstorages))

#     @inbounds storages_energy = Array{Float16, 1}(undef, length(system.storages))
#     @inbounds generatorstorages_energy = Array{Float16, 1}(undef, length(system.generatorstorages))
    
#     @inbounds sys = [true]

#     return SystemStates(
#         buses, loads, branches, shunts, generators, storages, generatorstorages,
#         loads_nexttransition, branches_nexttransition, shunts_nexttransition, 
#         generators_nexttransition, storages_nexttransition, generatorstorages_nexttransition,
#         storages_energy, generatorstorages_energy, sys)
# end
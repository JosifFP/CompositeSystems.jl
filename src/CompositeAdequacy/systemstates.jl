"Definition of States"
abstract type AbstractState end
abstract type FAILED <: AbstractState end
abstract type SUCCESSFUL <: AbstractState end
struct S{Bool} end
Status(::Type{S{false}}) = FAILED
Status(::Type{S{true}}) = SUCCESSFUL

struct SystemStates <: AbstractState

    loads::Array{Bool}
    branches::Array{Bool}
    shunts::Array{Bool}
    generators::Array{Bool}
    storages::Array{Bool}
    generatorstorages::Array{Bool}

    loads_nexttransition::Union{Nothing, Vector{Int}}
    branches_nexttransition::Union{Nothing, Vector{Int}}
    shunts_nexttransition::Union{Nothing, Vector{Int}}
    generators_nexttransition::Union{Nothing, Vector{Int}}
    storages_nexttransition::Union{Nothing, Vector{Int}}
    generatorstorages_nexttransition::Union{Nothing, Vector{Int}}

    storages_energy::Array{Float16}
    generatorstorages_energy::Array{Float16}

    system::Union{Nothing, Array{Bool}}

end

"SystemStates structure for Sequential MCS"
function SystemStates(system::SystemModel{N}, method::SequentialMCS) where {N}

    @inbounds loads = ones(Bool, length(system.loads), N)
    loads_nexttransition = nothing

    @inbounds branches = ones(Bool, length(system.branches), N)
    branches_nexttransition = nothing

    @inbounds shunts = ones(Bool, length(system.shunts), N)
    shunts_nexttransition = nothing

    @inbounds generators = ones(Bool, length(system.generators), N)
    generators_nexttransition = nothing

    @inbounds storages = ones(Bool, length(system.storages), N)
    storages_nexttransition = nothing

    @inbounds generatorstorages = ones(Bool, length(system.generatorstorages), N)
    generatorstorages_nexttransition = nothing

    @inbounds storages_energy = zeros(Float16, Base.length(system.storages), N)
    @inbounds generatorstorages_energy = zeros(Float16, Base.length(system.generatorstorages), N)
    
    @inbounds system = Array{Bool, 1}(undef, N)

    return SystemStates(
        loads, branches, shunts, generators, storages, generatorstorages,
        loads_nexttransition, branches_nexttransition, shunts_nexttransition, 
        generators_nexttransition, storages_nexttransition, generatorstorages_nexttransition,
        storages_energy, generatorstorages_energy, system)
end

"SystemStates structure for NonSequential MCS"
function SystemStates(system::SystemModel{N}, method::NonSequentialMCS) where {N}

    @inbounds loads = Array{Bool, 1}(undef, length(system.loads))
    @inbounds loads_nexttransition = Array{Int, 1}(undef, length(system.loads))
        
    @inbounds branches = Array{Bool, 1}(undef, length(system.branches))
    @inbounds branches_nexttransition = Array{Int, 1}(undef, length(system.branches))

    @inbounds shunts = Array{Bool, 1}(undef, length(system.shunts))
    @inbounds shunts_nexttransition = Array{Int, 1}(undef, length(system.shunts))

    @inbounds generators = Array{Bool, 1}(undef, length(system.generators))
    @inbounds generators_nexttransition = Array{Int, 1}(undef, length(system.generators))

    @inbounds storages = Array{Bool, 1}(undef, length(system.storages))
    @inbounds storages_nexttransition = Array{Int, 1}(undef, length(system.storages))

    @inbounds generatorstorages = Array{Bool, 1}(undef, length(system.generatorstorages))
    @inbounds generatorstorages_nexttransition = Array{Int, 1}(undef, length(system.generatorstorages))

    @inbounds storages_energy = Array{Float16, 1}(undef, length(system.storages))
    @inbounds generatorstorages_energy = Array{Float16, 1}(undef, length(system.generatorstorages))
    
    @inbounds system = [true]

    return SystemStates(
        loads, branches, shunts, generators, storages, generatorstorages,
        loads_nexttransition, branches_nexttransition, shunts_nexttransition, 
        generators_nexttransition, storages_nexttransition, generatorstorages_nexttransition,
        storages_energy, generatorstorages_energy, system)
end


"SystemStates structure for Tests"
function SystemStates(system::SystemModel{N}, method::Type{Tests}) where {N}

    @inbounds loads = ones(Bool, length(system.loads), N)
    loads_nexttransition = nothing
        
    @inbounds branches = ones(Bool, length(system.branches), N)
    branches_nexttransition = nothing

    @inbounds shunts = ones(Bool, length(system.shunts), N)
    shunts_nexttransition = nothing

    @inbounds generators = ones(Bool, length(system.generators), N)
    generators_nexttransition = nothing

    @inbounds storages = ones(Bool, length(system.storages), N)
    storages_nexttransition = nothing

    @inbounds generatorstorages = ones(Bool, length(system.generatorstorages), N)
    generatorstorages_nexttransition = nothing

    @inbounds storages_energy = zeros(Float16, Base.length(system.storages), N)
    @inbounds generatorstorages_energy = zeros(Float16, Base.length(system.generatorstorages), N)
    
    @inbounds system = ones(Bool, N)

    return SystemStates(
        loads, branches, shunts, generators, storages, generatorstorages,
        loads_nexttransition, branches_nexttransition, shunts_nexttransition, 
        generators_nexttransition, storages_nexttransition, generatorstorages_nexttransition,
        storages_energy, generatorstorages_energy, system)
end
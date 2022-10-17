""
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

    @inbounds storages_energy = zeros(Float16, Base.length(system.storages), N)
    @inbounds generatorstorages_energy = zeros(Float16, Base.length(system.generatorstorages), N)
    
    @inbounds groupstates = GroupStates(method, N)

    return SystemStates(
        loads, branches, shunts, generators, storages, generatorstorages,
        loads_nexttransition, branches_nexttransition, shunts_nexttransition, 
        generators_nexttransition, storages_nexttransition, generatorstorages_nexttransition,
        storages_energy, generatorstorages_energy, groupstates)
end

""
function GroupStates(::SequentialMCS, N::Int)

    return GroupStates(
        Vector{Bool}(undef, N), Vector{Bool}(undef, N), 
        Vector{Bool}(undef, N), Vector{Bool}(undef, N),
        Vector{Bool}(undef, N), Vector{Bool}(undef, N), 
        Vector{Bool}(undef, N)
    )
end
""
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
function GroupStates(::NonSequentialMCS, N::Int)

    return GroupStates(
        Vector{Bool}(undef, N), nothing, 
        nothing, nothing,
        nothing, nothing, 
        nothing
    )
end
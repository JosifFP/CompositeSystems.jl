struct SystemState

    loads::Matrix{Bool}
    branches::Matrix{Bool}
    shunts::Matrix{Bool}
    generators::Matrix{Bool}
    storages::Matrix{Bool}
    generatorstorages::Matrix{Bool}
    storages_energy::Matrix{Float16}
    generatorstorages_energy::Matrix{Float16}
    condition::Vector{Bool}

    function SystemState(system::SystemModel{N}) where {N}

        if all(field(system, Loads, :status))
            @inbounds status_loads = ones(Bool, length(system.loads), N)
        else
            @inbounds status_loads = reduce(hcat, [field(system, Loads, :status) for k in 1:N])
        end

        if all(field(system, Branches, :status))
            @inbounds status_branches = ones(Bool, length(system.branches), N)
        else
            @inbounds status_branches = reduce(hcat, [field(system, Branches, :status) for k in 1:N])
        end

        if all(field(system, Shunts, :status))
            @inbounds status_shunts = ones(Bool, length(system.shunts), N)
        else
            @inbounds status_shunts = reduce(hcat, [field(system, Shunts, :status) for k in 1:N])
        end

        if all(field(system, Generators, :status))
            @inbounds status_generators = ones(Bool, length(system.generators), N)
        else
            @inbounds status_generators = reduce(hcat, [field(system, Generators, :status) for k in 1:N])
        end

        if all(field(system, Generators, :status))
            @inbounds status_generators = ones(Bool, length(system.generators), N)
        else
            @inbounds status_generators = reduce(hcat, [field(system, Generators, :status) for k in 1:N])
        end

        if all(field(system, Storages, :status))
            @inbounds status_storages = ones(Bool, length(system.storages), N)
        else
            @inbounds status_storages = reduce(hcat, [field(system, Storages, :status) for k in 1:N])
        end

        if all(field(system, GeneratorStorages, :status))
            @inbounds status_generatorstorages = ones(Bool, length(system.generatorstorages), N)
        else
            @inbounds status_generatorstorages = reduce(hcat, [field(system, GeneratorStorages, :status) for k in 1:N])
        end

        @inbounds storages_energy = zeros(Float16, Base.length(system.storages), N)
        @inbounds generatorstorages_energy = zeros(Float16, Base.length(system.generatorstorages), N)
        @inbounds condition = ones(Bool, N)

        return new(
            status_loads, status_branches, status_shunts, status_generators, status_storages, status_generatorstorages,
            storages_energy, generatorstorages_energy, condition)
    end

end

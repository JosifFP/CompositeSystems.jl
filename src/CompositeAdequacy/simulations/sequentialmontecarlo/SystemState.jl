struct SystemState

    gens_available::Matrix{Bool}
    stors_available::Matrix{Bool}
    genstors_available::Matrix{Bool}
    branches_available::Matrix{Bool}

    stors_energy::Matrix{Float16}
    genstors_energy::Matrix{Float16}

    failed_generation::Vector{Bool}
    failed_transmission::Vector{Bool}

    function SystemState(system::SystemModel{N}) where N

        @inbounds gens_available = ones(Bool, Base.length(system.generators), N)
        @inbounds stors_available = ones(Bool, Base.length(system.storages), N)
        @inbounds genstors_available = ones(Bool, Base.length(system.generatorstorages), N)
        @inbounds branches_available = ones(Bool, Base.length(system.branches), N)

        @inbounds stors_energy = zeros(Float16, Base.length(system.storages), N)
        @inbounds genstors_energy = zeros(Float16, Base.length(system.generatorstorages), N)

        @inbounds failed_generation = zeros(Bool, N)
        @inbounds failed_transmission = zeros(Bool, N)

        return new(gens_available, stors_available, genstors_available, branches_available, stors_energy, genstors_energy, failed_generation, failed_transmission)

    end

end


Base.:(==)(x::T, y::T) where {T <: SystemState} =
    x.gens_available == y.gens_available &&
    x.stors_available == y.stors_available &&
    x.genstors_available == y.genstors_available &&
    x.branches_available == y.branches_available &&
    x.stors_energy == y.stors_energy &&
    x.genstors_energy == y.genstors_energy &&
    x.failed_generation == y.failed_generation &&
    x.failed_transmission == y.failed_transmission

Base.length(state::SystemState) = length(length(state.gens_available))
abstract type State end
abstract type Success <: State end
abstract type Failed <: State end

struct SystemState

    gens_available::Matrix{Bool}
    stors_available::Matrix{Bool}
    genstors_available::Matrix{Bool}
    branches_available::Matrix{Bool}

    stors_energy::Matrix{Float16}
    genstors_energy::Matrix{Float16}

    condition::Vector{DataType}

    function SystemState(system::SystemModel{N}) where {N}

        @inbounds gens_available = ones(Bool, Base.length(system.generators), N)
        @inbounds stors_available = ones(Bool, Base.length(system.storages), N)
        @inbounds genstors_available = ones(Bool, Base.length(system.generatorstorages), N)
        @inbounds branches_available = ones(Bool, Base.length(system.branches), N)

        @inbounds stors_energy = zeros(Float16, Base.length(system.storages), N)
        @inbounds genstors_energy = zeros(Float16, Base.length(system.generatorstorages), N)
        #@inbounds condition = ones(Bool, N)
        condition = [Success for i in 1:N]

        return new(gens_available, stors_available, genstors_available, branches_available, stors_energy, genstors_energy, condition)

    end

end


Base.:(==)(x::T, y::T) where {T <: SystemState} =
    x.gens_available == y.gens_available &&
    x.stors_available == y.stors_available &&
    x.genstors_available == y.genstors_available &&
    x.branches_available == y.branches_available &&
    x.stors_energy == y.stors_energy &&
    x.genstors_energy == y.genstors_energy &&
    x.condition == y.condition
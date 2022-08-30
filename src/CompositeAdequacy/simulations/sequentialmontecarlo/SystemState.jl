struct SystemState

    gens_available::Vector{Bool}
    stors_available::Vector{Bool}
    stors_energy::Vector{Int}
    genstors_available::Vector{Bool}
    genstors_energy::Vector{Int}
    branches_available::Vector{Bool}
    condition::Bool

    function SystemState(system::SystemModel)

        ngens = Base.length(system.generators)
        gens_available = Vector{Bool}(undef, ngens)

        nstors = Base.length(system.storages)
        stors_available = Vector{Bool}(undef, nstors)
        stors_energy = Vector{Int}(undef, nstors)

        ngenstors = Base.length(system.generatorstorages)
        genstors_available = Vector{Bool}(undef, ngenstors)
        genstors_energy = Vector{Int}(undef, ngenstors)

        nbranches = Base.length(system.branches)
        branches_available = Vector{Bool}(undef, nbranches)

        if 0 in [gens_available; stors_available; genstors_available; branches_available] == true
            condition = 0
        else
            condition =  1
        end

        return new(gens_available, stors_available, stors_energy, genstors_available, genstors_energy, branches_available, condition)

    end

end

struct UpDownSequence

    Up_gens::Matrix{Bool}
    Up_stors::Matrix{Bool}
    Up_genstors::Matrix{Bool}
    Up_branches::Matrix{Bool}

    function UpDownSequence(system::SystemModel{N}) where N

        @inbounds Up_gens = ones(Bool, Base.length(system.generators), N)
        @inbounds Up_stors = ones(Bool, Base.length(system.storages), N)
        @inbounds Up_genstors = ones(Bool, Base.length(system.generatorstorages), N)
        @inbounds Up_branches = ones(Bool, Base.length(system.branches), N)

        return new(Up_gens, Up_stors, Up_genstors, Up_branches)

    end

end
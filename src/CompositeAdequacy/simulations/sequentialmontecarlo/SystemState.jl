struct SystemState

    gens_available::Vector{Bool}
    stors_available::Vector{Bool}
    stors_energy::Vector{Int}
    genstors_available::Vector{Bool}
    genstors_energy::Vector{Int}
    branches_available::Vector{Bool}

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

        return new(gens_available, stors_available, stors_energy, genstors_available, genstors_energy, branches_available)

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

# struct UpDownSequence

#     UpDownseq::Array{Bool,3}

#     function UpDownSequence(system::SystemModel{N}) where N

#         @inbounds gens_sequence = ones(Bool, length(system.generators), N)::Matrix{Bool}
#         @inbounds stors_sequence = ones(Bool, length(system.storages), N)::Matrix{Bool}
#         @inbounds genstors_sequence = ones(Bool, length(system.generatorstorages), N)::Matrix{Bool}
#         @inbounds branches_sequence = ones(Bool, length(system.branches), N)::Matrix{Bool}

#         UpDownseq = cat(gens_sequence, stors_sequence, genstors_sequence, branches_sequence, dims=(1,3))

#         return UpDownseq
#     end
# end
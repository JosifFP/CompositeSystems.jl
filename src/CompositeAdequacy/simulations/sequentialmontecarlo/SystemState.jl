struct SystemState

    gens_available::Vector{Bool}
    stors_available::Vector{Bool}
    stors_energy::Vector{Int}
    genstors_available::Vector{Bool}
    genstors_energy::Vector{Int}
    lines_available::Vector{Bool}

    function SystemState(system::SystemModel)

        ngens = Base.length(system.generators)
        gens_available = Vector{Bool}(undef, ngens)

        nstors = Base.length(system.storages)
        stors_available = Vector{Bool}(undef, nstors)
        stors_energy = Vector{Int}(undef, nstors)

        ngenstors = Base.length(system.generatorstorages)
        genstors_available = Vector{Bool}(undef, ngenstors)
        genstors_energy = Vector{Int}(undef, ngenstors)

        nlines = Base.length(system.lines)
        lines_available = Vector{Bool}(undef, nlines)

        return new(gens_available, stors_available, stors_energy, genstors_available, genstors_energy, lines_available)

    end

end

struct UpDownSequence

    Up_gens::Matrix{Bool}
    Up_stors::Matrix{Bool}
    Up_genstors::Matrix{Bool}
    Up_lines::Matrix{Bool}

    function UpDownSequence(system::SystemModel{N}) where N

        @inbounds Up_gens = ones(Bool, Base.length(system.generators), N)
        @inbounds Up_stors = ones(Bool, Base.length(system.storages), N)
        @inbounds Up_genstors = ones(Bool, Base.length(system.generatorstorages), N)
        @inbounds Up_lines = ones(Bool, Base.length(system.lines), N)

        return new(Up_gens, Up_stors, Up_genstors, Up_lines)

    end

end

# struct UpDownSequence

#     UpDownseq::Array{Bool,3}

#     function UpDownSequence(system::SystemModel{N}) where N

#         @inbounds gens_sequence = ones(Bool, length(system.generators), N)::Matrix{Bool}
#         @inbounds stors_sequence = ones(Bool, length(system.storages), N)::Matrix{Bool}
#         @inbounds genstors_sequence = ones(Bool, length(system.generatorstorages), N)::Matrix{Bool}
#         @inbounds lines_sequence = ones(Bool, length(system.lines), N)::Matrix{Bool}

#         UpDownseq = cat(gens_sequence, stors_sequence, genstors_sequence, lines_sequence, dims=(1,3))

#         return UpDownseq
#     end
# end
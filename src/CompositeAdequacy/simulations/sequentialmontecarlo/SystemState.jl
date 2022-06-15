struct SystemState

    gens_available::Vector{Bool}
    gens_nexttransition::Vector{Int}

    stors_available::Vector{Bool}
    stors_nexttransition::Vector{Int}
    stors_energy::Vector{Int}

    genstors_available::Vector{Bool}
    genstors_nexttransition::Vector{Int}
    genstors_energy::Vector{Int}

    lines_available::Vector{Bool}
    lines_nexttransition::Vector{Int}

    function SystemState(system::SystemModel)

        ngens = Base.length(system.generators)
        gens_available = Vector{Bool}(undef, ngens)
        gens_nexttransition= Vector{Int}(undef, ngens)

        nstors = Base.length(system.storages)
        stors_available = Vector{Bool}(undef, nstors)
        stors_nexttransition = Vector{Int}(undef, nstors)
        stors_energy = Vector{Int}(undef, nstors)

        ngenstors = Base.length(system.generatorstorages)
        genstors_available = Vector{Bool}(undef, ngenstors)
        genstors_nexttransition = Vector{Int}(undef, ngenstors)
        genstors_energy = Vector{Int}(undef, ngenstors)

        nlines = Base.length(system.lines)
        lines_available = Vector{Bool}(undef, nlines)
        lines_nexttransition = Vector{Int}(undef, nlines)

        return new(
            gens_available, gens_nexttransition,
            stors_available, stors_nexttransition, stors_energy,
            genstors_available, genstors_nexttransition, genstors_energy,
            lines_available, lines_nexttransition)

    end

end


struct UpDownSequence

    UpDownseq::Array{Bool,3}

    function UpDownSequence(system::SystemModel{N}) where N

        @inbounds gens_sequence = ones(Bool, length(system.generators), N)::Matrix{Bool}
        @inbounds stors_sequence = ones(Bool, length(system.storages), N)::Matrix{Bool}
        @inbounds genstors_sequence = ones(Bool, length(system.generatorstorages), N)::Matrix{Bool}
        @inbounds lines_sequence = ones(Bool, length(system.lines), N)::Matrix{Bool}

        UpDownseq = cat(gens_sequence, stors_sequence, genstors_sequence, lines_sequence, dims=(1,3))

        return UpDownseq
    end
    # function UpDownSequence(
    #     gens_sequence::Union{Matrix{Bool},Vector{Bool}},
    #     stors_sequence::Union{Matrix{Bool},Vector{Bool}},
    #     genstors_sequence::Union{Matrix{Bool},Vector{Bool}},
    #     lines_sequence::Union{Matrix{Bool},Vector{Bool}})

    #     UpDownseq = cat(gens_sequence, stors_sequence, genstors_sequence, lines_sequence, dims=(1,3))

    #     return UpDownseq
    # end
end
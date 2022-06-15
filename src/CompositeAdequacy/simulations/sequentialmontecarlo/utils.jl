function initialize_availability!(
    rng::AbstractRNG,
    sequence::Matrix{Bool},
    availability::Vector{Bool}, nexttransition::Vector{Int},
    devices::AbstractAssets)
    
    for i in 1:length(devices)
        λ = devices.λ[i, 1]
        μ = devices.μ[i, 1]
        if λ != 0.0
            sequence[i,:] = cycles!(rng, λ, μ, sequence[i,:])
        end
        availability[i] = sequence[i,1]
        nexttransition[i] = sequence[i,2]
    end
    return sequence
end

function update_availability!(
    sequence_t::Matrix{Bool},
    availability::Vector{Bool}, nexttransition::Vector{Int},
    ndevices::Int, t_now::Int, N::Int)

    if t_now < N
        for i in 1:ndevices
            availability[i] = sequence_t[i,1]
            nexttransition[i] = sequence_t[i,2]
        end
    end
end

function update_availability!(
    sequence_t::Vector{Bool},
    availability::Vector{Bool}, nexttransition::Vector{Int},
    ndevices::Int, t_now::Int, N::Int)
    for i in 1:ndevices
        availability[i] = sequence_t[1]
        nexttransition[i] = 0
    end
end

function cycles!(
    rng::AbstractRNG, λ::Float64, μ::Float64, sequence::Vector{Bool})

    (ttf,ttr) = T(rng,λ,μ)
    N = length(sequence)
    i=Int(1);
    @inbounds while i + ttf + ttr  < N
        @inbounds sequence[i+ttf : i+ttf+ttr] = [false for _ in i+ttf : i+ttf+ttr]
        #@inbounds vector[i+ttf : i+ttf+ttr] = zeros(Bool, ttr)
        i = i + ttf + ttr
        (ttf,ttr) = T(rng,λ,μ)
    end
    return sequence
end

# T(λ::Float64, μ::Float64) = ((x->trunc(Int32, x)).(rand(Distributions.Exponential(1/λ))),
#                                 (y->trunc(Int32, y)).(rand(Distributions.Exponential(1/μ)))
# )::Tuple{Int32,Int32}

T(rng::AbstractRNG, λ::Float64, μ::Float64) = ((x->trunc(Int32, x)).((-1/λ)log(rand(rng))),
                                (y->trunc(Int32, y)).((-1/μ)log(rand(rng)))
)::Tuple{Int32,Int32}

function available_capacity(
    availability::Vector{Bool},
    lines::Lines,
    idxs::UnitRange{Int}, t::Int
)

    avcap_forward = 0
    avcap_backward = 0

    for i in idxs
        if availability[i]
            avcap_forward += lines.forward_capacity[i, t]
            avcap_backward += lines.backward_capacity[i, t]
        end
    end

    return avcap_forward, avcap_backward

end

function available_capacity(
    availability::Vector{Bool},
    gens::Generators,
    idxs::UnitRange{Int}, t::Int
)

    caps = gens.capacity
    avcap = 0

    for i in idxs
        availability[i] && (avcap += caps[i, t])
    end

    return avcap

end

function update_energy!(
    stors_energy::Vector{Int},
    stors::AbstractAssets,
    t::Int
)

    for i in 1:length(stors_energy)

        soc = stors_energy[i]
        efficiency = stors.carryover_efficiency[i,t]
        maxenergy = stors.energy_capacity[i,t]

        # Decay SoC
        soc = round(Int, soc * efficiency)

        # Shed SoC above current energy limit
        stors_energy[i] = min(soc, maxenergy)

    end

end

function maxtimetocharge_discharge(system::SystemModel)

    if length(system.storages) > 0

        if any(iszero, system.storages.charge_capacity)
            stor_charge_max = length(system.timestamps) + 1
        else
            stor_charge_durations =
                system.storages.energy_capacity ./ system.storages.charge_capacity
            stor_charge_max = ceil(Int, maximum(stor_charge_durations))
        end

        if any(iszero, system.storages.discharge_capacity)
            stor_discharge_max = length(system.timestamps) + 1
        else
            stor_discharge_durations =
                system.storages.energy_capacity ./ system.storages.discharge_capacity
            stor_discharge_max = ceil(Int, maximum(stor_discharge_durations))
        end

    else

        stor_charge_max = 0
        stor_discharge_max = 0

    end

    if length(system.generatorstorages) > 0

        if any(iszero, system.generatorstorages.charge_capacity)
            genstor_charge_max = length(system.timestamps) + 1
        else
            genstor_charge_durations =
                system.generatorstorages.energy_capacity ./ system.generatorstorages.charge_capacity
            genstor_charge_max = ceil(Int, maximum(genstor_charge_durations))
        end

        if any(iszero, system.generatorstorages.discharge_capacity)
            genstor_discharge_max = length(system.timestamps) + 1
        else
            genstor_discharge_durations =
                system.generatorstorages.energy_capacity ./ system.generatorstorages.discharge_capacity
            genstor_discharge_max = ceil(Int, maximum(genstor_discharge_durations))
        end

    else

        genstor_charge_max = 0
        genstor_discharge_max = 0

    end

    return (max(stor_charge_max, genstor_charge_max),
            max(stor_discharge_max, genstor_discharge_max))

end

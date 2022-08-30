function initialize_availability!(
    rng::AbstractRNG,
    sequence::Matrix{Bool},
    devices::AbstractAssets, N::Int)
    
    ndevices = Base.length(devices)

    for i in 1:ndevices
        λ = devices.λ[i]/N
        μ = devices.μ[i]/N
        if λ != 0.0 || μ != 0.0
            sequence[i,:] = cycles!(rng, λ, μ, N)
        end
    end

    return sequence
    
end

function update_availability!(
    availability::Vector{Bool}, sequences_device::Vector{Bool}, ndevices::Int)

    for i in 1:ndevices
        availability[i] = sequences_device[i]
    end

    return availability
end

function cycles!(
    rng::AbstractRNG, λ::Float32, μ::Float32, N::Int)

    sequence = Base.ones(true, N)
    i=Int(0)
    (ttf,ttr) = T(rng,λ,μ)
    if i + ttf > N - ttr && i + ttf < N ttr = N - ttf - i end

    @inbounds while i + ttf + ttr  <= N
        @inbounds sequence[i+ttf+1 : i+ttf+ttr] = [false for _ in i+ttf+1 : i+ttf+ttr]
        i = i + ttf + ttr
        (ttf,ttr) = T(rng,λ,μ)
        if i + ttf + ttr  >= N && i + ttf < N ttr = N - ttf - i end
    end
    return sequence

end

function T(rng, λ::Float32, μ::Float32)::Tuple{Int32,Int32}
    
    ttf = (x->trunc(Int32, x)).((-1/λ)log(rand(rng)))
    ttr = (y->trunc(Int32, y)).((-1/μ)log(rand(rng)))

    while ttf == 0.0 || ttr == 0.0
        ttf = (x->trunc(Int32, x)).((-1/λ)log(rand(rng)))
        ttr = (y->trunc(Int32, y)).((-1/μ)log(rand(rng)))
    end

    return ttf,ttr
end


function available_capacity(
    availability::Vector{Bool},
    branches::Branches,
    idxs::UnitRange{Int}, t::Int
)

    avcap_forward = 0
    avcap_backward = 0

    for i in idxs
        if availability[i]
            avcap_forward += branches.forward_capacity[i, t]
            avcap_backward += branches.backward_capacity[i, t]
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

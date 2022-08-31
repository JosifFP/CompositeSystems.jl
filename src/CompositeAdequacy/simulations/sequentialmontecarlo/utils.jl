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

"Add load curtailment information to data"
function add_load_curtailment_info!(network::Network)
    for i in eachindex(network.load)
        push!(network.load[string(i)], "cost" => float(1000))
    end
end

""
function apply_contingencies!(network_data::Dict{String,Any}, state::SystemState, system::SystemModel{N}) where {N}

    for i in eachindex(system.branches.keys)
        if state.branches_available[i] == false
            #system.network.branch[string(i)]["br_status"] = state.branches_available[i]
            network_data["branch"][string(i)]["br_status"] = state.branches_available[i]
        end
    end

    for i in eachindex(system.generators.keys)
        if state.gens_available[i] == false
            #system.network.gen[string(i)]["gen_status"] = state.gens_available[i]
            network_data["gen"][string(i)]["gen_status"] = state.gens_available[i]
        end
    end

    for i in eachindex(system.storages.keys)
        if state.stors_available[i] == false
            #system.network.storage[string(i)]["status"] = state.stors_available[i]
            network_data["storage"][string(i)]["status"] = state.stors_available[i]
        end
    end

end

function update_condition!(state::SystemState, condition::Bool)
    if 0 in [state.gens_available; state.stors_available; state.genstors_available; state.branches_available] == true
        condition = 0

    else
        condition =  1
    end
end

# ----------------------------------------------------------------------------------------------------------
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
        #efficiency = stors.carryover_efficiency[i,t]
        efficiency = 1.0
        maxenergy = stors.energy_capacity[i,t]

        # Decay SoC
        soc = round(Int, soc * efficiency)

        # Shed SoC above current energy limit
        stors_energy[i] = min(soc, maxenergy)

    end

end

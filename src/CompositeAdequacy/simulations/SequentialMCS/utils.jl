""
function initialize_availability!(
    rng::AbstractRNG,
    availability::Matrix{Bool},
    asset::AbstractAssets, N::Int)

    if field(asset, :status) ≠ false
        for i in 1:length(asset)
            sequence = view(availability, i, :)
            λ = asset.λ[i]/N
            μ = asset.μ[i]/N
            if λ ≠ 0.0 || μ ≠ 0.0
                cycles!(sequence, rng, λ, μ, N)
            else

             end
        end
    else
        fill!(availability, 0)
    end

    return
    
end

""
function cycles!(
    sequence::AbstractArray{Bool}, rng::AbstractRNG, λ::Float64, μ::Float64, N::Int)

    fill!(sequence, 1)
    (ttf,ttr) = T(rng,λ,μ)
    i=Int(1)

    if i + ttf > N - ttr && i + ttf < N ttr = N - ttf - i end

    @inbounds while i + ttf + ttr  <= N
        @inbounds sequence[i+ttf+1 : i+ttf+ttr] = [false for _ in i+ttf+1 : i+ttf+ttr]
        i = i + ttf + ttr
        (ttf,ttr) = T(rng,λ,μ)
        if i + ttf + ttr  >= N && i + ttf < N ttr = N - ttf - i end
    end

    return

end

""
function T(rng, λ::Float64, μ::Float64)::Tuple{Int,Int}
    
    ttf = (x->trunc(Int, x)).((-1/λ)log(rand(rng)))
    ttr = (y->trunc(Int, y)).((-1/μ)log(rand(rng)))

    while ttf == 0.0 || ttr == 0.0
        ttf = (x->trunc(Int, x)).((-1/λ)log(rand(rng)))
        ttr = (y->trunc(Int, y)).((-1/μ)log(rand(rng)))
    end

    return ttf,ttr
end

""
function initialize_availability_system!(states::SystemStates, gens::Generators, loads::Loads, N::Int)

    @inbounds for t in 1:N

        total_gen::Float16 = gens_sum(field(gens, :pmax), filter(k -> field(states, :generators)[k,t], field(gens, :keys)))

        if all(view(field(states, :branches),:,t)) == false
            states.system[t] = false
        else
            if sum(view(field(loads, :pd), :, t)) >= total_gen
                states.system[t] = false
            elseif count(view(field(states, :generators),:,t)) < length(gens) - 2
                states.system[t] = false
            end

        end
    end

end

""
function gens_sum(v_pmax::Vector{Float16}, active_keys::Vector{Int})
    return sum(v_pmax[i] for i in active_keys)
end


# ----------------------------------------------------------------------------------------------------------
# function available_capacity(
#     availability::Vector{Bool},
#     branches::Branches,
#     idxs::UnitRange{Int}, t::Int
# )

#     avcap_forward = 0
#     avcap_backward = 0

#     for i in idxs
#         if availability[i]
#             avcap_forward += branches.forward_capacity[i, t]
#             avcap_backward += branches.backward_capacity[i, t]
#         end
#     end

#     return avcap_forward, avcap_backward

# end

# function available_capacity(
#     availability::Vector{Bool},
#     gens::Generators,
#     idxs::UnitRange{Int}, t::Int
# )

#     caps = gens.capacity
#     avcap = 0

#     for i in idxs
#         availability[i] && (avcap += caps[i, t])
#     end

#     return avcap

# end

# function update_energy!(
#     stors_energy::Vector{Int},
#     stors::AbstractAssets,
#     t::Int
# )

#     for i in 1:length(stors_energy)

#         soc = stors_energy[i]
#         #efficiency = stors.carryover_efficiency[i,t]
#         efficiency = 1.0
#         maxenergy = stors.energy_capacity[i,t]

#         # Decay SoC
#         soc = round(Int, soc * efficiency)

#         # Shed SoC above current energy limit
#         stors_energy[i] = min(soc, maxenergy)

#     end

# end

# ""
# function initialize_availability_system!(states::SystemStates, N::Int)

#     v = vcat(field(states, :branches), field(states, :generators), field(states, :loads))

#     @inbounds for t in 1:N
#         B = filter(i -> states.buses[i]==4, states.buses)
#         if check_status(view(v, :, t)) == false ||  length(B) > 0
#             states.system[t] = false
#         end
#     end
# end

# ""
# function initialize_availability!(states::SystemStates, N::Int)

#     v = vcat(field(states, :branches), field(states, :generators))
#     #filter(field(states, :generators), field(states, :generators))

#     @inbounds for t in 1:N
#         if check_status(view(v, :, t)) == false
#             states.system[t] = false
#         end
#     end
# end
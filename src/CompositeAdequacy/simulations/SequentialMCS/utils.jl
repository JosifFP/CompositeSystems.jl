""
function initialize_availability!(
    rng::AbstractRNG,
    availability::Matrix{Bool},
    availability_de::Matrix{Float32},
    asset::Generators, N::Int)

    for i in asset.keys

        if asset.status[i] ≠ false

            sequence = view(availability, i, :)
            sequence_de = view(availability_de, i, :)
            fill!(sequence, 1)
            fill!(sequence_de, 1)
            λ_updn = asset.λ_updn[i]/N
            μ_updn = asset.μ_updn[i]/N
        
            if asset.state_model[i] == 3

                λ_upde = asset.λ_upde[i]/N
                μ_upde = asset.μ_upde[i]/N
                pde = asset.pde[i]

                if λ_updn ≠ 0.0 && λ_upde ≠ 0.0
                    cycles!(sequence_de, pde, rng, λ_updn, μ_updn, λ_upde, μ_upde, N)
                end

                for k = 1:N
                    #if sequence_de[k] > 0.0 && sequence_de[k] < 1.0 #sequence[k] = false
                    if sequence_de[k] == 0.0
                        sequence[k] = false
                    end
                end

            else
                
                if λ_updn ≠ 0.0
                    cycles!(sequence, rng, λ_updn, μ_updn, N)
                    sequence_de .= Float32.(sequence)
                end

            end
        end
    end

    return availability, availability_de
    
end

""
function initialize_availability!(
    rng::AbstractRNG,
    availability::Matrix{Bool},
    asset::AbstractAssets, N::Int)

    for i in asset.keys
        if asset.status[i] ≠ false
            sequence = view(availability, i, :)
            fill!(sequence, 1)
            λ_updn = asset.λ_updn[i]/N
            μ_updn = asset.μ_updn[i]/N
            if λ_updn ≠ 0.0
                cycles!(sequence, rng, λ_updn, μ_updn, N)
            end
        else
            fill!(sequence, 0)
        end
    end

    return availability
    
end

""
function initialize_availability!(
    rng::AbstractRNG,
    availability::Matrix{Bool},
    asset::CommonBranches, N::Int)

    for i in asset.keys
        sequence = view(availability, i, :)
        fill!(sequence, 1)
        λ_updn = asset.λ_updn[i]/N
        μ_updn = asset.μ_updn[i]/N
        if λ_updn ≠ 0.0
            cycles!(sequence, rng, λ_updn, μ_updn, N)
        end
    end

    return availability
    
end

""
function initialize_availability!(
    rng::AbstractRNG,
    availability::Matrix{Int},
    asset::Buses, N::Int)
    
    bus_type = field(asset, :bus_type)

    for j in 1:N
        for i in eachindex(asset.keys)
            availability[i,j] = bus_type[i]
        end
    end

    return availability
    
end

""
function cycles!(
    sequence_de::AbstractArray{Float32}, pde::Float32,
    rng::AbstractRNG, λ_updn::Float64, μ_updn::Float64, λ_upde::Float64, μ_upde::Float64, N::Int)

    (ttf_updn,ttr_updn) = T(rng,λ_updn,μ_updn)
    (ttf_upde,ttr_upde) = T(rng,λ_upde,μ_upde)

    i=Int(1)

    if i + ttf_updn > N - ttf_updn && i + ttf_updn < N 
        ttr_updn = N - ttf_updn - i 
    end
    if i + ttf_upde > N - ttf_upde && i + ttf_upde < N 
        ttr_upde = N - ttf_upde - i 
    end

    ttf = min(ttf_updn, ttf_upde)
    ttr = min(ttr_updn, ttr_upde)
    derated_up = false
    derated_down = false

    while i + ttf + ttr  <= N

        ttf = min(ttf_updn, ttf_upde)
        ttr = min(ttr_updn, ttr_upde)

        if ttf==ttf_updn
            sequence_de[i+ttf+1 : i+ttf+ttr] = [0 for _ in i+ttf+1 : i+ttf+ttr]
        else
            derated_down = true
            sequence_de[i+ttf+1 : i+ttf+ttr] = [pde for _ in i+ttf+1 : i+ttf+ttr]
        end

        if ttr==ttr_upde
            derated_up = true
        else
            derated_up = false
        end


        i = i + ttf + ttr

        (ttf_updn,ttr_updn) = T(rng,λ_updn,μ_updn)
        (ttf_upde,ttr_upde) = T(rng,λ_upde,μ_upde)
        ttr = min(ttr_updn, ttr_upde)

        if i + ttr <= N && derated_up == true
            sequence_de[i+1 : i+ttr] = [pde for _ in i+1 : i+ttr]
            i = i + ttr
            (ttf_updn,ttr_updn) = T(rng,λ_updn,μ_updn)
            (ttf_upde,ttr_upde) = T(rng,λ_upde,μ_upde)
            ttr = min(ttr_updn, ttr_upde)
        end

        ttf = min(ttf_updn, ttf_upde)

        if i + ttf + ttr > N && i + ttf < N 
            ttr_updn = N - ttf - i
            ttr_upde = N - ttf - i
            ttr = N - ttf - i
        end

    end

    return

end

""
function cycles!(sequence::AbstractArray{Bool}, rng::AbstractRNG, λ_updn::Float64, μ_updn::Float64, N::Int)

    (ttf,ttr) = T(rng,λ_updn,μ_updn)
    i=Int(1)
    if i + ttf > N - ttr && i + ttf < N 
        ttr = N - ttf - i 
    end

    while i + ttf + ttr  <= N

        sequence[i+ttf+1 : i+ttf+ttr] = [false for _ in i+ttf+1 : i+ttf+ttr]

        i = i + ttf + ttr

        (ttf,ttr) = T(rng,λ_updn,μ_updn)

        if i + ttf + ttr > N && i + ttf < N 
            ttr = N - ttf - i 
        end

    end
    return

end

""
function T(rng, λ_updn::Float64, μ_updn::Float64)::Tuple{Int,Int}
    
    ttf = (x->trunc(Int, x)).((-1/λ_updn)log(rand(rng)))
    ttr = (y->trunc(Int, y)).((-1/μ_updn)log(rand(rng)))

    while ttf == 0.0 || ttr == 0.0
        ttf = (x->trunc(Int, x)).((-1/λ_updn)log(rand(rng)))
        ttr = (y->trunc(Int, y)).((-1/μ_updn)log(rand(rng)))
    end

    return ttf,ttr
end

""
function initialize_availability_system!(states::SystemStates, system::SystemModel, N::Int)

    for t in 1:N

        total_gen::Float32 = sum(field(system, :generators, :pmax).*field(states, :generators_de)[:,t])

        if all(view(field(states, :commonbranches),:,t)) == false
            for k in field(system, :branches, :keys)
                if field(system, :branches, :common_mode)[k] ≠ 0
                    if states.commonbranches[field(system, :branches, :common_mode)[k],t] == false
                        states.branches[k,t] = false
                    end
                end
            end
        end    

        if all(view(field(states, :branches),:,t)) == false
            states.system[t] = false
        else
            if sum(view(field(system, :loads, :pd), :, t)) >= total_gen
                states.system[t] = false
            elseif sum(view(field(states, :generators_de), :, t)) < length(system.generators)
                states.system[t] = false
            end
        end
    end

end

# ""
# function gens_sum(v_pmax::Vector{Float32}, active_keys::Vector{Int})
#     return sum(v_pmax[i] for i in active_keys)
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
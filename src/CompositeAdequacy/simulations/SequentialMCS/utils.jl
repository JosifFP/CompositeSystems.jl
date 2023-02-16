"initialize the availability of buses using an RNG and a system object of type SystemModel."
function initialize_availability!(availability::Matrix{Int}, asset::Buses, N::Int)
    
    bus_type = field(asset, :bus_type)
    for j in 1:N
        for i in eachindex(asset.keys)
            availability[i,j] = bus_type[i]
        end
    end
    return
end

"initialize the availability of different types of assets using an RNG and a system object of type SystemModel."
function initialize_availability!(rng::AbstractRNG, availabilities::Matrix{Bool}, nexttransition::Vector{Int}, asset::AbstractAssets, N::Int)

    availability = view(availabilities, :, 1)

    for i in asset.keys
        λ_updn = asset.λ_updn[i]/N
        μ_updn = asset.μ_updn[i]/N
        online = rand(rng) < μ_updn / (λ_updn + μ_updn)
        #online = true
        availability[i] = online
        transitionprobs = online ? asset.λ_updn./N  : asset.μ_updn./N
        nexttransition[i] = randtransitiontime(rng, transitionprobs, i, 1, N)
    end
    return availability
end

"initialize the availability of different types of assets (buses, branches, generators, etc.) using an RNG and a system object of type SystemModel."
function initialize_availability!(rng::AbstractRNG, availability::Vector{Bool}, nexttransition::Vector{Int}, asset::AbstractAssets, N::Int)
    
    for i in asset.keys
        λ_updn = asset.λ_updn[i]/N
        μ_updn = asset.μ_updn[i]/N
        online = rand(rng) < μ_updn / (λ_updn + μ_updn)
        #online = true
        availability[i] = online
        transitionprobs = online ? asset.λ_updn./N  : asset.μ_updn./N
        nexttransition[i] = randtransitiontime(rng, transitionprobs, i, 1, N)
    end
    return availability
end

""
function initialize_availability!(rng::AbstractRNG, availabilities::Matrix{Float32}, nexttransition::Vector{Int}, asset::Generators, N::Int)

    availability = view(availabilities, :, 1)

    for i in asset.keys
        λ_updn = asset.λ_updn[i]/N
        μ_updn = asset.μ_updn[i]/N
        #online = true

        if asset.state_model[i] == 2
            online = rand(rng) < μ_updn / (λ_updn + μ_updn)
            availability[i] = online
            transitionprobs = online ? asset.λ_updn./N  : asset.μ_updn./N
            nexttransition[i] = randtransitiontime(rng, transitionprobs, i, 1, N)

        elseif asset.state_model[i] == 3
            sequence = view(availability, i, :)
            fill!(sequence, 1)
            λ_upde = asset.λ_upde[i]/N
            μ_upde = asset.μ_upde[i]/N
            pde = asset.pde[i]
            if λ_updn ≠ 0.0 && λ_upde ≠ 0.0
                cycles!(sequence, pde, rng, λ_updn, μ_updn, λ_upde, μ_upde, N)
            end
        end
    end
    return availability
end

""
function update_availability!(rng::AbstractRNG, availabilitY::Vector{Bool}, nexttransition::Vector{Int}, asset::AbstractAssets, t_now::Int, t_last::Int)

    for i in asset.keys
        if nexttransition[i] == t_now # Unit switches states
            transitionprobs = (availabilitY[i] ⊻= true) ? asset.λ_updn./t_last : asset.μ_updn./t_last
            nexttransition[i] = randtransitiontime(rng, transitionprobs, i, t_now, t_last)
        end
    end
end

""
function update_availability!(rng::AbstractRNG, availabilities::Matrix{Bool}, nexttransition::Vector{Int}, asset::AbstractAssets, t_now::Int, t_last::Int)

    availability = view(availabilities, :, t_now)

    for i in asset.keys
        if nexttransition[i] == t_now # Unit switches states
            transitionprobs = (availability[i] ⊻= true) ? asset.λ_updn./t_last : asset.μ_updn./t_last
            nexttransition[i] = randtransitiontime(rng, transitionprobs, i, t_now, t_last)
        end
    end
end

""
function randtransitiontime(rng::AbstractRNG, p::Vector{Float64}, i::Int, t_now::Int, t_last::Int)

    cdf = 0.
    p_noprevtransition = 1.

    x = rand(rng)
    t = t_now + 1

    while t <= t_last
        cdf += p_noprevtransition * p[i]
        x < cdf && return t
        p_noprevtransition *= (1. - p[i])
        t += 1
    end

    return t_last + 1

end

""
function randtransitiontime(rng::AbstractRNG, p::Matrix{Float64}, i::Int, t_now::Int, t_last::Int)

    cdf = 0.
    p_noprevtransition = 1.

    x = rand(rng)
    t = t_now + 1

    while t <= t_last
        p_it = p[i,t]
        cdf += p_noprevtransition * p_it
        x < cdf && return t
        p_noprevtransition *= (1. - p_it)
        t += 1
    end

    return t_last + 1

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
function cycles!(sequence::AbstractArray{Float32}, rng::AbstractRNG, λ_updn::Float64, μ_updn::Float64, N::Int)

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

"This initialize_all_states! function is designed to initialize the states of all devices in the system using an RNG, 
a singlestates object of type NextTransition, and a system object of type SystemModel."
function initialize_all_states!(rng::AbstractRNG, states::SystemStates, singlestates::NextTransition, system::SystemModel{N}) where N
    initialize_availability!(rng, singlestates.branches_available, singlestates.branches_nexttransition, system.branches, N)
    initialize_availability!(rng, singlestates.commonbranches_available, singlestates.commonbranches_nexttransition, system.commonbranches, N)
    initialize_availability!(rng, singlestates.generators_available, singlestates.generators_nexttransition, system.generators, N)
    initialize_availability!(rng, singlestates.storages_available, singlestates.storages_nexttransition, system.storages, N)
    view(states.branches,:,1) .= singlestates.branches_available[:]
    view(states.shunts,:,1) .= singlestates.shunts_available[:]
    view(states.commonbranches,:,1) .= singlestates.commonbranches_available[:]
    view(states.generators,:,1) .= singlestates.generators_available[:]
    view(states.storages,:,1) .= singlestates.storages_available[:]
    view(states.generatorstorages,:,1) .= singlestates.generatorstorages_available[:]
    return
end

""
function update_all_states!(rng::AbstractRNG, states::SystemStates, singlestates::NextTransition, system::SystemModel{N}, t::Int) where N
    update_availability!(rng, singlestates.branches_available, singlestates.branches_nexttransition, field(system, :branches), t, N)
    update_availability!(rng, singlestates.commonbranches_available, singlestates.commonbranches_nexttransition, field(system, :commonbranches), t, N)
    update_availability!(rng, singlestates.generators_available, singlestates.generators_nexttransition, field(system, :generators), t, N)
    update_availability!(rng, singlestates.storages_available, singlestates.storages_nexttransition, field(system, :storages), t, N)
    view(states.branches,:,t) .= singlestates.branches_available[:]
    view(states.commonbranches,:,t) .= singlestates.commonbranches_available[:]
    view(states.generators,:,t) .= singlestates.generators_available[:]
    view(states.storages,:,t) .= singlestates.storages_available[:]
    view(states.generatorstorages,:,t) .= singlestates.generatorstorages_available[:]
    apply_common_outages!(states, system, t)
end

""
function apply_common_outages!(states::SystemStates, system::SystemModel, t::Int)
    if all(view(states.commonbranches,:,t)) == false
        for k in field(system, :branches, :keys)
            if field(system, :branches, :common_mode)[k] ≠ 0
                if states.commonbranches[field(system, :branches, :common_mode)[k],t] == false
                    states.branches[k,t] = false
                end
            end
        end
    end
end
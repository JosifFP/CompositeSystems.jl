
"This initialize_all_states! function is designed to initialize the states of all devices in the system using an RNG, 
a singlestates object of type NextTransition, and a system object of type SystemModel."
function initialize_all_states!(rng::AbstractRNG, states::SystemStates, singlestates::NextTransition, system::SystemModel{N}) where N
    initialize_availability!(rng, singlestates.branches_available, singlestates.branches_nexttransition, system.branches, N)
    initialize_availability!(rng, singlestates.commonbranches_available, singlestates.commonbranches_nexttransition, system.commonbranches, N)
    initialize_availability!(rng, singlestates.generators_available, singlestates.generators_nexttransition, system.generators, N)
    view(states.branches,:,1) .= singlestates.branches_available[:]
    view(states.commonbranches,:,1) .= singlestates.commonbranches_available[:]
    view(states.generators,:,1) .= singlestates.generators_available[:]
    return
end

"initialize the availability of different types of assets (buses, branches, generators, etc.) using an RNG and a system object of type SystemModel."
function initialize_availability!(rng::AbstractRNG, availability::Vector{Bool}, nexttransition::Vector{Int}, asset::AbstractAssets, N::Int)
    for i in 1:length(asset)
        λ_updn = asset.λ_updn[i]/N
        μ_updn = asset.μ_updn[i]/N
        online = false
        if λ_updn ≠ 0 && μ_updn ≠ 0
            # while !online
            #     online = rand(rng) < μ_updn / (λ_updn + μ_updn)
            # end
            online = rand(rng) < μ_updn / (λ_updn + μ_updn)
            availability[i] = online
            transitionprobs = online ? asset.λ_updn./N  : asset.μ_updn./N
            nexttransition[i] = randtransitiontime(rng, transitionprobs[i], 1, N)
        else
            availability[i] = true
            nexttransition[i] = N+1
        end
    end
    return availability
end

"initialize the availability of buses using an RNG and a system object of type SystemModel."
function initialize_availability!(availability::Matrix{Int}, asset::Buses, N::Int)
    bus_type = field(asset, :bus_type)
    for j in 1:N
        for i in 1:length(asset)
            availability[i,j] = bus_type[i]
        end
    end
    return
end

""
function update_availability!(rng::AbstractRNG, availability::Vector{Bool}, nexttransition::Vector{Int}, asset::AbstractAssets, t_now::Int, t_last::Int)
    for i in 1:length(asset)
        if nexttransition[i] == t_now # Unit switches states
            transitionprobs = (availability[i] ⊻= true) ? asset.λ_updn./t_last : asset.μ_updn./t_last
            nexttransition[i] = randtransitiontime(rng, transitionprobs[i], t_now, t_last)
        end
    end
end

""
function randtransitiontime(rng::AbstractRNG, p_it::Float64, t_now::Int, t_last::Int)

    cdf = 0.
    p_noprevtransition = 1.
    x = rand(rng)
    t = t_now + 1

    while t <= t_last
        cdf += p_noprevtransition * p_it
        x < cdf && return t
        p_noprevtransition *= (1. - p_it)
        t += 1
    end
    return t_last + 1
end

""
function update_all_states!(rng::AbstractRNG, states::SystemStates, singlestates::NextTransition, system::SystemModel{N}, t::Int) where N
    update_availability!(rng, singlestates.branches_available, singlestates.branches_nexttransition, field(system, :branches), t, N)
    update_availability!(rng, singlestates.commonbranches_available, singlestates.commonbranches_nexttransition, field(system, :commonbranches), t, N)
    update_availability!(rng, singlestates.generators_available, singlestates.generators_nexttransition, field(system, :generators), t, N)
    view(states.branches,:,t) .= singlestates.branches_available[:]
    view(states.commonbranches,:,t) .= singlestates.commonbranches_available[:]
    view(states.generators,:,t) .= singlestates.generators_available[:]
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
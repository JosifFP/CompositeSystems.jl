
"initialize the availability of different types of assets (buses, branches, generators, etc.) 
using an RNG and a system object of type SystemModel."
function initialize_availability!(rng::AbstractRNG, availability::Vector{Bool}, nexttransition::Vector{Int}, asset::AbstractAssets, N::Int)
    
    for i in 1:length(asset)
        λ_updn = asset.λ_updn[i]/N
        μ_updn = asset.μ_updn[i]/N
        online = rand(rng) < μ_updn / (λ_updn + μ_updn)
        availability[i] = online
        transitionprobs = online ? asset.λ_updn./N  : asset.μ_updn./N
        nexttransition[i] = randtransitiontime(rng, transitionprobs, i, 1, N)
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
    return availability
end

""
function apply_common_outages!(states::States, branches::Branches, t::Int)
    if !all(states.commonbranches_available)
        for k in eachindex(branches.keys)
            if branches.common_mode[k] ≠ 0 && states.commonbranches_available[branches.common_mode[k]] == false
                states.branches_available[k] = false
            end
        end
    end
end

"Update the availability of different types of assets (branches, generators, etc.) 
using availability and nexttransition vectors"
function update_availability!(
    rng::AbstractRNG, availability::Vector{Bool}, 
    nexttransition::Vector{Int}, asset::AbstractAssets, t_now::Int, t_last::Int)

    for i in 1:length(asset)
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
    p_it = p[i]

    while t <= t_last
        cdf += p_noprevtransition * p_it
        x < cdf && return t
        p_noprevtransition *= (1. - p_it)
        t += 1
    end

    return t_last + 1
end

""
function update_other_states!(states::States, statetransition::StateTransition, system::SystemModel)

    states.branches_available .= statetransition.branches_available
    states.commonbranches_available .= statetransition.commonbranches_available
    states.generators_available .= statetransition.generators_available
    states.storages_available .= statetransition.storages_available
    states.buses_available .= field(system, :buses, :bus_type)
    fill!(states.commonbranches_available, 1)
    fill!(states.loads_available, 1)
    fill!(states.shunts_available, 1)

    return
end

""
function record_other_states!(states::States, system::SystemModel)
    
    states.branches_pasttransition .= states.branches_available
    states.commonbranches_pasttransition .= states.commonbranches_available
    states.generators_pasttransition .= states.generators_available
    states.storages_pasttransition .= states.storages_available
    states.buses_pasttransition .= states.buses_available
    states.loads_pasttransition .= states.loads_available
    states.shunts_pasttransition .= states.shunts_available
    return
end
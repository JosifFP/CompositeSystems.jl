
"initialize the availability of different types of assets (buses, branches, generators, etc.) 
using an RNG and a system object of type SystemModel."
function initialize_availability!(
    rng::AbstractRNG, 
    availability::Vector{Bool}, 
    nexttransition::Vector{Int},
    asset::AbstractAssets, 
    N::Int)
    
    for i in 1:length(asset)
        λ = asset.λ_updn[i]
        μ = asset.μ_updn[i]
        online = rand(rng) < μ / (λ + μ)
        availability[i] = online
        transitionprobs = online ? asset.λ_updn  : asset.μ_updn
        nexttransition[i] = randtransitiontime(rng, transitionprobs, i, 1, N)
    end
    return availability
end

"Update the availability of different types of assets (branches, generators, etc.) 
using availability and nexttransition vectors"
function update_availability!(
    rng::AbstractRNG, availability::Vector{Bool},
    nexttransition::Vector{Int}, asset::AbstractAssets, t_now::Int, t_last::Int)

    for i in 1:length(asset)
        if nexttransition[i] == t_now # Unit switches states
            transitionprobs = (availability[i] ⊻= true) ? asset.λ_updn : asset.μ_updn
            nexttransition[i] = randtransitiontime(rng, transitionprobs, i, t_now, t_last)
        end
    end
end

""
function randtransitiontime(rng::AbstractRNG, p::Vector{Float64}, i::Int, t_now::Int, t_last::Int; tol = 1e-6)

    cdf = 0.0
    p_noprevtransition = 1.0
    p_it = p[i]
    t = t_now + 1
    x = rand(rng)

    while t <= t_last
        cdf += p_noprevtransition * p_it
        x < cdf + tol && return t
        p_noprevtransition *= (1.0 - p_it)
        t += 1
    end

    return t_last + 1
end

""
function apply_common_outages!(topology::Topology, branches::Branches, t::Int)
    if !all(topology.commonbranches_available)
        for k in eachindex(branches.keys)
            if branches.common_mode[k] ≠ 0 && topology.commonbranches_available[branches.common_mode[k]] == false
                topology.branches_available[k] = false
            end
        end
    end
end
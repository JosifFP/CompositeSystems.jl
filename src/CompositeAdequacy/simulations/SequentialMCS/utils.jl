
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


"""
    randtransitiontime(rng::AbstractRNG, p::Vector{Float64}, i::Int, t_now::Int, t_last::Int; tol = 1e-9)

Generate a random transition time based on the probability distribution `p`.

# Arguments
- `rng::AbstractRNG`: The random number generator.
- `p::Vector{Float64}`: A vector of transition probabilities.
- `i::Int`: The index for the current state in the probability vector `p`.
- `t_now::Int`: The current time.
- `t_last::Int`: The last time step.
- `tol::Float64`: A small tolerance value used for numerical comparisons. Default is `1e-9`.

# Returns
The function returns a random time of transition, based on the provided transition probabilities. 
If no transition occurs until `t_last`, it returns `t_last + 1`.

# Description
The function models the random time at which a state transitions to another state.
It starts from the current time `t_now` and iteratively checks if a transition 
occurs based on the probabilities provided. If a transition occurs, it returns that time.
Otherwise, it increments the time and checks again until `t_last` is reached.

"""
function randtransitiontime(rng::AbstractRNG, p::Vector{Float64}, i::Int, t_now::Int, t_last::Int; tol = 1e-9)

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
# THIS FUNCTION MUST BE FIXED
function apply_common_outages!(topology::Topology, branches::Branches, t::Int)
    if !all(topology.interfaces_available)
        for k in eachindex(branches.keys)
            if branches.common_mode[k] ≠ 0 && topology.interfaces_available[branches.common_mode[k]] == false
                topology.branches_available[k] = false
            end
        end
    end
end
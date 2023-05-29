
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

"Empty or Initialize other variables"
function initialize_other_states!(states::ComponentStates)

    fill!(states.loads, 1)
    fill!(states.shunts, 1)
    fill!(states.stored_energy, 0)
    fill!(states.p_curtailed, 0)
    fill!(states.flow_from, 0)
    fill!(states.flow_to, 0)
end

"Update the availability of different types of assets (buses, branches, generators, etc.) 
using availability and nexttransition vectors"
function update_availability!(rng::AbstractRNG, updown_cycle::Matrix{Bool},
    availability::Vector{Bool}, nexttransition::Vector{Int}, asset::AbstractAssets, t_now::Int, t_last::Int)

    for i in 1:length(asset)

        if nexttransition[i] == t_now # Unit switches states
            transitionprobs = (availability[i] ⊻= true) ? asset.λ_updn./t_last : asset.μ_updn./t_last
            nexttransition[i] = randtransitiontime(rng, transitionprobs, i, t_now, t_last)
        end

        view(updown_cycle,i,t_now) .= availability[i]
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
function apply_common_outages!(states::ComponentStates, branches::Branches, t::Int)
    if all(view(states.commonbranches,:,t)) == false
        for k in branches.keys
            if branches.common_mode[k] ≠ 0 && states.commonbranches[branches.common_mode[k],t] == false
                states.branches[k,t] = false
            end
        end
    end
end

""
function peakload(loads::Loads{N}, buses::Buses) where {N}
    
    key_buses = field(buses, :keys)
    bus_loads_init = Dict{Int, Vector{Float64}}((i, Float64[]) for i in key_buses)
    
    for k in field(loads, :keys)
        push!(bus_loads_init[field(loads, :buses)[k]], maximum(loads.pd[k,:]))
    end

    bus_peakload = Array{Float64}(undef, length(buses))

    for (k,v) in bus_loads_init
        if !isempty(v)
            bus_peakload[k] = sum(v)
        else
            bus_peakload[k] = 0.0
        end
    end

    system_peakload = Float64(maximum(sum(loads.pd, dims=1)))
    return system_peakload, bus_peakload
end
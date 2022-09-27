function initialize_availability!(
    rng::AbstractRNG,
    availability::Matrix{Bool},
    devices::AbstractAssets, N::Int)
    
    ndevices = Base.length(devices)

    for i in 1:ndevices
        λ = devices.λ[i]/N
        μ = devices.μ[i]/N
        if λ ≠ 0.0 || μ ≠ 0.0
            availability[i,:] = cycles!(rng, λ, μ, N)
        end
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

""
function update_load!(loads::Loads, ref_load::Dict{Int,<:Any}, t::Int)

    tmp = Dict{Int,Any}()
    for i in eachindex(loads.keys)
        #dictionary[:load][i]["qd"] = Float16.(system.loads.pd[i,t]*Float32.(dictionary[:load][i]["qd"] / dictionary[:load][i]["pd"]))
        ref_load[i]["pd"] = loads.pd[i,t]*2
        get!(tmp, i, ref_load[i]["pd"])
    end
    return tmp
end

""
function update_gen!(generators::Generators, ref_gen::Dict{Int,<:Any}, gens_available::Matrix{Bool}, t::Int)
    for i in eachindex(generators.keys)
        ref_gen[i]["pg"] = generators.pg[i,t]
        if gens_available[i] == false ref_gen[i]["gen_status"] = gens_available[i,t] end
    end
    return ref_gen
end

""
function update_stor!(storages::Storages, ref_stor::Dict{Int,<:Any}, stors_available::Matrix{Bool}, t::Int)
    for i in eachindex(storages.keys)
        if stors_available[i] == false ref_stor[i]["status"] = stors_available[i,t] end
    end
    return ref_stor
end

""
function update_branches!(branches::Branches, ref_branch::Dict{Int,<:Any}, branches_available::Matrix{Bool}, t::Int)
    if all(branches_available[:,t]) == false
        for i in eachindex(branches.keys)
            if branches_available[i] == false ref_branch[i]["br_status"] = branches_available[i,t] end
        end
    end
    return ref_branch
end

# ""
# function overloadings(newdata::Dict{String,Any})

#     container = false
#     for j in eachindex(newdata["branch"])
#         if any(abs(newdata["branch"][string(j)]["pf"]) > newdata["branch"][string(j)]["rate_a"])
#             container = true
#             break
#         end
#     end

#     return container

# end

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
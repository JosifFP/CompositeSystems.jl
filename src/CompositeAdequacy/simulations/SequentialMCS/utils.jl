""
function initialize_availability!(
    states::SystemStates,
    system::Vector{Bool}, 
    N::Int)

    v = vcat(field(states, :branches), field(states, :generators),  field(states, :storages), field(states, :generatorstorages)
)

    @inbounds for t in 1:N
        if check_status(field(v, t)) == FAILED
            system[t] = false
        else
            system[t] = true
        end
    end
end

""
function initialize_availability!(
    rng::AbstractRNG,
    availability::Matrix{Bool},
    asset::AbstractAssets, N::Int)
    
    ndevices = Base.length(asset)

    for i in 1:ndevices
        if field(asset, :status) ≠ false
            λ = asset.λ[i]/N
            μ = asset.μ[i]/N
            if λ ≠ 0.0 || μ ≠ 0.0
                availability[i,:] = cycles!(rng, λ, μ, N)
            end
        end
    end

    return availability
    
end

function cycles!(
    rng::AbstractRNG, λ::Float64, μ::Float64, N::Int)

    sequence = Base.ones(true, N)
    i=Int(1)
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

function T(rng, λ::Float64, μ::Float64)::Tuple{Int,Int}
    
    ttf = (x->trunc(Int, x)).((-1/λ)log(rand(rng)))
    ttr = (y->trunc(Int, y)).((-1/μ)log(rand(rng)))

    while ttf == 0.0
        ttf = (x->trunc(Int, x)).((-1/λ)log(rand(rng)))
        ttr = (y->trunc(Int, y)).((-1/μ)log(rand(rng)))
    end

    return ttf,ttr
end

"Update asset_idxs and asset_loads"
function update_idxs!(
    key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}}, bus_assets::Dict{Int, Vector{Int}}, buses::Vector{Int})
    
    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
    map!(x -> Int[], bus_assets)
    update_asset_nodes!(key_assets, bus_assets, buses)

end

""
function update_asset_nodes!(key_assets::Vector{Int}, bus_assets::Dict{Int, Vector{Int}}, buses::Vector{Int})
    @inbounds for k in key_assets
        push!(bus_assets[buses[k]], k)
    end
end

""
function update_branch_idxs!(branches::Branches, assets_idxs::Vector{UnitRange{Int}}, updated_arcs::Arcs, arcs::Arcs, asset_states::Matrix{Bool}, t)

    assets_idxs .= makeidxlist(filter(i->field(asset_states, t)[i], field(branches, :keys)), length(assets_idxs))
    update_arcs_nodes!(updated_arcs, arcs, field(asset_states, t))
    
end

function update_arcs_nodes!(Actual::Arcs, Initial::Arcs, v::SubArray)

    @inbounds for i in eachindex(v)
        if !v[i]
            @inbounds view(field(Actual, :busarcs),:,i) .= field(Actual, :empty)
            @inbounds view(field(Actual, :arcs_from),i) .= missing
            @inbounds view(field(Actual, :arcs_to),i) .= missing
            @inbounds view(field(Actual, :arcs),i) .= missing
        else
            @inbounds view(field(Actual, :busarcs),:,i) .= view(field(Initial, :busarcs),:,i)
            @inbounds view(field(Actual, :arcs_from),i) .= view(field(Initial, :arcs_from),i)
            @inbounds view(field(Actual, :arcs_to),i) .= view(field(Initial, :arcs_to),i)
            @inbounds view(field(Actual, :arcs),i) .= view(field(Initial, :arcs),i)
        end
    end

end

# idxs(topology::Topology, ::Loads) = field(topology, :loads_idxs)
# idxs(topology::Topology, ::Shunts) = field(topology, :shunts_idxs)
# idxs(topology::Topology, ::Generators) = field(topology, :generators_idxs)
# idxs(topology::Topology, ::Storages) = field(topology, :storages_idxs)
# idxs(topology::Topology, ::GeneratorStorages) = field(topology, :generatorstorages_idxs)
# bus_idxs(topology::Topology, ::Loads) = field(topology, :loads_nodes)
# bus_idxs(topology::Topology, ::Shunts) = field(topology, :generators_nodes)
# bus_idxs(topology::Topology, ::Generators) = field(topology, :generators_nodes)
# bus_idxs(topology::Topology, ::Storages) = field(topology, :storages_nodes)
# bus_idxs(topology::Topology, ::GeneratorStorages) = field(topology, :generatorstorages_nodes)

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
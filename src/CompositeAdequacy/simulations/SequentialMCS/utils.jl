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

""
function update!(system::SystemModel{N}) where {N}

    for k in field(system, Branches, :keys)
        if field(system, Branches, :status)[k] ≠ 0
            f_bus = field(system, Branches, :f_bus)[k]
            t_bus = field(system, Branches, :t_bus)[k]
            if field(system, Buses, :bus_type)[f_bus] == 4 || field(system, Buses, :bus_type)[t_bus] == 4
                #@info("deactivating branch $(k):($(f_bus),$(t_bus)) due to connecting bus status")
                field(system, Branches, :status)[k] = 0
            end
        end
    end
    
    for k in field(system, Buses, :keys)
        if field(system, Buses, :bus_type)[k] == 4
            if field(system, Loads, :status)[k] ≠ 0 field(system, Loads, :status)[k] = 0 end
            if field(system, Shunts, :status)[k] ≠ 0 field(system, Shunts, :status)[k] = 0 end
            if field(system, Generators, :status)[k] ≠ 0 field(system, Generators, :status)[k] = 0 end
            if field(system, Storages, :status)[k] ≠ 0 field(system, Storages, :status)[k] = 0 end
            if field(system, GeneratorStorages, :status)[k] ≠ 0 field(system, GeneratorStorages, :status)[k] = 0 end
        end
    end

    #tmp_arcs_from = [(l,i,j) for (l,i,j) in field(system, Topology, :arcs_from) if field(system, Branches, :status)[l] ≠ 0]
    #tmp_arcs_to   = [(l,i,j) for (l,i,j) in field(system, Topology, :arcs_to) if field(system, Branches, :status)[l] ≠ 0]
    #tmp_arcs = [(l,i,j) for (l,i,j) in field(system, Topology, :arcs) if field(system, Branches, :status)[l] ≠ 0]

end

"Update Asset statess"
function update_states!(system::SystemModel, states::SystemStates, t::Int)

    field(system, Loads, :status)[:] = field(states, :loads, t)
    field(system, Branches, :status)[:] = field(states, :branches, t)
    field(system, Shunts, :status)[:] = field(states, :shunts, t)
    field(system, Generators, :status)[:] = field(states, :generators, t)
    field(system, Storages, :status)[:] = field(states, :storages, t)
    field(system, GeneratorStorages, :status)[:] = field(states, :generatorstorages, t)

end


"Do nothing"
function update_asset_idxs!(topology::Topology, asset::AbstractAssets, asset_states::SubArray, 
    key_buses::Vector{Int}, t::Int, ::Type{SUCCESSFUL})
end

"Update loads_idxs and bus_loads"
function update_asset_idxs!(topology::Topology, asset::Loads, asset_states::SubArray, 
    key_buses::Vector{Int}, t::Int, ::Type{FAILED})
    
    key_assets = [i for i in field(asset, :keys) if asset_states[i] == 1]
    field(topology, :loads_idxs)[:] = makeidxlist(key_assets, length(asset))
    update_bus_assets!(field(topology, :bus_loads), field(asset, :buses), key_buses, key_assets)

end

"Update shunts_idxs and bus_shunts"
function update_asset_idxs!(topology::Topology, asset::Shunts, asset_states::SubArray, 
    key_buses::Vector{Int}, t::Int, ::Type{FAILED})
    
    key_assets = [i for i in field(asset, :keys) if asset_states[i] == 1]
    field(topology, :shunts_idxs)[:] = makeidxlist(key_assets, length(asset))
    update_bus_assets!(field(topology, :bus_shunts), field(asset, :buses), key_buses, key_assets)

end

"Update generators_idxs and bus_generators"
function update_asset_idxs!(topology::Topology, asset::Generators, asset_states::SubArray, 
    key_buses::Vector{Int}, t::Int, ::Type{FAILED})
    
    key_assets = [i for i in field(asset, :keys) if asset_states[i] == 1]
    field(topology, :generators_idxs)[:] = makeidxlist(key_assets, length(asset))
    update_bus_assets!(field(topology, :bus_generators), field(asset, :buses), key_buses, key_assets)

end

"Update storages_idxs and bus_storages"
function update_asset_idxs!(topology::Topology, asset::Storages, asset_states::SubArray, 
    key_buses::Vector{Int}, t::Int, ::Type{FAILED})
    
    key_assets = [i for i in field(asset, :keys) if asset_states[i] == 1]
    field(topology, :storages_idxs)[:] = makeidxlist(key_assets, length(asset))
    update_bus_assets!(field(topology, :bus_storages), field(asset, :buses), key_buses, key_assets)

end

"Update generatorstorages_idxs and bus_generatorstorages"
function update_asset_idxs!(topology::Topology, asset::GeneratorStorages, asset_states::SubArray, 
    key_buses::Vector{Int}, t::Int, ::Type{FAILED})
    
    key_assets = [i for i in field(asset, :keys) if asset_states[i] == 1]
    field(topology, :generatorstorages_idxs)[:] = makeidxlist(key_assets, length(asset))
    update_bus_assets!(field(topology, :bus_generatorstorages), field(asset, :buses), key_buses, key_assets)

end

""
function update_bus_assets!(bus_assets::Dict{Int, Vector{Int}}, buses::Vector{Int}, 
    key_buses::Vector{Int}, key_assets::Vector{Int})

    for v=values(bus_assets) empty!(v) end
    
    for k in key_assets
        push!(bus_assets[buses[k]], k)
    end
end

""
function update_bus_assets!(
    bus_arcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}, arcs::Vector{Tuple{Int, Int, Int}}, key_buses::Vector{Int}, branch_states::Vector{Bool})

    for i in key_buses
        bus_arcs[i] = Tuple{Int,Int,Int}[]
    end
    
    for (l,i,j) in arcs
        if branch_states[l] ≠ 0
            push!(bus_arcs[i], (l,i,j))
        end
    end
end

"Do nothing"
function update_branch_idxs!(topology::Topology, system::SystemModel, asset_states::SubArray, key_buses::Vector{Int}, t::Int, ::Type{SUCCESSFUL})
end

""
function update_branch_idxs!(topology::Topology, system::SystemModel, asset_states::SubArray, key_buses::Vector{Int}, t::Int, ::Type{FAILED})

    branches = field(system, :branches)

    key_branches = [i for i in field(branches, :keys) if asset_states[i] == 1]

    field(topology, :branches_idxs)[:] = makeidxlist(key_branches, length(branches))

    update_bus_assets!(field(topology, :bus_arcs), field(system, :arcs), key_buses, asset_states)

    tmp_buspairs = calc_buspair_parameters(field(system, :buses), branches, key_branches)
            
    for (k,_) in field(topology, :buspairs)
        if haskey(tmp_buspairs, k) ≠ true
            empty!(field(topology, :buspairs)[k])
        else
            field(topology, :buspairs)[k] = tmp_buspairs[k]
        end
    end
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
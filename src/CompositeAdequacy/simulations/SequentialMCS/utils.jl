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

""
function initialize_availability!(states::SystemStates, N::Int)

    v = vcat(field(states, :branches), field(states, :generators), field(states, :loads))

    @inbounds for t in 1:N
        B = filter(i -> states.buses[i]==4, states.buses)
        if check_status(view(v, :, t)) == false ||  length(B) > 0
            states.system[t] = false
        end
    end
end


""
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

"Update asset_idxs and asset_nodes"
function update_idxs!(key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}}, bus_assets::Dict{Int, Vector{Int}}, buses::Vector{Int})
    
    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))
    map!(x -> Int[], bus_assets)
    update_asset_nodes!(key_assets, bus_assets, buses)

end

""
function update_idxs!(key_assets::Vector{Int}, assets_idxs::Vector{UnitRange{Int}})
    
    assets_idxs .= makeidxlist(key_assets, length(assets_idxs))

end

""
function update_asset_nodes!(key_assets::Vector{Int}, bus_assets::Dict{Int, Vector{Int}}, buses::Vector{Int})
    @inbounds for k in key_assets
        push!(bus_assets[buses[k]], k)
    end
end

""
function update_branch_idxs!(branches::Branches, assets_idxs::Vector{UnitRange{Int}}, topology_arcs::Arcs, initial_arcs::Arcs, asset_states::Matrix{Bool}, t::Int)
    assets_idxs .= makeidxlist(filter(i->asset_states[i,t]==1, field(branches, :keys)), length(assets_idxs))
    update_arcs!(branches, topology_arcs, initial_arcs, asset_states, t)
end

""
function update_arcs!(branches::Branches, topology_arcs::Arcs, initial_arcs::Arcs, asset_states::Matrix{Bool}, t::Int)
    
    state = asset_states[:,t]
    @inbounds for i in eachindex(state)

        f_bus = field(branches, :f_bus)[i]
        t_bus = field(branches, :t_bus)[i]

        if !state[i]
            field(topology_arcs, :busarcs)[:,i] = deepcopy(field(topology_arcs, :empty))
            field(topology_arcs, :arcs_from)[i] = missing
            #field(topology_arcs, :arcs_to)[i] = missing
            field(topology_arcs, :buspairs)[(f_bus, t_bus)] = missing
        else
            field(topology_arcs, :busarcs)[:,i] = deepcopy(view(field(initial_arcs, :busarcs),:,i))
            field(topology_arcs, :arcs_from)[i] = deepcopy(view(field(initial_arcs, :arcs_from),i)[1])
            #field(topology_arcs, :arcs_to)[i] = deepcopy(view(field(initial_arcs, :arcs_to),i)[1])
            field(topology_arcs, :buspairs)[(f_bus, t_bus)] = deepcopy(field(initial_arcs, :buspairs)[(f_bus, t_bus)])
        end
    end
    
    #field(topology_arcs, :arcs)[:] = [field(topology_arcs, :arcs_from); field(topology_arcs, :arcs_to)]

end


function initialize_bus_types(buses_states::Matrix{Int}, branches_states::Matrix{Bool}, branches::Branches, settings::Settings, N::Int)

    for t in 1:N

        pm_data = PowerModels.parse_file(field(settings, :file))
        branch_states = branches_states[:,t]
        bus_types = buses_states[:,t]

        for i in branches.keys
            if !branch_states[i]
                pm_data["branch"][string(i)]["br_status"] = 0
            end
        end

        PowerModels.simplify_network!(pm_data)
        PowerModels.select_largest_component!(pm_data)
        PowerModels.simplify_network!(pm_data)

        for (k,v) in pm_data["bus"]
            i = parse(Int, k)
            bus_types[i] = Int(v["bus_type"])
        end

        for (k,v) in pm_data["branch"]
            i = parse(Int, k)
            branch_states[i] = Bool(v["br_status"])
        end


    end

    return buses_states, branches_states

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
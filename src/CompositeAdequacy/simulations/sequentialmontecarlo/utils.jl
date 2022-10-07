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
                Memento.info(_LOGGER, "deactivating branch $(k):($(f_bus),$(t_bus)) due to connecting bus status")
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

"Update Asset states"
function update_states!(system::SystemModel, state::SystemState, t::Int)

    field(system, Loads, :status)[:] = field(state, :loads)[:,t]
    field(system, Branches, :status)[:] = field(state, :branches)[:,t]
    field(system, Shunts, :status)[:] = field(state, :shunts)[:,t]
    field(system, Generators, :status)[:] = field(state, :generators)[:,t]
    field(system, Storages, :status)[:] = field(state, :storages)[:,t]
    field(system, GeneratorStorages, :status)[:] = field(state, :generatorstorages)[:,t]

end

""
function update_asset_idxs!(asset::AbstractAssets, asset_idxs::Vector{UnitRange{Int}}, bus_asset_idxs::Vector{UnitRange{Int}}, asset_states::Vector{Bool}, nbuses::Int)

    if all(asset_states) ≠ true && isempty(asset_idxs) ≠ true

        key_assets = [i for i in assetgrouplist(asset_idxs) if asset_states[i] ≠ 0]
        asset_idxs[:] = makeidxlist(key_assets, length(asset))
        bus_asset_idxs[:] = makeidxlist([field(asset, :buses)[i] for i in key_assets], nbuses)

    end

end

""
function update_branch_idxs!(
    topology::Topology, branches::Branches, buses::Buses, branches_idxs::Vector{UnitRange{Int}}, 
    buses_idxs::Vector{UnitRange{Int}}, branch_states::Vector{Bool}, arcs::Vector{Tuple{Int, Int, Int}})

    if all(branch_states) ≠ true && isempty(branches_idxs) ≠ true

        key_buses = [i for i in assetgrouplist(buses_idxs) if field(buses, :bus_type)[i] ≠ 4]
        key_branches = [i for i in assetgrouplist(branches_idxs) if branch_states[i] ≠ 0]
        branches_idxs[:] = makeidxlist(key_branches, length(branches))

        for i in  key_buses
            field(topology, :bus_arcs)[i] = Tuple{Int,Int,Int}[]
        end
        
        for (l,i,j) in arcs
            if branch_states[l] ≠ 0
                push!(field(topology, :bus_arcs)[i], (l,i,j))
            end
        end
        
        tmp_buspairs = calc_buspair_parameters(buses, branches, key_branches)
        
        for (k,_) in field(topology, :buspairs)
            if haskey(tmp_buspairs, k) ≠ true
                empty!(field(topology, :buspairs)[k])
            else
                field(topology, :buspairs)[k] = tmp_buspairs[k]
            end
        end

    end

end


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
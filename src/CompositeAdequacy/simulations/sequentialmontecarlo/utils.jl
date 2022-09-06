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

"Add load curtailment information to data"
function add_load_curtailment_info!(network::Network)
    for i in eachindex(network.load)
        push!(network.load[string(i)], "cost" => float(1000))
    end
end

""
function apply_contingencies!(network_data::Dict{String,Any}, state::SystemState, system::SystemModel{N}, t::Int) where {N}

    if state.condition[t] == false

        for i in eachindex(system.branches.keys)
            if state.branches_available[i] == false network_data["branch"][string(i)]["br_status"] = state.branches_available[i,t] end
        end
        for i in eachindex(system.generators.keys)
            if state.gens_available[i] == false network_data["gen"][string(i)]["gen_status"] = state.gens_available[i,t] end
        end
        for i in eachindex(system.storages.keys)
            if state.stors_available[i] == false network_data["storage"][string(i)]["status"] = state.stors_available[i,t] end
        end

        network_data["branch"][string(7)]["br_status"] = 0
        network_data["branch"][string(23)]["br_status"] = 0
        network_data["branch"][string(29)]["br_status"] = 0
        PRATSBase.SimplifyNetwork!(network_data)
        return DCMLPowerModel
    
    else

        overloaded_lines = overloadings(compute_dc_pf(network_data))
        if overloaded_lines == false
            return DCSPowerModel
        else
            return DCPPowerModel
        end

    end

end

""
function update_condition!(state::SystemState, N::Int)
    for t in 1:N
        if any(i->(i==0), [state.gens_available[:,t];state.stors_available[:,t]; state.genstors_available[:,t]; state.branches_available[:,t]]) == true
            state.condition[t] = false
        end
    end
end

function SolveModel(data::Dict{String,<:Any}, model_type::Type{DCSPowerModel}, optimizer)

    pm = model_type(nothing, data, Dict{String,Any}(), nothing)
    push!(pm.solution, 
    "termination_status"    => "No optimizer used",  
    "optimizer"             => "No optimizer used",
    "solution"              => Dict{String,Any}()
    )

    build_solution!(pm)
    return pm

end

""
function SolveModel(data::Dict{String,<:Any}, model_type::Type{DCPPowerModel}, optimizer)

    pm =  InitializeAbstractPowerModel(data, model_type, optimizer)
    build_model!(pm)
    optimization!(pm)
    build_result!(pm)
    return pm
    
end

""
function SolveModel(data::Dict{String,<:Any}, model_type::Type{DCMLPowerModel}, optimizer)

    pm =  InitializeAbstractPowerModel(data, model_type, optimizer)
    build_model!(pm)
    optimization!(pm)

    if JuMP.termination_status(pm.model) ≠ JuMP.LOCALLY_SOLVED
        pm = nothing
        pm = Type{DCSPowerModel}(nothing, data, Dict{String,Any}(), nothing)
        push!(pm.solution, 
        "termination_status"    => "No optimizer used",  
        "optimizer"             => "No optimizer used",
        "solution"              => Dict{String,Any}()
        )
    
        build_solution!(pm)
    else
        build_result!(pm)
    end

    return pm
    
end

function update_systemmodel!(pm::AbstractPowerModel, system::SystemModel, t::Int)

    for i in eachindex(pm.solution["solution"]["branch"])
        system.branches.pf[i,t] = Float16.(pm.solution["solution"]["branch"][i]["pf"])
        system.branches.pt[i,t] = Float16.(pm.solution["solution"]["branch"][i]["pt"])
    end
    
    for i in eachindex(pm.solution["solution"]["gen"])
         system.generators.pg[i,t] = Float16.(pm.solution["solution"]["gen"][string(i)]["pg"])
    end

    return

end

function overloadings(newdata::Dict{String,Any})

    container = false
    for j in eachindex(newdata["branch"])
        if any(abs(newdata["branch"][string(j)]["pf"]) > newdata["branch"][string(j)]["rate_a"])
            container = true
            break
        end
    end

    return container

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
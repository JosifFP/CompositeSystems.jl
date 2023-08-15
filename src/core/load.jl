"""
    SystemModel(rawfile::String)

Load a `SystemModel` using a specified `rawfile`. 
This constructor parses the raw network data and associates static parameters with it.

Arguments:
- `rawfile`: Path to the raw network data file.
"""
function SystemModel(rawfile::String)
    #load network data
    network = build_network(rawfile)
    SParametrics = static_parameters{1,1,Hour}(Dates.now(), "UTC")
    get!(network, :timeseries_load, "")
    return _SystemModel(network, SParametrics)
end



"""
    SystemModel(rawfile::String, reliabilityfile::String)

Load a `SystemModel` using a `rawfile` and incorporate reliability data from `reliabilityfile`.

Arguments:
- `rawfile`: Path to the raw network data file.
- `reliabilityfile`: Path to the reliability data file.
"""
function SystemModel(rawfile::String, reliabilityfile::String)
    #load network data
    network = build_network(rawfile)
    reliability_data = extract_reliability_data(reliabilityfile)
    SParametrics = static_parameters{1,1,Hour}(Dates.now(), "UTC")
    merge_compositesystems_data!(network, reliability_data)
    return _SystemModel(network, SParametrics)
end



"""
    SystemModel(rawfile::String, reliabilityfile::String, timeseriesfile::String)

Load a `SystemModel` using a `rawfile`, `reliabilityfile`, and load time-series data from `timeseriesfile`.

Arguments:
- `rawfile`: Path to the raw network data file.
- `reliabilityfile`: Path to the reliability data file.
- `timeseriesfile`: Path to the time-series data file.
"""
function SystemModel(rawfile::String, reliabilityfile::String, timeseriesfile::String)
    #load network data
    network = build_network(rawfile)
    reliability_data = extract_reliability_data(reliabilityfile)
    timeseries_data, SParametrics = extract_timeseriesload(timeseriesfile)
    merge_compositesystems_data!(network, reliability_data, timeseries_data)
    return _SystemModel(network, SParametrics)
end



"""
    SystemModel(rawfile::String, reliabilityfile::String, timeseries_data::Dict{Int, Vector{Float32}}, SParametrics::static_parameters{N,L,T})

Load a `SystemModel` using a `rawfile`, `reliabilityfile`, and directly provide `timeseries_data` and `SParametrics`.

Arguments:
- `rawfile`: Path to the raw network data file.
- `reliabilityfile`: Path to the reliability data file.
- `timeseries_data`: Time-series data provided as a dictionary.
- `SParametrics`: Static parameters for the model.
"""
function SystemModel(
    rawfile::String, reliabilityfile::String, timeseries_data::Dict{Int, Vector{Float32}}, 
    SParametrics::static_parameters{N,L,T}
    ) where {N,L,T<:Period}

    #load network data
    network = build_network(rawfile)
    reliability_data = extract_reliability_data(reliabilityfile)
    merge_compositesystems_data!(network, reliability_data, timeseries_data)
    return _SystemModel(network, SParametrics)
end

""
function fetch_component(network::Dict{Symbol, Any}, key::Symbol, default::Any)
    return get(network, key, default)
end



"""
    _SystemModel(network::Dict{Symbol, Any}, SParametrics::static_parameters{N,L,T})

Helper function to build a `SystemModel` using preprocessed `network` data and `SParametrics`.

Arguments:
- `network`: Processed network data in dictionary format.
- `SParametrics`: Static parameters for the model.
"""
function _SystemModel(
    network::Dict{Symbol, Any}, SParametrics::static_parameters{N,L,T}) where {N,L,T<:Period}

    # Fetch all components
    baseMVA =  Float64(fetch_component(network, :baseMVA, Float64))
    network_bus = fetch_component(network, :bus, Dict{Int, Any}())
    network_branch = fetch_component(network, :branch, Dict{Int, Any}())
    network_commonbranch = fetch_component(network, :commonbranch, Dict{Int, Any}())
    network_shunt = fetch_component(network, :shunt, Dict{Int, Any}())
    network_gen = fetch_component(network, :gen, Dict{Int, Any}())
    network_load = fetch_component(network, :load, Dict{Int, Any}())
    network_storage = fetch_component(network, :storage, Dict{Int, Any}())
    
    if !isempty(network_bus)
        data = container(network_bus, bus_fields)
        buses = Buses(
            data["index"], 
            data["zone"], 
            data["bus_type"],
            data["bus_i"], 
            data["vmax"], 
            data["vmin"],
            data["base_kv"], 
            data["va"], 
            data["vm"]
        )
    end

    if !isempty(network_branch)
        data = container(network_branch, branch_fields)
        branches = Branches(
            data["index"], 
            data["f_bus"], 
            data["t_bus"],
            data["common_mode"],
            data["rate_a"], 
            data["rate_b"], 
            data["br_r"], 
            data["br_x"],
            data["b_fr"], 
            data["b_to"],
            data["g_fr"], 
            data["g_to"],
            data["shift"], 
            data["angmin"],
            data["angmax"], 
            data["transformer"],
            data["tap"],
            data["λ_updn"], 
            data["μ_updn"],
            data["br_status"]
        )
    end

    if !isempty(network_shunt)
        data = container(network_shunt, shunt_fields)
        shunts = Shunts(
            data["index"], 
            data["shunt_bus"], 
            data["bs"],
            data["gs"], 
            data["status"]
        )
    else
        shunts = Shunts(Int[], Int[], Float32[], Float32[], Vector{Bool}())
    end

    if !isempty(network_commonbranch)
        data = container(network_commonbranch, commonbranch_fields)
        commonbranches = CommonBranches(
            data["index"], 
            data["f_bus"], 
            data["t_bus"], 
            data["λ_updn"], 
            data["μ_updn"]
        )
    else
        commonbranches = CommonBranches(Int[], Int[], Int[], Float64[], Float64[])
    end

    if !isempty(network_gen)
        data = container(network_gen, gen_fields)
        generators = Generators{N,L,T}(
            data["index"], 
            data["gen_bus"], 
            data["pg"], 
            data["qg"], 
            data["vg"], 
            data["pmax"], 
            data["pmin"], 
            data["qmax"], 
            data["qmin"], 
            data["mbase"], 
            data["cost"],
            data["state_model"],
            data["λ_updn"],
            data["μ_updn"],
            data["λ_upde"],
            data["μ_upde"],
            data["pde"],
            data["gen_status"]
        )
    end
    
    if !isempty(network_load)
        data = container(network_load, load_fields)
        if isempty(network[:timeseries_load])
            loads = Loads{N,L,T}(
                data["index"], 
                data["load_bus"], 
                data["pd"], 
                data["qd"],
                data["pf"],
                data["cost"],
                data["status"]
            )
        else
            timeseries_load::Dict{Int64, Vector{Float32}} = network[:timeseries_load]
            timeseries_pd = convert_array(data["index"], timeseries_load, baseMVA)
            loads = Loads{N,L,T}(
                data["index"], 
                data["load_bus"], 
                timeseries_pd, 
                data["qd"],
                data["pf"],
                data["cost"],
                data["status"]
            )
        end

    end

    if !isempty(network_storage) && network[:time_elapsed] == 1.0
        data = container(network_storage, storage_fields)
        storages = Storages{N,L,T}(
            data["index"], 
            data["storage_bus"],
            data["ps"], 
            data["qs"],
            data["energy"],
            data["energy_rating"],
            data["charge_rating"],
            data["discharge_rating"],
            data["charge_efficiency"],
            data["discharge_efficiency"],
            data["thermal_rating"],
            data["qmax"],
            data["qmin"],
            data["r"],
            data["x"],
            data["p_loss"],
            data["q_loss"],
            data["λ_updn"],
            data["μ_updn"],
            data["status"],
        )

    else
        storages = Storages{N,L,T}(
            Int[], Int[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], 
            Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float64[], Float64[], Vector{Bool}())
    end

    _check_consistency(network, buses, loads, branches, shunts, generators, storages)
    _check_connectivity(network, buses, loads, branches, shunts, generators, storages)

    return SystemModel(loads, generators, storages, buses, branches, commonbranches, shunts, baseMVA, SParametrics.timestamps)
end
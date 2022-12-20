"""
Load a `SystemModel` from appropriately-formatted XLSX and PSSE RAW files on disk.
"""
function SystemModel(RawFile::String, ReliabilityFile::String)

    #load network data
    network = build_network(RawFile)
    reliability_data = parse_reliability_data(ReliabilityFile)
    SParametrics = StaticParameters{1,1,Hour}()
    get!(network, :timeseries_load, "")
    _merge_CompositeSystems_data!(network, reliability_data, SParametrics)
    return _SystemModel(network, SParametrics)

end

""
function SystemModel(RawFile::String, ReliabilityFile::String, TimeSeriesFile::String)

    #load network data
    network = build_network(RawFile)
    reliability_data = parse_reliability_data(ReliabilityFile)
    timeseries_data, SParametrics = extract_timeseriesload(TimeSeriesFile)
    merge_CompositeSystems_data!(network, reliability_data, timeseries_data, SParametrics)
    return _SystemModel(network, SParametrics)

end

""
function SystemModel(RawFile::String, ReliabilityFile::String, timeseries_data::Dict{Int, Vector{Float32}}, SParametrics::StaticParameters{N,L,T}) where {N,L,T<:Period}

    #load network data
    network = build_network(RawFile)
    reliability_data = parse_reliability_data(ReliabilityFile)
    merge_CompositeSystems_data!(network, reliability_data, timeseries_data, SParametrics)
    return _SystemModel(network, SParametrics)

end


""
function _SystemModel(network::Dict{Symbol, Any}, SParametrics::StaticParameters{N,L,T}) where {N,L,T<:Period}

    baseMVA::Float32 = Float32(network[:baseMVA])
    network_bus::Dict{Int, Any} = network[:bus]
    network_branch::Dict{Int, Any} = network[:branch]
    network_interface::Dict{Int, Any} = network[:interface]
    network_shunt::Dict{Int, Any} = network[:shunt]
    network_gen::Dict{Int, Any} = network[:gen]
    network_load::Dict{Int, Any} = network[:load]
    network_storage::Dict{Int, Any} = network[:storage]

    has = has_asset(network)
    
    if has[:buses]
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

    if has[:branches]
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
            data["λ"], 
            data["μ"],
            data["br_status"]
        )
    end

    if has[:shunts]
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

    if has[:interfaces]
        data = container(network_interface, interface_fields)
        interfaces = Interfaces(
            data["index"], 
            data["f_bus"], 
            data["t_bus"], 
            data["λ"], 
            data["μ"]
        )
    else
        interfaces = Interfaces(Int[], Int[], Int[], Float64[], Float64[])
    end

    if has[:generators]
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
            data["λ"],
            data["μ"],
            data["gen_status"]
        )
    end
    
    if has[:loads]
        data = container(network_load, load_fields)
        if isempty(network[:timeseries_load])
            loads = Loads{N,L,T}(
                data["index"], 
                data["load_bus"], 
                data["pd"], 
                data["qd"],
                data["pf"],
                data["cost"],
                data["firm_load"],
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
                data["firm_load"],
                data["status"]
            )
        end

    end

    if has[:storages] && network[:time_elapsed] == 1.0
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
            data["λ"],
            data["μ"],
            data["status"],
        )

    else
        storages = Storages{N,L,T}(
            Int[], Int[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], 
            Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float64[], Float64[], Vector{Bool}())
    end
    
    if has[:dclines]
        #
    end

    if has[:switches]
        #
    end


    generatorstorages = GeneratorStorages{N,L,T}(
        Int[], Int[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], 
        Array{Float32}(undef, 0, N), Array{Float32}(undef, 0, N), Array{Float32}(undef, 0, N), Float64[], Float64[], Vector{Bool}())


    _check_consistency(network, buses, loads, branches, shunts, generators, storages)
    _check_connectivity(network, buses, loads, branches, shunts, generators, storages)

    ref_buses = slack_buses(buses)

    return SystemModel(loads, generators, storages, generatorstorages, buses, branches, shunts, interfaces, ref_buses, baseMVA, SParametrics.timestamps)
    
end


""
function slack_buses(buses::Buses)

    ref_buses = Int[]
    for i in buses.keys
        if buses.bus_type[i] == 3
            push!(ref_buses, i)
        end
    end

    if length(ref_buses) > 1
        @error("multiple reference buses found, $(keys(ref_buses)), this can cause infeasibility if they are in the same connected component")
    end

    return ref_buses

end

""
function has_asset(network::Dict{Symbol,Any})

    has = Dict{Symbol, Bool}(
        :buses => haskey(network, :bus) && isempty(network[:bus]) == false,
        :loads => haskey(network, :load) && isempty(network[:load]) == false,
        :generators => haskey(network, :gen) && isempty(network[:gen]) == false,
        :storages => haskey(network, :storage) && isempty(network[:storage]) == false,
        :branches => haskey(network, :branch) && isempty(network[:branch]) == false,
        :interfaces => haskey(network, :interface) && isempty(network[:interface]) == false,
        :dclines => haskey(network, :dcline) && isempty(network[:dcline]) == false,
        :switches => haskey(network, :switch) && isempty(network[:switch]) == false,
        :shunts => haskey(network, :shunt) && isempty(network[:shunt]) == false,
    )

    has[:buses] ||  @error("Bus data must be provided")
    has[:generators] && has[:loads] && has[:branches] ||  @error("Generator, Load and Branch data must be provided")

    return has

end

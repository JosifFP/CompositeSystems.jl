"""
    SystemModel(filename::String)

Load a `SystemModel` from appropriately-formatted XLSX and PSSE RAW files on disk.
"""
function SystemModel(RawFile::String, ReliabilityDataDir::String, N::Int)

    CurrentDir = pwd()
    L = 1 #timestep_length
    T = timeunits["h"] #timestep_unit
    U = perunit["pu"]
    #P = powerunits["MW"] #E = energyunits["MWh"] #V = voltageunits["kV"]
    start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))

    timestamps = range(start_timestamp, length=N, step=T(L))::StepRange{DateTime, Hour}
    files = readdir(ReliabilityDataDir; join=false)
    cd(ReliabilityDataDir)
    network = BuildNetwork(RawFile)

    if network[:per_unit] == false error("Network data must be in per unit format") end

    has_buses = haskey(network, :bus) && isempty(network[:bus]) == false
    has_loads = haskey(network, :load) && isempty(network[:load]) == false
    has_generators = haskey(network, :gen) && isempty(network[:gen]) == false
    has_storages = haskey(network, :storage) && isempty(network[:storage]) == false
    has_branches = haskey(network, :branch) && isempty(network[:branch]) == false
    has_dclines = haskey(network, :dcline) && isempty(network[:dcline]) == false
    has_switches = haskey(network, :switch) && isempty(network[:switch]) == false
    has_shunts = haskey(network, :shunt) && isempty(network[:shunt]) == false

    has_buses || error("Bus data must be provided")
    has_generators && has_loads && has_branches || error("Generator, Load and Branch data must be provided")

    if has_buses
        asset_bus = container(network, Buses, N, L, T, U)
    end

    if has_generators
        dict_timeseries, dict_core = extract(ReliabilityDataDir, files, Generators, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        asset_gen = container(container_key, key_order_series, dict_core, dict_timeseries, network, Generators, N, L, T, U)
        empty!(dict_timeseries)
        empty!(dict_core)
        empty!(key_order_series)
    end
    
    if has_loads
        dict_timeseries, dict_core = extract(ReliabilityDataDir, files, Loads, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        asset_load = container(container_key, key_order_series, dict_core, dict_timeseries, network, Loads, N, L, T, U)
        empty!(dict_timeseries)
        empty!(dict_core)
        empty!(key_order_series)
    end

    if has_branches
        _, dict_core = extract(ReliabilityDataDir, files, Branches, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        asset_branch = container(dict_core, network, Branches, N, L, T, U)
    end

    if has_shunts
        asset_shunt = container(network, Shunts, N, L, T, U)
    end

    if has_storages
    else
        asset_storage = Storages{N,L,T,U}(
            Int[], Int[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], 
            Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], BitVector(), Float64[], Float64[])
    end

    if has_dclines
        #
    # else
    #     asset_dcline = DCLines{N,L,T,U}()
    end

    if has_switches
        #
    end
    
    asset_gentor = GeneratorStorages{N,L,T,U}(
        Int[], Int[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], 
        Float16[], BitVector(), Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Float64[], Float64[]
    )

    cd(CurrentDir)

    return SystemModel(asset_bus, asset_gen, asset_load, asset_storage, asset_gentor, asset_branch, asset_shunt, timestamps)

end


""
function _check_connectivity(data::Dict{String,<:Any})
    bus_ids = Set(bus["index"] for (i,bus) in data["bus"])
    @assert(length(bus_ids) == length(data["bus"])) # if this is not true something very bad is going on

    for (i, load) in data["load"]
        if !(load["load_bus"] in bus_ids)
            Memento.error(_LOGGER, "bus $(load["load_bus"]) in load $(i) is not defined")
        end
    end

    for (i, shunt) in data["shunt"]
        if !(shunt["shunt_bus"] in bus_ids)
            Memento.error(_LOGGER, "bus $(shunt["shunt_bus"]) in shunt $(i) is not defined")
        end
    end

    for (i, gen) in data["gen"]
        if !(gen["gen_bus"] in bus_ids)
            Memento.error(_LOGGER, "bus $(gen["gen_bus"]) in generator $(i) is not defined")
        end
    end

    for (i, strg) in data["storage"]
        if !(strg["storage_bus"] in bus_ids)
            Memento.error(_LOGGER, "bus $(strg["storage_bus"]) in storage unit $(i) is not defined")
        end
    end

    for (i, switch) in data["switch"]
        if !(switch["f_bus"] in bus_ids)
            Memento.error(_LOGGER, "from bus $(switch["f_bus"]) in switch $(i) is not defined")
        end

        if !(switch["t_bus"] in bus_ids)
            Memento.error(_LOGGER, "to bus $(switch["t_bus"]) in switch $(i) is not defined")
        end
    end

    for (i, branch) in data["branch"]
        if !(branch["f_bus"] in bus_ids)
            Memento.error(_LOGGER, "from bus $(branch["f_bus"]) in branch $(i) is not defined")
        end

        if !(branch["t_bus"] in bus_ids)
            Memento.error(_LOGGER, "to bus $(branch["t_bus"]) in branch $(i) is not defined")
        end
    end

    for (i, dcline) in data["dcline"]
        if !(dcline["f_bus"] in bus_ids)
            Memento.error(_LOGGER, "from bus $(dcline["f_bus"]) in dcline $(i) is not defined")
        end

        if !(dcline["t_bus"] in bus_ids)
            Memento.error(_LOGGER, "to bus $(dcline["t_bus"]) in dcline $(i) is not defined")
        end
    end
end


"checks that active components are not connected to inactive buses, otherwise prints warnings"
function check_status(data::Dict{String,<:Any})
    apply_pm!(_check_status, data)
end

""
function _check_status(data::Dict{String,<:Any})
    active_bus_ids = Set(bus["index"] for (i,bus) in data["bus"] if bus["bus_type"] != 4)

    for (i, load) in data["load"]
        if load["status"] != 0 && !(load["load_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active load $(i) is connected to inactive bus $(load["load_bus"])")
        end
    end

    for (i, shunt) in data["shunt"]
        if shunt["status"] != 0 && !(shunt["shunt_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active shunt $(i) is connected to inactive bus $(shunt["shunt_bus"])")
        end
    end

    for (i, gen) in data["gen"]
        if gen["gen_status"] != 0 && !(gen["gen_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active generator $(i) is connected to inactive bus $(gen["gen_bus"])")
        end
    end

    for (i, strg) in data["storage"]
        if strg["status"] != 0 && !(strg["storage_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active storage unit $(i) is connected to inactive bus $(strg["storage_bus"])")
        end
    end

    for (i, branch) in data["branch"]
        if branch["br_status"] != 0 && !(branch["f_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active branch $(i) is connected to inactive bus $(branch["f_bus"])")
        end

        if branch["br_status"] != 0 && !(branch["t_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active branch $(i) is connected to inactive bus $(branch["t_bus"])")
        end
    end

    for (i, dcline) in data["dcline"]
        if dcline["br_status"] != 0 && !(dcline["f_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active dcline $(i) is connected to inactive bus $(dcline["f_bus"])")
        end

        if dcline["br_status"] != 0 && !(dcline["t_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active dcline $(i) is connected to inactive bus $(dcline["t_bus"])")
        end
    end
end
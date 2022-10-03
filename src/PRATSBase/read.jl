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
        buses = container(network, Buses, N, L, T, U)
    end

    if has_generators
        dict_timeseries, dict_core = extract(ReliabilityDataDir, files, Generators, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        generators = container(container_key, key_order_series, dict_core, dict_timeseries, network, Generators, N, L, T, U)
        empty!(dict_timeseries)
        empty!(dict_core)
        empty!(key_order_series)
    end
    
    if has_loads
        dict_timeseries, dict_core = extract(ReliabilityDataDir, files, Loads, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        loads = container(container_key, key_order_series, dict_core, dict_timeseries, network, Loads, N, L, T, U)
        empty!(dict_timeseries)
        empty!(dict_core)
        empty!(key_order_series)
    end

    if has_branches
        _, dict_core = extract(ReliabilityDataDir, files, Branches, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        branches = container(dict_core, network, Branches, N, L, T, U)
    end

    if has_shunts
        shunts = container(network, Shunts, N, L, T, U)
    end

    if has_storages
    else
        storages = Storages{N,L,T,U}(
            Int[], Int[], Float16[], Float16[], 
            Float16[], Float16[], Float16[], Float16[], 
            Float16[], Float16[], Float16[], Float16[], 
            Float16[], Float16[], Float16[], Float16[], 
            Float16[], BitVector(), Float64[], Float64[])
    end
    
    if has_dclines
        #
    # else
    #     asset_dcline = DCLines{N,L,T,U}()
    end

    if has_switches
        #
    end
    
    generatorstorages = GeneratorStorages{N,L,T,U}(
        Int[], Int[], Float16[], Float16[], 
        Float16[], Float16[], Float16[], Float16[], 
        Float16[], Float16[], BitVector(), 
        Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), 
        Float64[], Float64[]
    )

    cd(CurrentDir)


    _check_consistency(network, buses, loads, branches, shunts, generators, storages)
    _check_connectivity(network, buses, loads, branches, shunts, generators, storages)

    topology = container(network, Topology, buses, loads, branches, shunts, generators, storages,N, U)

    return SystemModel(buses, loads, branches, shunts, generators, storages, generatorstorages, topology, timestamps)

end


"Checks for inconsistencies between AbstractAsset and Power Model Network"
function _check_consistency(ref::Dict{Symbol,<:Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

    for k in buses.keys
        @assert haskey(ref[:bus],k) == true
        @assert Int.(ref[:bus][k]["index"]) == buses.keys[k]
        @assert Int.(ref[:bus][k]["index"]) == buses.index[k]
        @assert Int.(ref[:bus][k]["area"]) == buses.area[k]
        @assert Int.(ref[:bus][k]["bus_type"]) == buses.bus_type[k]
        @assert Float16.(ref[:bus][k]["vmax"]) == buses.vmax[k]
        @assert Float16.(ref[:bus][k]["vmin"]) == buses.vmin[k]
        @assert Float16.(ref[:bus][k]["base_kv"]) == buses.base_kv[k]
        @assert Float32.(ref[:bus][k]["va"]) == buses.va[k]
        @assert Float32.(ref[:bus][k]["vm"]) == buses.vm[k]
    end
    
    for k in generators.keys
        @assert haskey(ref[:gen],k) == true
        @assert Int.(ref[:gen][k]["index"]) == generators.keys[k]
        @assert Int.(ref[:gen][k]["gen_bus"]) == generators.buses[k]
        @assert Float16.(ref[:gen][k]["qg"]) == generators.qg[k]
        @assert Float32.(ref[:gen][k]["vg"]) == generators.vg[k]
        @assert Float16.(ref[:gen][k]["pmax"]) == generators.pmax[k]
        @assert Float16.(ref[:gen][k]["pmin"]) == generators.pmin[k]
        @assert Float16.(ref[:gen][k]["qmax"]) == generators.qmax[k]
        @assert Float16.(ref[:gen][k]["qmin"]) == generators.qmin[k]
        @assert Int.(ref[:gen][k]["mbase"]) == generators.mbase[k]
        @assert Bool.(ref[:gen][k]["gen_status"]) == generators.status[k]
        #@assert (ref[:gen][k]["cost"]) == generators.cost[k]
    end
    
    for k in loads.keys
        @assert haskey(ref[:load],k) == true
        @assert Int.(ref[:load][k]["index"]) == loads.keys[k]
        @assert Int.(ref[:load][k]["load_bus"]) == loads.buses[k]
        @assert Float16.(ref[:load][k]["qd"]) == loads.qd[k]
        @assert Bool.(ref[:load][k]["status"]) == loads.status[k]
    end
    
    for k in branches.keys
        @assert haskey(ref[:branch],k) == true
        @assert Int.(ref[:branch][k]["index"]) == branches.keys[k]
        @assert Int.(ref[:branch][k]["f_bus"]) == branches.f_bus[k]
        @assert Int.(ref[:branch][k]["t_bus"]) == branches.t_bus[k]
        @assert Float16.(ref[:branch][k]["rate_a"]) == branches.rate_a[k]
        @assert Float16.(ref[:branch][k]["rate_b"]) == branches.rate_b[k]
        @assert Float16.(ref[:branch][k]["rate_c"]) == branches.rate_c[k]
        @assert Float16.(ref[:branch][k]["br_r"]) == branches.r[k]
        @assert Float16.(ref[:branch][k]["br_x"]) == branches.x[k]
        @assert Float16.(ref[:branch][k]["b_fr"]) == branches.b_fr[k]
        @assert Float16.(ref[:branch][k]["b_to"]) == branches.b_to[k]
        @assert Float16.(ref[:branch][k]["g_fr"]) == branches.g_fr[k]
        @assert Float16.(ref[:branch][k]["g_to"]) == branches.g_to[k]
        @assert Float16.(ref[:branch][k]["shift"]) == branches.shift[k]
        @assert Float16.(ref[:branch][k]["angmin"]) == branches.angmin[k]
        @assert Float16.(ref[:branch][k]["angmax"]) == branches.angmax[k]
        @assert Bool.(ref[:branch][k]["transformer"]) == branches.transformer[k]
        @assert Float16.(ref[:branch][k]["tap"]) == branches.tap[k]
        @assert Bool.(ref[:branch][k]["br_status"]) == branches.status[k]
    end
    
    for k in shunts.keys
        @assert haskey(ref[:shunt],k) == true
        @assert Int.(ref[:shunt][k]["index"]) == shunts.keys[k]
        @assert Int.(ref[:shunt][k]["shunt_bus"]) == shunts.buses[k]
        @assert Float16.(ref[:shunt][k]["bs"]) == shunts.bs[k]
        @assert Float16.(ref[:shunt][k]["gs"]) == shunts.gs[k]
        @assert Bool.(ref[:shunt][k]["status"]) == shunts.status[k]
    end
    
end

"Checks connectivity issues and status"
function _check_connectivity(ref::Dict{Symbol,<:Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

    @assert(length(buses.keys) == length(ref[:bus])) # if this is not true something very bad is going on
    active_bus_ids = Set(bus["index"] for (i,bus) in ref[:bus] if bus["bus_type"] != 4)

    for (i, gen) in ref[:gen]
        if !(gen["gen_bus"] in buses.keys) || !(generators.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(gen["gen_bus"]) in shunt $(i) is not defined")
        end
        if gen["gen_status"] != 0 && !(gen["gen_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active generator $(i) is connected to inactive bus $(gen["gen_bus"])")
        end
    end

    for (i, load) in ref[:load]
        if !(load["load_bus"] in buses.keys) || !(loads.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(load["load_bus"]) in load $(i) is not defined")
        end

        if load["status"] != 0 && !(load["load_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active load $(i) is connected to inactive bus $(load["load_bus"])")
        end       
    end

    for (i, shunt) in ref[:shunt]
        if !(shunt["shunt_bus"] in buses.keys) || !(shunts.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(shunt["shunt_bus"]) in shunt $(i) is not defined")
        end
        if shunt["status"] != 0 && !(shunt["shunt_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active shunt $(i) is connected to inactive bus $(shunt["shunt_bus"])")
        end
    end

    for (i, strg) in ref[:storage]
        if !(strg["storage_bus"] in buses.keys) || !(storages.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(strg["storage_bus"]) in shunt $(i) is not defined")
        end
        if strg["status"] != 0 && !(strg["storage_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active storage unit $(i) is connected to inactive bus $(strg["storage_bus"])")
        end
    end
    
    for (i, branch) in ref[:branch]
        if !(branch["f_bus"] in buses.keys) || !(branches.f_bus[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(branch["f_bus"]) in shunt $(i) is not defined")
        end
        if !(branch["t_bus"] in buses.keys) || !(branches.t_bus[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(branch["t_bus"]) in shunt $(i) is not defined")
        end
        if branch["br_status"] != 0 && !(branch["f_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active branch $(i) is connected to inactive bus $(branch["f_bus"])")
        end

        if branch["br_status"] != 0 && !(branch["t_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active branch $(i) is connected to inactive bus $(branch["t_bus"])")
        end

        # if dcline["br_status"] != 0 && !(dcline["f_bus"] in active_bus_ids)
        #     Memento.warn(_LOGGER, "active dcline $(i) is connected to inactive bus $(dcline["f_bus"])")
        # end

        # if dcline["br_status"] != 0 && !(dcline["t_bus"] in active_bus_ids)
        #     Memento.warn(_LOGGER, "active dcline $(i) is connected to inactive bus $(dcline["t_bus"])")
        # end
    end

end
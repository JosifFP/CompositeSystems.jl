"""
Load a `SystemModel` from appropriately-formatted XLSX and PSSE RAW files on disk.
"""
function SystemModel(RawFile::String, ReliabilityDataDir::String, N::Int)

    CurrentDir = pwd()

    L = 1 #timestep_length
    T = timeunits["h"] #timestep_unit
    start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))
    timezone = "UTC"
    timestamps_tz = timestamps(start_timestamp, N, L, T, timezone)

    files = readdir(ReliabilityDataDir; join=false)
    cd(ReliabilityDataDir)
    network = BuildNetwork(RawFile)

    S = Int(network[:baseMVA]) #base MVA

    if network[:per_unit] == false Memento.error(_LOGGER,"Network data must be in per unit format") end
    has_buses = haskey(network, :bus) && isempty(network[:bus]) == false
    has_loads = haskey(network, :load) && isempty(network[:load]) == false
    has_generators = haskey(network, :gen) && isempty(network[:gen]) == false
    has_storages = haskey(network, :storage) && isempty(network[:storage]) == false
    has_branches = haskey(network, :branch) && isempty(network[:branch]) == false
    has_dclines = haskey(network, :dcline) && isempty(network[:dcline]) == false
    has_switches = haskey(network, :switch) && isempty(network[:switch]) == false
    has_shunts = haskey(network, :shunt) && isempty(network[:shunt]) == false

    has_buses ||  Memento.error(_LOGGER,"Bus data must be provided")
    has_generators && has_loads && has_branches ||  Memento.error(_LOGGER,"Generator, Load and Branch data must be provided")

    if has_buses
        buses = container(network, Buses, S, N, L, T)
    end

    if has_generators
        dict_timeseries, dict_core = extract(ReliabilityDataDir, files, Generators, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        generators = container(container_key, key_order_series, dict_core, dict_timeseries, network, Generators, S, N, L, T)
        empty!(dict_timeseries)
        empty!(dict_core)
        empty!(key_order_series)
    end
    
    if has_loads
        dict_timeseries, dict_core = extract(ReliabilityDataDir, files, Loads, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        loads = container(container_key, key_order_series, dict_core, dict_timeseries, network, Loads, S, N, L, T)
        empty!(dict_timeseries)
        empty!(dict_core)
        empty!(key_order_series)
    end

    if has_branches
        _, dict_core = extract(ReliabilityDataDir, files, Branches, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        branches = container(dict_core, network, Branches, S, N, L, T)
    end

    if has_shunts
        shunts = container(network, Shunts, S, N, L, T)
    end

    if has_storages
    else
        storages = Storages{N,L,T,S}(
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
    
    generatorstorages = GeneratorStorages{N,L,T,S}(
        Int[], Int[], Float16[], Float16[], 
        Float16[], Float16[], Float16[], Float16[], 
        Float16[], Float16[], BitVector(), 
        Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), 
        Float64[], Float64[]
    )

    cd(CurrentDir)

    _check_consistency(network, buses, loads, branches, shunts, generators, storages)
    _check_connectivity(network, buses, loads, branches, shunts, generators, storages)

    ref_buses = Int[]
    for i in buses.keys
        if buses.bus_type[i] == 3
            push!(ref_buses, i)
        end
    end

    if length(ref_buses) > 1
        Memento.error(_LOGGER, "multiple reference buses found, $(keys(ref_buses)), this can cause infeasibility if they are in the same connected component")
    end

    return SystemModel(buses, loads, branches, shunts, generators, storages, generatorstorages, timestamps_tz)

end

""
function timestamps(start_timestamp::DateTime, N::Int, L::Int, T::Type, timezone::String)
    timestamps = range(start_timestamp, length=N, step=T(L))
    tz = TimeZone(timezone)
    time_start = ZonedDateTime(first(timestamps), tz)
    time_end = ZonedDateTime(last(timestamps), tz)
    return time_start:step(timestamps):time_end
end
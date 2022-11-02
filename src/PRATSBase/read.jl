"""
Load a `SystemModel` from appropriately-formatted XLSX and PSSE RAW files on disk.
"""
function SystemModel(RawFile::String; ReliabilityDataDir::String="No Directory")

    system = open(RawFile) do io
        network = Dict{Symbol, Any}(BuildNetwork(io, split(lowercase(RawFile), '.')[end]))
        network[:per_unit] == false && Memento.error(_LOGGER,"Network data must be in per unit format")
        N = intunits[network[:N]]
        L = intunits[network[:L]]
        T = timeunits[network[:T]]

        if ReliabilityDataDir=="No Directory" && N==1
            return _SystemModel(network, N, L, T)
        else
            return SystemModel(network, ReliabilityDataDir, N, L, T)
        end
    end
    return system

end

""
function _SystemModel(network::Dict{Symbol, Any}, N, L, T::Type{Ts}) where {Ts<:Period}
    
    baseMVA = Float16(getindex(network, :baseMVA))

    has = has_asset(network)

    if has[:buses]
        data = container(network, Buses)
        buses = Buses(
            data[:keys], data[:zone], data[:bus_type], data[:index],
            data[:vmax], data[:vmin], data[:base_kv], data[:va], data[:vm])
        empty!(data)
    end

    if has[:branches]
        data = container(network, Branches)
        branches = Branches(
            data[:keys], data[:f_bus], data[:t_bus], data[:rate_a], data[:rate_b], data[:r], 
            data[:x], data[:b_fr], data[:b_to], data[:g_fr], data[:g_to], data[:shift], 
            data[:angmin], data[:angmax], data[:transformer], data[:tap], data[:λ], data[:μ], data[:status])
        empty!(data)
    end

    if has[:shunts]
        data = container(network, Shunts)
        shunts = Shunts(data[:keys], data[:buses], data[:bs], data[:gs], data[:status])
        empty!(data)
    else
        shunts = Shunts(Int[], Int[], Float16[], Float16[], BitVector())
    end

    if has[:generators]
        data = container(network, Generators)
        generators = Generators{N,L,T}(
            data[:keys], data[:buses], data[:pg], data[:qg], data[:vg], data[:pmax], data[:pmin], 
            data[:qmax], data[:qmin], data[:mbase], data[:cost], data[:λ], data[:μ], data[:status])
        empty!(data)
    end
    
    if has[:loads]
        data = container(network, Loads)
        loads = Loads{N,L,T}(data[:keys], data[:buses], data[:pd], data[:qd], data[:cost], data[:status])
        empty!(data)
    end

    if has[:storages]
    else
        storages = Storages{N,L,T}(
            Int[], Int[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], 
            Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float64[], Float64[], BitVector())
    end
    
    if has[:dclines]
        #
    # else
    #     asset_dcline = DCLines{N,L,T,U}()
    end

    if has[:switches]
        #
    end
    
    generatorstorages = GeneratorStorages{N,L,T}(
        Int[], Int[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], 
        Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Float64[], Float64[], BitVector())

    _check_consistency(network, buses, loads, branches, shunts, generators, storages)
    _check_connectivity(network, buses, loads, branches, shunts, generators, storages)

    arcs = Arcs(branches, buses.keys, length(buses), length(branches))
    ref_buses = slack_buses(buses)

    return SystemModel(loads, generators, storages, generatorstorages, buses, branches, shunts, arcs, ref_buses, baseMVA)
    
end

""
function SystemModel(network::Dict{Symbol, Any}, ReliabilityDataDir::String, N, L, T::Type{Ts}) where {Ts<:Period}

    CurrentDir = pwd()
    baseMVA = Float16(getindex(network, :baseMVA))
    
    files = readdir(ReliabilityDataDir; join=false)
    cd(ReliabilityDataDir)

    has = has_asset(network)

    if has[:buses]
        data = container(network, Buses)
        buses = Buses(
            data[:keys], data[:zone], data[:bus_type], data[:index],
            data[:vmax], data[:vmin], data[:base_kv], data[:va], data[:vm])
        empty!(data)
    end

    
    if has[:branches]
        _, dict_core = extract(ReliabilityDataDir, files, Branches, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        data = container(dict_core, network, Branches, N, baseMVA)
        branches = Branches(
            data[:keys], data[:f_bus], data[:t_bus], data[:rate_a], data[:rate_b], data[:r], 
            data[:x], data[:b_fr], data[:b_to], data[:g_fr], data[:g_to], data[:shift], 
            data[:angmin], data[:angmax], data[:transformer], data[:tap], data[:λ], data[:μ], data[:status])
        empty!(data)
    end

    if has[:shunts]
        data = container(network, Shunts)
        shunts = Shunts(data[:keys], data[:buses], data[:bs], data[:gs], data[:status])
        empty!(data)
    else
        shunts = Shunts(Int[], Int[], Float16[], Float16[], BitVector())
    end

    if has[:generators]
        #dict_timeseries, dict_core = extract(ReliabilityDataDir, files, Generators, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        #data = container(dict_core, dict_timeseries, network, Generators, N, B)
        data = container(network, Generators)
        generators = Generators{N,L,T}(
            data[:keys], data[:buses], data[:pg], data[:qg], data[:vg], data[:pmax], data[:pmin], 
            data[:qmax], data[:qmin], data[:mbase], data[:cost], data[:λ], data[:μ], data[:status])
        empty!(data)
        #empty!(dict_timeseries)
        #empty!(dict_core)
    end

    if has[:loads]
        dict_timeseries, dict_core = extract(ReliabilityDataDir, files, Loads, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        data = container(dict_core, dict_timeseries, network, Loads, N, baseMVA)
        loads = Loads{N,L,T}(data[:keys], data[:buses], data[:pd], data[:qd], data[:cost], data[:status])
        empty!(data)
        empty!(dict_timeseries)
        empty!(dict_core)
    end

    if has[:storages]
    else
        storages = Storages{N,L,T}(
            Int[], Int[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], 
            Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float64[], Float64[], BitVector())
    end
    
    if has[:dclines]
        #
    # else
    #     asset_dcline = DCLines{N,L,T,U}()
    end

    if has[:switches]
        #
    end
    
    generatorstorages = GeneratorStorages{N,L,T}(
        Int[], Int[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], 
        Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Float64[], Float64[], BitVector()
    )

    cd(CurrentDir)
    _check_consistency(network, buses, loads, branches, shunts, generators, storages)
    _check_connectivity(network, buses, loads, branches, shunts, generators, storages)

    arcs = Arcs(branches, buses.keys, length(buses), length(branches))
    ref_buses = slack_buses(buses)

    return SystemModel(loads, generators, storages, generatorstorages, buses, branches, shunts, arcs, ref_buses, baseMVA)

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
        Memento.error(_LOGGER, "multiple reference buses found, $(keys(ref_buses)), this can cause infeasibility if they are in the same connected component")
    end

    return ref_buses

end

""
function timestamps(start_timestamp::DateTime, N::Int, L::Int, T::Type, timezone::String)
    timestamps = range(start_timestamp, length=N, step=T(L))
    tz = TimeZone(timezone)
    time_start = ZonedDateTime(first(timestamps), tz)
    time_end = ZonedDateTime(last(timestamps), tz)
    return time_start:step(timestamps):time_end
end

""
function has_asset(network::Dict{Symbol,Any})

    has = Dict{Symbol, Bool}(
        :buses => haskey(network, :bus) && isempty(network[:bus]) == false,
        :loads => haskey(network, :load) && isempty(network[:load]) == false,
        :generators => haskey(network, :gen) && isempty(network[:gen]) == false,
        :storages => haskey(network, :storage) && isempty(network[:storage]) == false,
        :branches => haskey(network, :branch) && isempty(network[:branch]) == false,
        :dclines => haskey(network, :dcline) && isempty(network[:dcline]) == false,
        :switches => haskey(network, :switch) && isempty(network[:switch]) == false,
        :shunts => haskey(network, :shunt) && isempty(network[:shunt]) == false,
    )

    has[:buses] ||  Memento.error(_LOGGER,"Bus data must be provided")
    has[:generators] && has[:loads] && has[:branches] ||  Memento.error(_LOGGER,"Generator, Load and Branch data must be provided")

    return has

end

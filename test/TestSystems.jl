module TestSystems
    using PRATS
    import PRATS: PRATSBase, Branches, Buses, Shunts, Loads, Generators, Storages

    ReliabilityDataDir = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS"
    RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS2.m"
    PRATSBase.silence()
    CurrentDir = pwd()

    network = Dict{Symbol, Any}(PRATSBase.BuildNetwork(RawFile))
    baseMVA = Float16(getindex(network, :baseMVA))

    files = readdir(ReliabilityDataDir; join=false)
    cd(ReliabilityDataDir)
    has = PRATSBase.has_asset(network)
    N = 8736

    if has[:buses]
        data = PRATSBase.container(network, Buses)
        buses = Buses(
            data[:keys], data[:zone], data[:bus_type], data[:index],
            data[:vmax], data[:vmin], data[:base_kv], data[:va], data[:vm])
    end


    if has[:branches]
        _, dict_core = PRATSBase.extract(ReliabilityDataDir, files, Branches, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        data = PRATSBase.container(dict_core, network, Branches, 8736, baseMVA)
        branches = Branches(
            data[:keys], data[:f_bus], data[:t_bus], data[:rate_a], data[:rate_b], data[:r], 
            data[:x], data[:b_fr], data[:b_to], data[:g_fr], data[:g_to], data[:shift], 
            data[:angmin], data[:angmax], data[:transformer], data[:tap], data[:λ], data[:μ], data[:status])
    end

    if has[:shunts]
        data = PRATSBase.container(network, Shunts)
        shunts = Shunts(data[:keys], data[:buses], data[:bs], data[:gs], data[:status])
    else
        shunts = Shunts(Int[], Int[], Float16[], Float16[], BitVector())
    end

    if has[:generators]
        data = PRATSBase.container(network, Generators)
        generators = Generators{8736,1,Hour}(
            data[:keys], data[:buses], data[:pg], data[:qg], data[:vg], data[:pmax], data[:pmin], 
            data[:qmax], data[:qmin], data[:mbase], data[:cost], data[:λ], data[:μ], data[:status])
    end

    if has[:loads]
        dict_timeseries, dict_core = PRATSBase.extract(ReliabilityDataDir, files, Loads, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        data = PRATSBase.container(dict_core, dict_timeseries, network, Loads, 8736, baseMVA)
        loads = Loads{8736,1,Hour}(data[:keys], data[:buses], data[:pd], data[:qd], data[:cost], data[:status])
    end

    if has[:storages]
    else
        storages = Storages{8736,1,Hour}(
            Int[], Int[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], 
            Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float64[], Float64[], BitVector())
    end

    generatorstorages = GeneratorStorages{8736,1,Hour}(
        Int[], Int[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], Float16[], 
        Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Array{Float16}(undef, 0, N), Float64[], Float64[], BitVector()
    )

    cd(CurrentDir)
    PRATSBase._check_consistency(network, buses, loads, branches, shunts, generators, storages)
    PRATSBase._check_connectivity(network, buses, loads, branches, shunts, generators, storages)

    arcs = PRATSBase.Arcs(branches, buses.keys, length(buses), length(branches))
    ref_buses = PRATSBase.slack_buses(buses)

    RBTS = CompositeAdequacy.SystemModel(loads, generators, storages, generatorstorages, buses, branches, shunts, arcs, ref_buses, baseMVA)

end

import .TestSystems
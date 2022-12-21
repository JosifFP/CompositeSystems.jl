module RTS
    using CompositeSystems
    import CompositeSystems: BaseModuleModule, Branches, Buses, Shunts, Loads, Generators, Storages

    ReliabilityDataDir = "C:/Users/jfiguero/.julia/dev/CompositeSystems/test/data/RTS"
    RawFile = "C:/Users/jfiguero/.julia/dev/CompositeSystems/test/data/RTS.m"
    BaseModule.silence()
    CurrentDir = pwd()

    network = Dict{Symbol, Any}(BaseModule.build_network(RawFile))
    baseMVA = Float32(getindex(network, :baseMVA))

    files = readdir(ReliabilityDataDir; join=false)
    cd(ReliabilityDataDir)
    has = BaseModule.has_asset(network)
    N = 8736

    if has[:buses]
        data = BaseModule.container(network, Buses)
        buses = Buses(
            data[:keys], data[:zone], data[:bus_type], data[:bus_i],
            data[:vmax], data[:vmin], data[:base_kv], data[:va], data[:vm])
    end


    if has[:branches]
        _, dict_core = BaseModule.extract(ReliabilityDataDir, files, Branches, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        data = BaseModule.container(dict_core, network, Branches, 8736, baseMVA)
        branches = Branches(
            data[:keys], data[:f_bus], data[:t_bus], data[:rate_a], data[:rate_b], data[:r], 
            data[:x], data[:b_fr], data[:b_to], data[:g_fr], data[:g_to], data[:shift], 
            data[:angmin], data[:angmax], data[:transformer], data[:tap], data[:λ_updn], data[:μ_updn], data[:status])
    end

    if has[:shunts]
        data = BaseModule.container(network, Shunts)
        shunts = Shunts(data[:keys], data[:buses], data[:bs], data[:gs], data[:status])
    else
        shunts = Shunts(Int[], Int[], Float32[], Float32[], Vector{Bool}())
    end

    if has[:generators]
        data = BaseModule.container(network, Generators)
        generators = Generators{8736,1,Hour}(
            data[:keys], data[:buses], data[:pg], data[:qg], data[:vg], data[:pmax], data[:pmin], 
            data[:qmax], data[:qmin], data[:mbase], data[:cost], data[:λ_updn], data[:μ_updn], data[:status])
    end

    if has[:loads]
        dict_timeseries, dict_core = BaseModule.extract(ReliabilityDataDir, files, Loads, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        data = BaseModule.container(dict_core, dict_timeseries, network, Loads, 8736, baseMVA)
        loads = Loads{8736,1,Hour}(data[:keys], data[:buses], data[:pd], data[:qd], data[:cost], data[:status])
    end

    if has[:storages]
    else
        storages = Storages{8736,1,Hour}(
            Int[], Int[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], 
            Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float64[], Float64[], Vector{Bool}())
    end

    generatorstorages = GeneratorStorages{8736,1,Hour}(
        Int[], Int[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], Float32[], 
        Array{Float32}(undef, 0, N), Array{Float32}(undef, 0, N), Array{Float32}(undef, 0, N), Float64[], Float64[], Vector{Bool}()
    )

    cd(CurrentDir)
    BaseModule._check_consistency(network, buses, loads, branches, shunts, generators, storages)
    BaseModule._check_connectivity(network, buses, loads, branches, shunts, generators, storages)

    arcs = BaseModule.Arcs(branches, buses.keys, length(buses), length(branches))
    ref_buses = BaseModule.slack_buses(buses)

    RBTS = CompositeAdequacy.SystemModel(loads, generators, storages, generatorstorages, buses, branches, shunts, arcs, ref_buses, baseMVA)

end

import .RTS
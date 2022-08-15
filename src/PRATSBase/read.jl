"""
    SystemModel(filename::String)

Load a `SystemModel` from an appropriately-formatted XLSX file on disk.
"""
function SystemModel(RawFile::String, ReliabilityDataDir::String)

    CurrentDir = pwd()
    N = 8760                                                    #timestep_count
    L = 1                                                       #timestep_length
    T = timeunits["h"]                                          #timestep_unit
    P = powerunits["MW"]
    E = energyunits["MWh"]
    V = voltageunits["kV"]
    start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))
    timestamps = range(start_timestamp, length=N, step=T(L))::StepRange{DateTime, Hour}
    assets = Vector{Any}()
    files = readdir(ReliabilityDataDir; join=false)
    cd(ReliabilityDataDir)
    network = PRATSBase.BuildNetwork(RawFile, N, L, T, P, E, V)  #Previously BuildData
    
    for asset in [Generators, Loads, Branches]
    
        dictionary_timeseries, dictionary_core = extract(ReliabilityDataDir, files, asset, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        container_key = [i for i in keys(dictionary_timeseries)]
        key_order = sortperm(container_key)
        #container_key_core = Vector{Int64}()#key_order_core = Vector{Int64}()#container_bus = Vector{Int64}()#container_data = Vector{Vector{Float16}}()
        #container_category = Vector{String}()#container_λ = Vector{Float32}()#container_μ = Vector{Float32}()
        push!(assets, container(container_key, key_order, dictionary_core, dictionary_timeseries, network, asset))
    end
    
    storages = Storages{N,L,T,P,E}(
        Int[], Int[], String[],
        zeros(Float16, 0, N), zeros(Float16, 0, N), zeros(Float16, 0, N),
        Float32[], Float32[], Float32[],
        Float32[], Float32[])
    
    generatorstorages = GeneratorStorages{N,L,T,P,E}(
        Int[], Int[], String[],
        zeros(Float16, 0, N), zeros(Float16, 0, N), zeros(Float16, 0, N),
        Float32[], Float32[], Float32[],
        zeros(Int, 0, N), zeros(Float16, 0, N), zeros(Float16, 0, N),
        Float32[], Float32[])
    
    cd(CurrentDir)
    return SystemModel(assets[1], assets[2], storages, generatorstorages, assets[3], network, timestamps)    

end
"""
    SystemModel(filename::String)

Load a `SystemModel` from appropriately-formatted XLSX and PSSE RAW files on disk.
"""
function SystemModel(RawFile::String, ReliabilityDataDir::String, N::Int)

    CurrentDir = pwd()
    #N = 8760                                                    #timestep_count
    L = 1                                                       #timestep_length
    T = timeunits["h"]                                          #timestep_unit
    U = perunit["pu"]
    #P = powerunits["MW"]
    #E = energyunits["MWh"]
    #V = voltageunits["kV"]
    start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))
    timestamps = range(start_timestamp, length=N, step=T(L))::StepRange{DateTime, Hour}
    assets = Vector{Any}()
    files = readdir(ReliabilityDataDir; join=false)
    cd(ReliabilityDataDir)
    network = PRATSBase.BuildNetwork(RawFile, N, U)  #Previously BuildData
    
    for asset in [Generators, Loads, Branches]
    
        dictionary_timeseries, dictionary_core = extract(ReliabilityDataDir, files, asset, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
        container_key = [i for i in keys(dictionary_timeseries)]
        key_order = sortperm(container_key)
        #container_key_core = Vector{Int64}()#key_order_core = Vector{Int64}()#container_bus = Vector{Int64}()#container_data = Vector{Vector{Float16}}()
        #container_category = Vector{String}()#container_λ = Vector{Float32}()#container_μ = Vector{Float32}()
        push!(assets, container(container_key, key_order, dictionary_core, dictionary_timeseries, network, asset, L, T))
    end
    
    storages = Storages{N,L,T,U}(
        Int[], Int[], zeros(Float16, 0, N),
        Float32[], Float32[], Float32[])
    
    generatorstorages = GeneratorStorages{N,L,T,U}(
        Int[], Int[],
        zeros(Float16, 0, N), Float32[],
        zeros(Int, 0, N), zeros(Float16, 0, N), zeros(Float16, 0, N),
        Float32[], Float32[])
    
    cd(CurrentDir)



    return SystemModel(assets[1], assets[2], storages, generatorstorages, assets[3], network, timestamps)    

end

# function check_limits()
# @assert network_data["gen"][string(i)]["pg"] <= network_data["gen"][string(i)]["pmax"] "Generator Pmax violated"
# end
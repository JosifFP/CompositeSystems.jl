#using Pkg
#Pkg.develop(PackageSpec(path="C:/Users/jfiguero/.julia/dev/ContingencySolver"))
#using PRATS, HDF5, Dates, TimeZones, Test, CSV, DataFrames, XLSX, PRAS, ContingencySolver
#using PRAS

using PRATS, Reexport, XLSX, DataFrames, Dates, TimeZones
using ContingencySolver


## Build System SystemModel


networkfile = "test/data/RTS.raw"
loadfile = "test/data/rts_Load.xlsx"
studycase = [networkfile, loadfile]
data = ContingencySolver.build_data(studycase[1])


#build_system_model
    f = Dict{Symbol,Any}()
    f[:total_load] = zeros(Int64,N)
    f[:loads] = XLSX.readtable(studycase[2], "loads")
    f[:generators] = XLSX.readtable(studycase[2], "generators")
    f[:regions] = string.(XLSX.readtable(studycase[2], "regions")[1][1])
    generators = Dict(f[:generators][2][i]=>f[:generators][1][i] for i in 1:length(f[:generators][2]))
    loads = Dict(f[:loads][2][i]=> Vector{Any}() for i in 1:length(f[:loads][2]))
    
    for i in 1:length(f[:loads][2])
        if f[:loads][2][i] == :time
            for n in 1:length(f[:loads][1][1])
                if typeof(f[:loads][1][1][n]) == Dates.Date
                    push!(loads[f[:loads][2][i]], DateTime(f[:loads][1][1][n]))
                else
                    push!(loads[f[:loads][2][i]],f[:loads][1][1][n])
                end
            end
        else
            loads[f[:loads][2][i]] = round.(Int64,f[:loads][1][i])
        end
        if occursin("MW",string(f[:loads][2][i])) == true
            f[:total_load]+= f[:loads][1][i]
        end
    end

    #T = timeunits["h"]
    start_timestamp = DateTime(load[:time][1])
    N = length(load[:time])
    L = hour(load[:time][2])-hour(load[:time][1])
    T = typeof(Dates.Hour(load[:time][2]-load[:time][1]))
    P = powerunits[string(f[:load][2][2])]
    E = energyunits[string(f[:load][2][2])*"h"]
    timestamps = range(start_timestamp, length=N, step=T(L))

    regions = Regions{N,P}(regionnames, Int.(read(f["regions/load"])))
    regionnames = f[:regions]
    regions = Regions{N,P}(regionnames, load[Symbol(P)])
    regions = Regions{N,P}(regionnames, load)
    a = reshape(b, (8760,1))
    b =load[:MW]
    regionlookup = Dict(n=>i for (i, n) in enumerate(regionnames))
    n_regions = length(regions)

    load = reshape(load[:MW],size(load[:MW]))
    #
    gen_names = gen[:name]
    gen_categories = gen[:category]
    gen_regionnames = gen[:region]
    gen_regions = 

a=Dict(f[:gen][2][i]=>f[:gen][1][i] for i in 1:length(f[:gen][2]))

    col = getindex.(:name, f[:gen])
    NamedTuple{f[:gen][2]}(f[:gen][1])

    gen_regions = getindex.(Ref(regionlookup), gen_regionnames)
    region_order = sortperm(gen_regions)

    generators = Generators{N,L,T,P}(
        gen_names[region_order], gen_categories[region_order],
        Int.(read(f["generators/capacity"]))[region_order, :],
        read(f["generators/failureprobability"])[region_order, :],
        read(f["generators/repairprobability"])[region_order, :]
    )



    ##############################
        #From SystemModel function
        regions = Regions{N,P}(["Region"], reshape(Int64.(load[Symbol(P)]), 1, :))
        interfaces = Interfaces{N,P}(Int[], Int[], Matrix{Int}(undef, 0, N), Matrix{Int}(undef, 0, N))
        region_gen_idxs = [1:length(generators)]
        region_stor_idxs = [1:length(storages)]
        region_genstor_idxs = [1:length(generatorstorages)]
        lines = Lines{N,L,T,P}(String[], String[], Matrix{Int}(undef, 0, N), Matrix{Int}(undef, 0, N), Matrix{Float64}(undef, 0, N), Matrix{Float64}(undef, 0, N))
        interface_line_idx = UnitRange{Int}[]
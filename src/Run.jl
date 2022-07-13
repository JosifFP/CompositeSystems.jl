
#********************************************************************************************************************************
#Create files to import PRATS data
#********************************************************************************************************************************
using PRATS
using PRATS.PRATSBase

#Required directories and files to import
RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
InputData = ["branches"; "generators"; "loads"]

network, ref, ReliabilityDataDir = PRATSBase.FileGenerator(RawFile, InputData)



#********************************************************************************************************************************
#Import PRATS data
#********************************************************************************************************************************
using PRATS
using PRATS.PRATSBase
using XLSX
import Dates
import Dates: DateTime, Date, Time
import BenchmarkTools: @btime

RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
network = PRATSBase.BuildNetwork(RawFile)
ref = Dict{Symbol, Any}()
ref[:load] = Dict(i => network.load[string(i)] for i in 1:length(keys(network.load)))
ref[:gen] = Dict(i => network.gen[string(i)] for i in 1:length(keys(network.gen)))
ref[:storage] = Dict(i => network.storage[string(i)] for i in 1:length(keys(network.storage)))
ref[:branch] = Dict(i => network.branch[string(i)] for i in 1:length(keys(network.branch)))

#parameters
start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))
N = 8760                                                    #timestep_count
L = 1                                                       #timestep_length
T = timeunits["h"]                                          #timestep_unit
P = powerunits["MW"]
E = energyunits["MWh"]


#function LoadingInputData(FolderDir::String)

files = readdir(ReliabilityDataDir; join=false)
cd(ReliabilityDataDir)
const data  = Vector{Any}()
const column_labels = Vector{Symbol}()
const timestamps = range(start_timestamp, length=N, step=T(L))::StepRange{DateTime, Hour}

D_loads = extract(files, "loads", data, column_labels)
D_generators =  extract(files, "generators", data, column_labels)
D_branches = extract(files, "branches", data, column_labels)
D_storages = extract(files, "storages", data, column_labels)
D_generatorstorages = extract(files, "generatorstorages", data, column_labels)

#empty_storages = isempty(D_storages)
#empty_branches = isempty(D_branches)

if isempty(D_loads) error("Load data must be provided") end
#if isempty(D_generators) || isempty(D_generatorstorages) error("Generator or generator storage data (or both) must be provided") end
@assert length(D_loads) == length(ref[:load])

container_key = [i for i in keys(D_loads)]
p = sortperm(container_key)
container_bus = [ref[:load][i]["load_bus"] for i in keys(D_loads)]
container_data = [D_loads[i] for i in keys(D_loads)]

PRATS.Loads{N,L,T,P}(container_key[p], container_bus[p], reduce(vcat,transpose.(container_data[p])))

PRATS.Loads

buses = Buses{N,P}(string.(f[:buses]), copy(transpose(repeat(f[:total_load],1,2))))


buslookup = Dict(n=>i for (i, n) in enumerate(string.(keys(D_loads))))


if size(string.(f[:buses])) == (1,)
    buses = Buses{N,P}(string.(f[:buses]), reshape(f[:total_load], 1, :))
else
    buses = Buses{N,P}(string.(f[:buses]), copy(transpose(repeat(f[:total_load],1,2))))
end

if isempty(D_generators)
    generators = Generators{N,L,T,P}(String[], String[], zeros(Int, 0, N), zeros(Float64, 0), zeros(Float64, 0))
    bus_gen_idxs = fill(1:0, length(buses))       
else
    gen_names =  string.(D_generators[:name])
    gen_categories = string.(D_generators[:category])
    gen_buses = getindex.(Ref(buslookup), string.(D_generators[:bus]))
    bus_order = sortperm(gen_buses)
    gen_capacity = repeat(round.(Int, D_generators[:Pmax]), 1, N)
    failureprobability = float.(D_generators[:failureprobability])/N
    repairprobability = float.(D_generators[:repairprobability])/N
    generators = Generators{N,L,T,P}(
        gen_names[bus_order], gen_categories[bus_order],
        gen_capacity[bus_order, :],
        failureprobability[bus_order],
        repairprobability[bus_order]
    )

    bus_gen_idxs = makeidxlist(gen_buses[bus_order], length(buses))
end




function extract(files::Vector{String}, assettype::String, data::Vector{Any}, column_labels::Vector{Symbol})

    if in(files).(assettype*".xlsx") == true
        XLSX.openxlsx(ReliabilityDataDir*"/"*assettype*".xlsx", enable_cache=false) do io
            for i in 1:XLSX.sheetcount(io)
                if XLSX.sheetnames(io)[i]=="time series capacity" 
                    data, column_labels = XLSX.readtable(assettype*".xlsx", XLSX.sheetnames(io)[i])
                end
            end
        end
    else
        if assettype == "loads" || assettype == "generators"
            error("file $assettype.xlsx not found in $ReliabilityDataDir/ directory")
        end
    end

    return Dict(parse(Int, String(column_labels[i])) => Float16.(data[i]) for i in 2:length(column_labels))
end






#function DataGenerator(RawFile::String, InputData::Vector{String},
#    start_timestamp::DateTime, N::Integer, L::Integer, T::Type{<:Period})


#P = powerunits["MW"]
#E = energyunits["MWh"]
#timestamps = range(start_timestamp, length=N, step=T(L))
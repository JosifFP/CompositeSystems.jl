
#********************************************************************************************************************************
#Create files to import PRATS data
#********************************************************************************************************************************
using PRATS
using PRATS.PRATSBase

#Required directories and files to import
RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
InputData = ["Branches"; "Generators"; "Loads"]

#create directories and files to import
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
N = 8760                                                    #timestep_count
L = 1                                                       #timestep_length
T = timeunits["h"]                                          #timestep_unit
P = powerunits["MW"]
E = energyunits["MWh"]
V = voltageunits["kV"]

network = PRATSBase.BuildNetwork(RawFile, N, L, T, P, E, V)  #Previously BuildData

#ref = Dict{Symbol, Any}()
#ref[:load] = Dict(i => network.load[string(i)] for i in 1:length(keys(network.load)))
#ref[:gen] = Dict(i => network.gen[string(i)] for i in 1:length(keys(network.gen)))
#ref[:storage] = Dict(i => network.storage[string(i)] for i in 1:length(keys(network.storage)))
#ref[:branch] = Dict(i => network.branch[string(i)] for i in 1:length(keys(network.branch)))
#ref[:baseMVA] = network.baseMVA

#parameters
start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))


#function LoadingInputData(FolderDir::String)
files = readdir(ReliabilityDataDir; join=false)
cd(ReliabilityDataDir)
const timestamps = range(start_timestamp, length=N, step=T(L))::StepRange{DateTime, Hour}

#empty_storages = isempty(D_storages)
#empty_branches = isempty(D_branches)

#if isempty(D_generators) || isempty(D_generatorstorages) error("Generator or generator storage data (or both) must be provided") end
#function asset_data(files::Vector{String}, asset::String, data::Vector{Any}, column_labels:: Vector{Symbol})

assets = Vector{Any}()

for asset in [PRATS.Generators, PRATS.Loads, PRATS.Branches]

    dictionary_timeseries, dictionary_core = extract(ReliabilityDataDir, files, asset, [Vector{Symbol}(), Vector{Integer}()], [Vector{Symbol}(), Vector{Any}()])
    container_key = [i for i in keys(dictionary_timeseries)]
    key_order = sortperm(container_key)
    #container_key_core = Vector{Int64}()#key_order_core = Vector{Int64}()#container_bus = Vector{Int64}()#container_data = Vector{Vector{Float16}}()
    #container_category = Vector{String}()#container_λ = Vector{Float32}()#container_μ = Vector{Float32}()
    push!(assets, container(container_key, key_order, dictionary_core, dictionary_timeseries, network, asset))
end



#***************************************************************************************************
#function DataGenerator(RawFile::String, InputData::Vector{String}, start_timestamp::DateTime, N::Integer, L::Integer, T::Type{<:Period})
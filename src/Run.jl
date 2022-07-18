
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

#THIS IS SPECIFIED INSIDE
L = 1                                                       #timestep_length
T = timeunits["h"]                                          #timestep_unit
P = powerunits["MW"]
E = energyunits["MWh"]


#function LoadingInputData(FolderDir::String)

files = readdir(ReliabilityDataDir; join=false)
cd(ReliabilityDataDir)
const timestamps = range(start_timestamp, length=N, step=T(L))::StepRange{DateTime, Hour}

function extract(files::Vector{String}, assettype::String, container_1::Vector{Vector}, container_2::Vector{Vector{Any}})

    if in(files).(assettype*".xlsx") == true
        XLSX.openxlsx(ReliabilityDataDir*"/"*assettype*".xlsx", enable_cache=false) do io
            for i in 1:XLSX.sheetcount(io)
                if XLSX.sheetnames(io)[i] == "time series capacity" 
                    container_1[2], container_1[1] = XLSX.readtable(assettype*".xlsx", XLSX.sheetnames(io)[i])
                elseif XLSX.sheetnames(io)[i] == "core"
                    container_2[2], container_2[1] = XLSX.readtable(assettype*".xlsx",XLSX.sheetnames(io)[i])
                end
            end
        end
    else
        if assettype == "loads" || assettype == "generators"
            error("file $assettype.xlsx not found in $ReliabilityDataDir/ directory")
        end
    end

    return Dict(parse(Int, String(container_1[1][i])) => Float16.( container_1[2][i]) for i in 2:length(container_1[1])), 
    Dict(container_2[1][i] => container_2[2][i] for i in 1:length(container_2[1]))

end

#empty_storages = isempty(D_storages)
#empty_branches = isempty(D_branches)

#if isempty(D_generators) || isempty(D_generatorstorages) error("Generator or generator storage data (or both) must be provided") end
#function asset_data(files::Vector{String}, asset::String, data::Vector{Any}, column_labels:: Vector{Symbol})

assets = ["generators", "storages", "generatorstorages", "loads", "branches"]

for asset in assets

    dictionary_timeseries, dictionary_core = extract(files, asset, [Vector{Symbol}(), Vector{Integer}()], [Vector{Symbol}(), Vector{Any}()])
    container_key = [i for i in keys(dictionary_timeseries)]
    key_order = sortperm(container_key)
    container_key_core = Int.(dictionary_core[:key])
    key_order_core = sortperm(container_key_core)
    container_bus = []
    container_data = []
    
    if asset == "loads"
        
        if isempty(dictionary_timeseries) error("Load data must be provided") end
        @assert length(dictionary_timeseries) == length(ref[:load])
    
        container_bus = [ref[:gen][i]["gen_bus"] for i in keys(dictionary_timeseries)]
        container_data = [dictionary_timeseries[i] for i in keys(dictionary_timeseries)]
    
        PRATS.Loads{N,L,T,P}(container_key[key_order], container_bus[key_order], reduce(vcat,transpose.(container_data[key_order])))
    
    elseif asset == "generators"
    
    
    
    end

end


dictionary_timeseries, dictionary_core = extract(files, "generators", [Vector{Symbol}(), Vector{Integer}()], [Vector{Symbol}(), Vector{Any}()])
container_key = [i for i in keys(dictionary_timeseries)]
key_order = sortperm(container_key)
container_key_core = Int.(dictionary_core[:key])
key_order_core = sortperm(container_key_core)
#***************************************************************************************************

if length(container_key) != length(container_key_core)
    for i in container_key_core
        if in(container_key).(i) == false
            println("hello")
            setindex!(dictionary_timeseries, [ref[:gen][i]["pmax"]*network.baseMVA for k in 1:N], i)
        end
    end
    container_key = [i for i in keys(dictionary_timeseries)]
    key_order = sortperm(container_key)
    @assert length(container_key) == length(container_key_core)
end

container_bus = Int.(tmp[:,2])
container_data = [dictionary_timeseries[i] for i in keys(dictionary_timeseries)]
container_bus[key_order_core]
container_data[key_order_core]

container_category = String.(values(dictionary_core[:category]))
container_category[container_key_core]

container_λ = Float16.(values(dictionary_core[Symbol("failurerate [f/year]")]))
container_μ = Float16.(values(dictionary_core[Symbol("repairrate [r/year]")])) 


reduce(vcat,transpose.(container_data[key_order_1]))

PRATS.Generators{N,L,T,P}(container_key[key_order], container_bus[key_order], , reduce(vcat,transpose.(container_data[key_order])))
new{N,L,T,P}(Int.(keys), Int.(buses), string.(categories), capacity, λ, μ)









#function DataGenerator(RawFile::String, InputData::Vector{String},
#    start_timestamp::DateTime, N::Integer, L::Integer, T::Type{<:Period})

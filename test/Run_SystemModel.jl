
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
import BenchmarkTools: @btime
using Dates

RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"

sys = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
# sys.generators
# sys.storages
# sys.branches
# sys.timestamps


#********************************************************************************************************************************
#MCS
#********************************************************************************************************************************
using Distributions
using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using Base.Threads


RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)

method = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())

#threads = Base.Threads.nthreads()
threads = 1
sampleseeds = Channel{Int}(2*threads)

results = PRATS.CompositeAdequacy.resultchannel(method, resultspecs, threads)
@async PRATS.CompositeAdequacy.makeseeds(sampleseeds, method.nsamples)

#dispatchproblem = ContingencyAnalysis(system)
sequences = UpDownSequence(system)
systemstate = SystemState(system)

# sequences.Up_gens
# sequences.Up_stors
# sequences.Up_genstors
#system.network.bus

#sequences.Up_branches
#x = 1:8760
#using Plots
#plot(x,sequences.Up_branches[6,:])

recorders = accumulator.(system, method, resultspecs)
rng = PRATS.CompositeAdequacy.Philox4x((0, 0), 10)

PRATS.CompositeAdequacy.seed!(rng, (method.seed, 1))  #using the same seed for entire period.
#PRATS.CompositeAdequacy.initialize!(rng, systemstate, system, sequences) #creates the up/down sequence for each device.

N =8760

PRATS.CompositeAdequacy.initialize_availability!(rng, sequences.Up_gens, system.generators, N)
PRATS.CompositeAdequacy.initialize_availability!(rng, sequences.Up_stors, system.storages, N)
PRATS.CompositeAdequacy.initialize_availability!(rng, sequences.Up_genstors, system.generatorstorages, N)
PRATS.CompositeAdequacy.initialize_availability!(rng, sequences.Up_branches, system.branches, N)
PRATS.CompositeAdequacy.fill!(systemstate.stors_energy, 0)
PRATS.CompositeAdequacy.fill!(systemstate.genstors_energy, 0)

x = 1:8760
using Plots
plot(x,sequences.Up_branches[10,:])

t=1


advance!(sequences, systemstate, dispatchproblem, system, t)
solve!(dispatchproblem, systemstate, system, t)
foreach(recorder -> record!(
    recorder, system, systemstate, dispatchproblem, s, t
    ), recorders)


#shortfalls, availability = PRATS.assess(sys, simspec, resultspecs...)
#lole, eue = PRATS.LOLE(shortfalls), PRATS.EUE(shortfalls)

#***************************************************************************************************
#function DataGenerator(RawFile::String, InputData::Vector{String}, start_timestamp::DateTime, N::Int, L::Int, T::Type{<:Period})
#ref = Dict{Symbol, Any}()
#ref[:load] = Dict(i => network.load[string(i)] for i in 1:length(keys(network.load)))
#ref[:gen] = Dict(i => network.gen[string(i)] for i in 1:length(keys(network.gen)))
#ref[:storage] = Dict(i => network.storage[string(i)] for i in 1:length(keys(network.storage)))
#ref[:branch] = Dict(i => network.branch[string(i)] for i in 1:length(keys(network.branch)))
#ref[:baseMVA] = network.baseMVA



#***************************************************************************************************
#********************************************************************************************************************************
#Import PRATS data
#********************************************************************************************************************************
using PRATS
using PRATS.PRATSBase
import BenchmarkTools: @btime
using Dates

RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"

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

asset = Generators
    
dictionary_timeseries, dictionary_core = extract(ReliabilityDataDir, files, asset, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
container_key = [i for i in keys(dictionary_timeseries)]
key_order = sortperm(container_key)

#push!(assets, container(container_key, key_order, dictionary_core, dictionary_timeseries, network, asset))

ref = Dict(i => network.gen[string(i)] for i in 1:length(keys(network.gen)))
tmp = sort([[i, gen["gen_bus"]] for (i,gen) in ref], by = x->x[1])
container_key_core = Int64.(reduce(vcat, tmp')[:,1])
key_order_core = sortperm(container_key_core)

if length(container_key) != length(container_key_core)
    for i in container_key_core
        if in(container_key).(i) == false
            setindex!(dictionary_timeseries, Float16.([ref[i]["pmax"]*network.baseMVA for k in 1:N]), i)
        end
    end
    container_key = [i for i in keys(dictionary_timeseries)]
    key_order = sortperm(container_key)
    @assert length(container_key) == length(container_key_core)
end

container_data = [Float16.(dictionary_timeseries[i]) for i in keys(dictionary_timeseries)]
container_bus = Int64.(reduce(vcat, tmp')[:,2])
container_category = String.(values(dictionary_core[:category]))
container_λ = Float32.(values(dictionary_core[Symbol("failurerate[f/year]")]))
container_μ = Vector{Float32}(undef, length(values(dictionary_core[Symbol("repairtime[hrs]")])))
for i in 1:length(values(dictionary_core[Symbol("repairtime[hrs]")]))
    if values(dictionary_core[Symbol("repairtime[hrs]")])[i]!=0.0
        container_μ[i] = Float32.(8760/values(dictionary_core[Symbol("repairtime[hrs]")])[i])
    else
        container_μ[i] = 0.0
    end
end

Generators{N,L,T,P}(container_key_core[key_order_core], container_bus[key_order_core], container_category[key_order_core], 
    reduce(vcat,transpose.(container_data[key_order])), container_λ[key_order_core], container_μ[key_order_core])

    key_order_core
length(container_data)
@show bus_gen_idxs = makeidxlist(container_key_core[key_order_core], length(container_bus))
container_bus[key_order_core]
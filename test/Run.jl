
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

#dispatchproblem = DispatchProblem(system)
sequences = UpDownSequence(system)

systemstate = SystemState(system)

# sequences.Up_gens
# sequences.Up_stors
# sequences.Up_genstors
#system.network.bus

sequences.Up_branches
x = 1:8760
using Plots
plot(x,sequences.Up_branches[6,:])

recorders = accumulator.(system, method, resultspecs)
rng = PRATS.CompositeAdequacy.Philox4x((0, 0), 10)

PRATS.CompositeAdequacy.seed!(rng, (method.seed, 1))  #using the same seed for entire period.
#PRATS.CompositeAdequacy.initialize!(rng, systemstate, system, sequences) #creates the up/down sequence for each device.

N =8760
xx = PRATS.CompositeAdequacy.initialize_availability!(rng, sequences.Up_branches, system.branches, N)
x = 1:8760
using Plots
plot(x,xx[6,:])

PRATS.CompositeAdequacy.initialize_availability!(rng, sequences.Up_stors, system.storages, N)
PRATS.CompositeAdequacy.initialize_availability!(rng, sequences.Up_genstors, system.generatorstorages, N)
PRATS.CompositeAdequacy.initialize_availability!(rng, sequences.Up_branches, system.branches, N)
PRATS.CompositeAdequacy.fill!(systemstate.stors_energy, 0)
PRATS.CompositeAdequacy.fill!(systemstate.genstors_energy, 0)





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
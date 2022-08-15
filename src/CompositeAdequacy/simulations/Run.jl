
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
using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime
import Base: -, broadcastable, getindex, merge!
#import Base.Threads: nthreads, @spawn
import Dates: DateTime, Period
import Decimals: Decimal, decimal
import Distributions: DiscreteNonParametric, probs, support, Exponential
import OnlineStatsBase: EqualWeight, fit!, Mean, value, Variance
import OnlineStats: Series
import Printf: @sprintf
import Random: AbstractRNG, rand, seed!
import Random123: Philox4x
import StatsBase: mean, std, stderror
import TimeZones: ZonedDateTime, @tz_str

RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)

method = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())

include("sequentialmontecarlo/SystemState.jl")
include("sequentialmontecarlo/utils.jl")

    #threads = Base.Threads.nthreads()
    threads = 1
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    @async makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    assess(system, method, sampleseeds, results, resultspecs...)
    finalize(results, system)
















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
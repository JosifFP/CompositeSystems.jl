
using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
import BenchmarkTools: @btime
using Dates

RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"



CurrentDir = pwd()
    #N = 8760                                                    #timestep_count
    L = 1                                                       #timestep_length
    T = timeunits["h"]                                          #timestep_unit
    U = perunit["pu"]
    N=365
    #P = powerunits["MW"]
    #E = energyunits["MWh"]
    #V = voltageunits["kV"]
    start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))
    timestamps = range(start_timestamp, length=N, step=T(L))::StepRange{DateTime, Hour}
    assets = Vector{Any}()
    files = readdir(ReliabilityDataDir; join=false)
    cd(ReliabilityDataDir)
    network = PRATSBase.BuildNetwork(RawFile, N, L, T, U)  #Previously BuildData

    asset = Loads
    dictionary_timeseries, dictionary_core = extract(ReliabilityDataDir, files, asset, [Vector{Symbol}(), Vector{Int}()], [Vector{Symbol}(), Vector{Any}()])
    container_key = [i for i in keys(dictionary_timeseries)]
    key_order = sortperm(container_key)

    if isempty(dictionary_timeseries) error("Load data must be provided") end

    ref = Dict(i => network.load[string(i)] for i in 1:length(keys(network.load)))
    @assert length(dictionary_timeseries) == length(ref)

    keys(dictionary_core)


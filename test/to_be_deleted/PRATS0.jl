module PRATS

const PRATS_VERSION = "v0.1.0"
using MinCostFlows

import XLSX, Dates, HDF5, TimeZones, Base
import Base: -, broadcastable, getindex, merge!, length
import Base.Threads: nthreads, @spawn
import Dates: @dateformat_str, AbstractDateTime, DateTime,
              Period, Minute, Hour, Day, Year, Date, hour
import HDF5: attributes, File, Group, Dataset, Datatype, dataspace,
             h5open, create_group, create_dataset,
             h5t_create, h5t_copy, h5t_insert, h5t_set_size, H5T_COMPOUND,
             hdf5_type_id, h5d_write, H5S_ALL, H5P_DEFAULT
import TimeZones: TimeZone, ZonedDateTime, @tz_str
import Decimals: Decimal, decimal
import Distributions: DiscreteNonParametric, probs, support
import OnlineStatsBase: EqualWeight, fit!, Mean, value, Variance
import OnlineStats: Series
import Printf: @sprintf
import Random: AbstractRNG, rand, seed!
import Random123: Philox4x
import StatsBase: mean, std, stderror

abstract type ReliabilityMetric end
abstract type SimulationSpec end
abstract type ResultSpec end
abstract type ResultAccumulator{S<:SimulationSpec,R<:ResultSpec} end
abstract type Result{
    N, # Number of timesteps simulated
    L, # Length of each simulation timestep
    T <: Period, # Units of each simulation timestep
} end


#Root submodule
export
    # System assets
    Regions, Interfaces, AbstractAssets, Generators, Storages, GeneratorStorages, Lines,
    # Units
    Period, Minute, Hour, Day, Year,
    PowerUnit, kW, MW, GW, TW,
    EnergyUnit, kWh, MWh, GWh, TWh,
    unitsymbol, conversionfactor, powertoenergy, energytopower,
    # Main data structure
    SystemModel,# savemodel
    
    # PRE submoduleexport
    assess,
    # Metrics
    ReliabilityMetric, LOLE, EUE, val, stderror,
    # Simulation specifications
    SequentialMonteCarlo,
    # Result specifications
    Shortfall, ShortfallSamples,
    GeneratorAvailability, StorageAvailability, GeneratorStorageAvailability, LineAvailability
    # Convenience re-exports
    MeanVariance = Series{ Number, Tuple{Mean{Float64, EqualWeight}, Variance{Float64, Float64, EqualWeight}}}

    DispatchProblem, SystemState, accumulator
#

include("core/units.jl")
include("core/assets.jl")
include("core/SystemModel.jl")
include("core/utils.jl")
include("core/read.jl")

include("CompositeAdequacy/metrics.jl")
include("CompositeAdequacy/results/results.jl")
include("CompositeAdequacy/simulations/simulations.jl")
include("CompositeAdequacy/simulations/sequentialmontecarlo/SequentialMonteCarlo.jl")
include("CompositeAdequacy/simulations/sequentialmontecarlo/DispatchProblem.jl")
include("CompositeAdequacy/utils.jl")

end

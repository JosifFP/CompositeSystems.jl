module PRATS

using Reexport
const PRATS_VERSION = "v0.1.0"

@reexport module PRATSBase
import Base.Broadcast: broadcastable
import XLSX
import Dates: @dateformat_str, AbstractDateTime, DateTime,
    Period, Minute, Hour, Day, Year, Date, hour
import HDF5: attributes, File, Group, Dataset, Datatype, dataspace,
    h5open, create_group, create_dataset,
    h5t_create, h5t_copy, h5t_insert, h5t_set_size, H5T_COMPOUND,
    hdf5_type_id, h5d_write, H5S_ALL, H5P_DEFAULT
import TimeZones: TimeZone, ZonedDateTime
import StatsBase: mean, std, stderror

abstract type ReliabilityMetric end
abstract type SimulationSpec end
abstract type ResultSpec end
abstract type ResultAccumulator{S<:SimulationSpec,R<:ResultSpec} end
abstract type Result{
    N, # Number of timesteps simulated
    L, # Length of each simulation timestep
    T<:Period, # Units of each simulation timestep
} end

export
    # System assets
    Buses, Interfaces, AbstractAssets, Generators, Storages, GeneratorStorages, Branches,
    # Units
    Period, Minute, Hour, Day, Year,
    PowerUnit, kW, MW, GW, TW,
    EnergyUnit, kWh, MWh, GWh, TWh,
    VoltageUnit,kV,
    PerUnit, pu,
    unitsymbol, conversionfactor, powertoenergy, energytopower,
    # Main data structure
    SystemModel# savemodel


import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
__init__() = Memento.register(_LOGGER)

"Suppresses information and warning messages output"
function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.")
    Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
    Memento.setlevel!(Memento.getlogger(PowerModels), "error")
    Memento.setlevel!(Memento.getlogger(PRATS), "error")
end

include("core/units.jl")
include("core/assets.jl")
include("core/SystemModel.jl")
include("core/utils.jl")
include("core/read.jl")
end

include("CompositeAdequacy/CompositeAdequacy.jl")
include("SystemRepresentation/Network.jl")

end

module PRATS

using Reexport
const PRATS_VERSION = "v0.1.0"

@reexport module PRATSBase
    import Base.Broadcast: broadcastable
    import XLSX
    import Dates: @dateformat_str, AbstractDateTime, DateTime,
        Period, Minute, Hour, Day, Year, Date, hour
    import TimeZones: TimeZone, ZonedDateTime
    import StatsBase: mean, std, stderror

    export
        # System assets
        Buses, AbstractAssets, Generators, Storages, GeneratorStorages, Branches,
        # Units
        Period, Minute, Hour, Day, Year,
        PowerUnit, kW, MW, GW, TW,
        EnergyUnit, kWh, MWh, GWh, TWh,
        VoltageUnit,kV,
        PerUnit, pu,
        unitsymbol, conversionfactor, powertoenergy, energytopower,
        # Main data structure
        SystemModel# savemodel

    include("core/units.jl")
    include("core/assets.jl")
    include("core/SystemModel.jl")
    include("core/utils.jl")
    include("core/read.jl")

end

import InfrastructureModels, PowerModels
import PowerModels:  parse_matpower, parse_psse
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
__init__() = Memento.register(_LOGGER)

"Suppresses information and warning messages output"
function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.")
    Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
    Memento.setlevel!(Memento.getlogger(PowerModels), "error")
    Memento.setlevel!(Memento.getlogger(PRATS), "error")
end

include("CompositeAdequacy/CompositeAdequacy.jl")
include("SystemRepresentation/TransmissionSystem.jl")

end

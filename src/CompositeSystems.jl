module CompositeSystems

using Reexport
const CompositeSystems_VERSION = "v0.1.0"

import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)

"Suppresses information and warning messages output"
function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.")
    Memento.setlevel!(Memento.getlogger(CompositeSystems), "info", recursive=false)
end

include("core/BaseModule.jl")
include("optimization/OPF.jl")
include("CompositeAdequacy/CompositeAdequacy.jl")
end
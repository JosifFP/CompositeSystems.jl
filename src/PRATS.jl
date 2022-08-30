module PRATS

using Reexport
const PRATS_VERSION = "v0.1.0"

import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
__init__() = Memento.register(_LOGGER)

"Suppresses information and warning messages output"
function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.")
    Memento.setlevel!(Memento.getlogger(PRATS), "info", recursive=false)
end


include("PRATSBase/PRATSBase.jl")
include("CompositeAdequacy/CompositeAdequacy.jl")


end

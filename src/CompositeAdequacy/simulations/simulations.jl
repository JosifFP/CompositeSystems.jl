Base.broadcastable(x::SimulationSpec) = Ref(x)

include("SequentialMCS/SequentialMCS.jl")
include("NonSequentialMCS/NonSequentialMCS.jl")
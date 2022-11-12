Base.broadcastable(x::SimulationSpec) = Ref(x)

include("SequentialMCS/SMCS.jl")
#include("SequentialMCS/SequentialMCS.jl")
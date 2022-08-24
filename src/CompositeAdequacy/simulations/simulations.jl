broadcastable(x::SimulationSpec) = Ref(x)

include("NoContingencies/NoContingencies.jl")
include("sequentialmontecarlo/SequentialMonteCarlo.jl")

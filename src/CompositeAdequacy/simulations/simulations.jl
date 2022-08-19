broadcastable(x::SimulationSpec) = Ref(x)

#include("convolution/Convolution.jl")
include("contingencyanalysis/PreoutagePowerFlows.jl")
include("sequentialmontecarlo/SequentialMonteCarlo.jl")

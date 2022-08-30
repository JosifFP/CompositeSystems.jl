struct PreoutagePowerFlows <: SimulationSpec

    verbose::Bool
    threaded::Bool

    PreoutagePowerFlows(;verbose::Bool=false, threaded::Bool=true) =
        new(verbose, threaded)

end
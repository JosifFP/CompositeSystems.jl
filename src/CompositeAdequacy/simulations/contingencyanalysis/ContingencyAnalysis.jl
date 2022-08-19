struct ContingencyAnalysis <: SimulationSpec

    verbose::Bool
    threaded::Bool

    ContingencyAnalysis(;verbose::Bool=false, threaded::Bool=true) =
        new(verbose, threaded)

end
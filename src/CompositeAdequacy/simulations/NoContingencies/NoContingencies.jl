include("utils.jl")


struct NoContingencies <: SimulationSpec

    verbose::Bool
    threaded::Bool

    NoContingencies(;verbose::Bool=false, threaded::Bool=true) =
        new(verbose, threaded)

end


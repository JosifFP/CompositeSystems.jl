@reexport module Network
    
    import LinearAlgebra, SparseArrays, JuMP
    import InfrastructureModels, PowerModels
    import JuMP: @variable, @constraint, @NLexpression, @NLconstraint, @objective, @expression, 
                optimize!, Model
    import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
    __init__() = Memento.register(_LOGGER)
    
    "Suppresses information and warning messages output"
    function silence()
        Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.")
        Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
        Memento.setlevel!(Memento.getlogger(PowerModels), "error")
        Memento.setlevel!(Memento.getlogger(PRATS), "error")
    end

    include("network/common.jl")
    include("network/data.jl")
    include("network/base.jl")
    include("network/ref.jl")
end
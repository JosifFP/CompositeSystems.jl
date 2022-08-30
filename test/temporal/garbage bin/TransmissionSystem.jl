@reexport module TransmissionSystem
    
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
    end

    export Network
    
    include("BuildNetwork/data.jl")
    include("BuildNetwork/ref.jl")
end
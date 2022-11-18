module PRATS

using Reexport
const PRATS_VERSION = "v0.1.0"

import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)

"Suppresses information and warning messages output"
function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.")
    Memento.setlevel!(Memento.getlogger(PRATS), "info", recursive=false)
end

include("core/BaseModule.jl")
include("optimization/OPF.jl")
include("compositeadequacy/CompositeAdequacy.jl")

end


# default setup for solvers
#nlp_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
#nlp_ws_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "mu_init"=>1e-4, "print_level"=>0)

#milp_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
#minlp_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])
#sdp_solver = JuMP.optimizer_with_attributes(SCS.Optimizer, "verbose"=>false)
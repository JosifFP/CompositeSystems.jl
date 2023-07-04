#module load gurobi
#module load julia/1.8.5
#gurobi_cl 1> /dev/null && echo Success || echo
#gurobi_cl --tokens
#julia -p 2 --threads 2
import Distributed
Distributed.@everywhere import Gurobi, JuMP, Dates, Distributed, Pkg
Distributed.@everywhere Pkg.activate(".")
Pkg.instantiate()
Distributed.@everywhere using CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    count_samples = true
)

timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
rawfile = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
method_2 = CompositeAdequacy.SequentialMCS(samples=100, seed=100, distributed=true)
shortfall_threaded,_ = CompositeSystems.assess(system, method_2, settings, resultspecs...)

Gurobi.Env()
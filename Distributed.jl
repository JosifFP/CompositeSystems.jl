#module load gurobi/10.0.2
#module load julia/1.8.5
#gurobi_cl 1> /dev/null && echo Success || echo
#gurobi_cl --tokens
#julia -p 4 --threads 2
#Distributed.nprocs()
#Base.Threads.nthreads()
import Distributed
Distributed.@everywhere using Gurobi, JuMP, Dates, Distributed, Pkg
Distributed.@everywhere Pkg.activate(".")
Distributed.@everywhere Pkg.instantiate()
Distributed.@everywhere using CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy
const GRB_ENV = Gurobi.Env()

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings_dc = CompositeSystems.Settings(;
    env = GRB_ENV,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = false
)

timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
rawfile = "test/data/RBTS/Base/RBTS.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)


method_2 = CompositeAdequacy.SequentialMCS(samples=8, seed=100, threaded=false, distributed=true)
shortfall_threaded,_ = CompositeSystems.assess(system, method_2, settings_dc, resultspecs...)
#module load gurobi/10.0.2
#module load julia/1.8.5
#gurobi_cl 1> /dev/null && echo Success || echo
#gurobi_cl --tokens
#julia -p 4 --threads 4
#Distributed.nprocs()
#Base.Threads.nthreads()

using Distributed

# instantiate and precompile environment in all processes
@everywhere begin
    using Pkg; Pkg.activate(@__DIR__)
end

Pkg.instantiate()
Pkg.precompile()

@everywhere begin
  Pkg.instantiate(); Pkg.precompile()
end

@everywhere begin
    # load dependencies
    using Gurobi, Dates, JuMP
    using CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy
end

@everywhere begin

  settings = CompositeSystems.Settings(;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = false,
    count_samples = true
  )

  timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
  rawfile = "test/data/RBTS/Base/RBTS.m"
  Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
  library = String[rawfile; Base_reliabilityfile; timeseriesfile]
  method = CompositeAdequacy.SequentialMCS(samples=20, seed=100, threaded=false, distributed=true)
  resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
end

sys = BaseModule.SystemModel(library[1], library[2], library[3])
Shortfall,_ = CompositeSystems.assess(library, sys, method, settings, resultspecs...)
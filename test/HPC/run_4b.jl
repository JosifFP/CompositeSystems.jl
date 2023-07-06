using Distributed

# instantiate and precompile environment in all processes
@everywhere begin
  using Pkg; Pkg.activate(@__DIR__)
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
        powermodel_formulation = OPF.LPACCPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = true,
        set_string_names_on_creation = false,
        #count_samples = true
    )
  
    timeseriesfile = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
    Base_reliabilityfile = "test/data/RTS_79_A/R_RTS.m"
    library = String[rawfile, Base_reliabilityfile, timeseriesfile]
    method = CompositeAdequacy.SequentialMCS(samples=15000, seed=100, threaded=true, distributed=true)
    resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
end

function run_smc(library, method, settings, resultspecs)
    hour = Dates.format(Dates.now(),"HH_MM_SS")
    current_dir = pwd()
    sys = BaseModule.SystemModel(library[1], library[2], library[3])
    new_dir = mkdir(string("RTS_AC_15000_",hour))
    total_result = CompositeSystems.assess(library, method, settings, resultspecs...)
    shortfall_threaded, util = CompositeAdequacy.finalize.(total_result, sys)
    cd(new_dir)
    CompositeAdequacy.print_results(sys, shortfall_threaded)
    CompositeAdequacy.print_results(sys, util)
    println("$(settings.powermodel_formulation)")
    cd(current_dir)
end

run_smc(library, method, settings, resultspecs)
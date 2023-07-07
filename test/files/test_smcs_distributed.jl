#To test Distributing Computing on a single machine, open a new command prompt terminal
#and paste "julia -p 3 --threads 7" where 3 could be any number of machines, and 7
#could be any number of threads per machine. If this is not done, the testsets will
#run parallel processes on a single machine using the same function for 
#distributing computing, which give us the same results as any other option with
#the same seed.

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


@testset "Sequential MCS, 1000 samples, RBTS, distributed" begin

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
        method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=true, distributed=true)
        resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
    end

    total_result = CompositeSystems.assess(library, method, settings, resultspecs...)
    system = BaseModule.SystemModel(library[1], library[2], library[3])
    shortfall_threaded, util = CompositeAdequacy.finalize.(total_result, sys)

    system_EDLC_mean = [0.0, 0.0, 1.18200, 0.0, 0.00200, 10.35400]
    system_EENS_mean = [0.0, 0.0, 10.68267, 0.0, 0.01941, 127.18585]
    system_SI_mean = [0.0, 0.0, 3.46465, 0.0, 0.00629, 41.24946]

    system_EDLC_stderror = [0.0, 0.0, 0.13081, 0.0, 0.00200, 0.45317]
    system_EENS_stderror= [0.0, 0.0, 1.66407, 0.0, 0.01941, 5.61568]
    system_SI_stderror = [0.0, 0.0, 0.53969, 0.0, 0.00629, 1.82130]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_threaded, system.buses.keys)), 
        system_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_threaded, system.buses.keys)), 
        system_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_threaded, system.buses.keys)), 
        system_SI_mean; atol = 1e-4)

    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall_threaded, system.buses.keys)), 
        system_EDLC_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall_threaded, system.buses.keys)), 
        system_EENS_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall_threaded, system.buses.keys)), 
        system_SI_stderror; atol = 1e-4)

end

@testset "Sequential MCS, 100 samples, RTS, threaded" begin

    @everywhere begin

        settings = CompositeSystems.Settings(;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = false,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = false,
            count_samples = true
        )
      
        timeseriesfile = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
        rawfile = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
        Base_reliabilityfile = "test/data/RTS_79_A/R_RTS.m"
        library = String[rawfile; Base_reliabilityfile; timeseriesfile]
        method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true, distributed=true)
        resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
    end
    
    system_EDLC_mean = [0.00, 0.00, 0.00, 0.10, 0.00, 0.00, 4.2200, 0.00, 10.1200, 0.1700, 0.00, 
    0.00, 0.00, 2.85, 0.00, 0.00, 0.00, 0.00, 0.64, 0.00, 0.00, 0.00, 0.00, 0.00]

    system_EENS_mean = [0.0000, 0.0000, 0.0000, 4.7239, 0.0000, 0.0000, 324.0319, 0.0000, 900.3531, 
    12.8916, 0.0000, 0.0000, 0.0000, 238.3064, 0.0000, 0.0000, 0.0000, 0.0000, 59.4747, 0.0000, 
    0.0000, 0.0000, 0.0000, 0.0000]

    system_SI_mean = [0.0000, 0.0000, 0.0000, 0.0995, 0.0000, 0.0000, 6.8217, 0.0000, 18.9548, 0.2714, 
    0.0000, 0.0000, 0.0000, 5.0170, 0.0000, 0.0000, 0.0000, 0.0000, 1.2521, 0.0000, 0.0000, 
    0.0000, 0.0000, 0.0000]

    system_SI_stderror = [0.0000, 0.0000, 0.0000, 0.0995, 0.0000, 0.0000, 1.5451, 0.0000, 3.8116, 0.2387, 
    0.0000, 0.0000, 0.0000, 1.5869, 0.0000, 0.0000, 0.0000, 0.0000, 0.6933, 0.0000, 0.0000, 
    0.0000, 0.0000, 0.0000]
    
    total_result = CompositeSystems.assess(library, method, settings, resultspecs...)
    system = BaseModule.SystemModel(library[1], library[2], library[3])
    shortfall_threaded, util = CompositeAdequacy.finalize.(total_result, sys)

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_threaded, system.buses.keys)), 
        system_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_threaded, system.buses.keys)), 
        system_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_threaded, system.buses.keys)), 
        system_SI_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall_threaded, system.buses.keys)), 
        system_SI_stderror; atol = 1e-4)
end
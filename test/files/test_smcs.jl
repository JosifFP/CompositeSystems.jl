resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = true,
    count_samples = true
)

@testset "Sequential MCS, 1000 samples, RBTS, non-threaded" begin

    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RBTS/Base/RBTS.m"
    Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    #getindex(util, :)
    #CompositeAdequacy.PTV(util, :)

    method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=false)
    shortfall_nonthreaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

    system_EDLC_mean = [0.0, 0.0, 1.18200, 0.0, 0.00200, 10.35400]
    system_EENS_mean = [0.0, 0.0, 10.68267, 0.0, 0.01941, 127.18585]
    system_SI_mean = [0.0, 0.0, 3.46465, 0.0, 0.00629, 41.24946]

    system_EDLC_stderror = [0.0, 0.0, 0.13081, 0.0, 0.00200, 0.45317]
    system_EENS_stderror= [0.0, 0.0, 1.66407, 0.0, 0.01941, 5.61568]
    system_SI_stderror = [0.0, 0.0, 0.53969, 0.0, 0.00629, 1.82130]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_nonthreaded, system.buses.keys)), 
        system_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_nonthreaded, system.buses.keys)), 
        system_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_nonthreaded, system.buses.keys)), 
        system_SI_mean; atol = 1e-4)

    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall_nonthreaded, system.buses.keys)), 
        system_EDLC_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall_nonthreaded, system.buses.keys)), 
        system_EENS_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall_nonthreaded, system.buses.keys)), 
        system_SI_stderror; atol = 1e-4)
end

@testset "Sequential MCS, 1000 samples, RBTS, threaded" begin

    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RBTS/Base/RBTS.m"
    Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    #getindex(util, :)
    #CompositeAdequacy.PTV(util, :)

    system_EDLC_mean = [0.0, 0.0, 1.18200, 0.0, 0.00200, 10.35400]
    system_EENS_mean = [0.0, 0.0, 10.68267, 0.0, 0.01941, 127.18585]
    system_SI_mean = [0.0, 0.0, 3.46465, 0.0, 0.00629, 41.24946]

    system_EDLC_stderror = [0.0, 0.0, 0.13081, 0.0, 0.00200, 0.45317]
    system_EENS_stderror= [0.0, 0.0, 1.66407, 0.0, 0.01941, 5.61568]
    system_SI_stderror = [0.0, 0.0, 0.53969, 0.0, 0.00629, 1.82130]

    method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=true)
    shortfall_threaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

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

@testset "Sequential MCS, 100 samples, RTS" begin
    
    timeseriesfile = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
    Base_reliabilityfile = "test/data/RTS_79_A/R_RTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=false)
    shortfall_nonthreaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

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

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall_nonthreaded, system.buses.keys)), 
        system_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_nonthreaded, system.buses.keys)), 
        system_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_nonthreaded, system.buses.keys)), 
        system_SI_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall_nonthreaded, system.buses.keys)), 
        system_SI_stderror; atol = 1e-4)
    
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true)
    shortfall_threaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

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
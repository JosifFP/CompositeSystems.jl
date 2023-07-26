resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    #set_string_names_on_creation = false,
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

    CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_nonthreaded, system.buses.keys))

    system_EDLC_mean = [0.0, 0.0, 1.19100, 0.0, 0.00199, 10.42499]
    system_EENS_mean = [0.0, 0.0, 9.55717, 0.0, 0.01930, 128.37732]
    system_SI_mean = [0.0, 0.0, 3.09962, 0.0, 0.00626, 41.63588]
    
    system_EDLC_stderror = [0.0, 0.0, 0.13097, 0.0, 0.00200, 0.45253]
    system_EENS_stderror= [0.0, 0.0, 1.35715, 0.0, 0.01930, 5.66021]
    system_SI_stderror = [0.0, 0.0, 0.44015, 0.0, 0.00626, 1.83574]

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

@testset "Sequential MCS, 100 samples, RTS, non-threaded" begin
    
    timeseriesfile = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
    Base_reliabilityfile = "test/data/RTS_79_A/R_RTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=false)
    shortfall_nonthreaded,_ = CompositeSystems.assess(system, method, settings, resultspecs...)

    system_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.66, 0.0, 8.78000, 0.16, 0.0, 0.0, 0.0, 2.37, 
        0.0, 0.0, 0.0, 0.0, 0.69, 0.0, 0.0, 0.0, 0.0, 0.0]

    system_EENS_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 280.40032, 0.0, 770.41584, 7.11353, 0.0, 0.0, 0.0, 
        219.74267, 0.0, 0.0, 0.0, 0.0, 71.21919, 0.0, 0.0, 0.0, 0.0, 0.0]

    system_SI_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.90316, 0.0, 16.21927, 0.14975, 0.0, 0.0, 0.0, 4.62616, 
        0.0, 0.0, 0.0, 0.0, 1.49935, 0.0, 0.0, 0.0, 0.0, 0.0]

    system_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.33244, 0.0, 3.21769, 0.11970, 0.0, 0.0, 0.0, 1.85691, 
        0.0, 0.0, 0.0, 0.0, 1.02961, 0.0, 0.0, 0.0, 0.0, 0.0]

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
end
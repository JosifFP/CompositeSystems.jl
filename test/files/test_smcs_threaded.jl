
settings = CompositeSystems.Settings(;
    jump_modelmode = JuMP.AUTOMATIC,
    #optimizer = gurobi_optimizer,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    #set_string_names_on_creation = false
)


@testset "Sequential MCS, 100 samples, RBTS, threaded" begin

    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RBTS/Base/RBTS.m"
    Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true)#, count_samples=true)
    shortfall_threaded = first(CompositeSystems.assess(system, method, settings, CompositeAdequacy.Shortfall()))

    system_EENS_mean_no_storage = [0.0, 0.0, 13.68820, 0.0, 0.19304, 123.34869]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_threaded, system.buses.keys)), 
        system_EENS_mean_no_storage; atol = 1e-4)

    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/others/Storage/RBTS_strg.m"
    reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true, count_samples=true)
    shortfall_threaded = first(CompositeSystems.assess(system, method, settings, CompositeAdequacy.Shortfall()))
    system_EENS_mean_storage = [0.0, 0.0, 9.02484, 0.0, 0.88675, 115.56389]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall_threaded, system.buses.keys)), 
        system_EENS_mean_storage; atol = 1e-4)

end

@testset "Sequential MCS, 1000 samples, RBTS, threaded" begin

    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RBTS/Base/RBTS.m"
    Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

    system_EDLC_mean = [0.0, 0.0, 1.21599, 0.0, 0.00199, 10.37499]
    system_EENS_mean = [0.0, 0.0, 9.80189, 0.0, 0.01930, 127.66720]
    system_SI_mean = [0.0, 0.0, 3.17899, 0.0, 0.00626, 41.40557]
    
    system_EDLC_stderror = [0.0, 0.0, 0.13298, 0.0, 0.00200, 0.45122]
    system_EENS_stderror= [0.0, 0.0, 1.37436, 0.0, 0.01930, 5.63966]
    system_SI_stderror = [0.0, 0.0, 0.44574, 0.0, 0.00626, 1.82908]

    method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=true)
    shortfall_threaded = first(CompositeSystems.assess(system, method, settings, CompositeAdequacy.Shortfall()))

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
    
    timeseriesfile = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
    Base_reliabilityfile = "test/data/RTS_79_A/R_RTS.m"
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
    
    system_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.02, 0.0, 9.71, 0.16, 0.0, 0.0, 
        0.0, 2.51, 0.0, 0.0, 0.0, 0.0, 0.70000, 0.0, 0.0, 0.0, 0.0, 0.0]  
    system_EENS_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 313.14204, 0.0, 836.48611, 7.11353, 
        0.0, 0.0, 0.0, 223.98704, 0.0, 0.0, 0.0, 0.0, 71.97868, 0.0, 0.0, 0.0, 0.0, 0.0]
    system_SI_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 6.59246, 0.0, 17.61023, 0.14975, 0.0, 
        0.0, 0.0, 4.7155, 0.0, 0.0, 0.0, 0.0, 1.51534, 0.0, 0.0, 0.0, 0.0, 0.0]
    system_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.57322, 0.0, 3.33650, 0.11970, 0.0, 
        0.0, 0.0, 1.85522, 0.0, 0.0, 0.0, 0.0, 1.02965, 0.0, 0.0, 0.0, 0.0, 0.0]
    
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true)
    shortfall_threaded = first(CompositeSystems.assess(system, method, settings, CompositeAdequacy.Shortfall()))

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

# loads = [
#     1 => 0.2/1.85,
#     2 => 0.85/1.85,
#     3 => 0.4/1.85,
#     4 => 0.2/1.85,
#     5 => 0.2/1.85
# ]

# gurobi_optimizer = JuMP.optimizer_with_attributes(
#     Gurobi.Optimizer, 
#     "Presolve"=>1, 
#     "PreCrush"=>1, 
#     "OutputFlag"=>0, 
#     "LogToConsole"=>0, 
#     "NonConvex"=>2, 
#     "NumericFocus"=>3, 
#     "Threads"=>64
# )

#resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
settings = CompositeSystems.Settings(;
   optimizer = gurobi_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.DCMPPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = true
)

@testset "Sequential MCS, 100 samples, RBTS, non-threaded, DCMPPowerModel form." begin

    sys = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
    settings.powermodel_formulation = OPF.DCMPPowerModel
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=false)
    shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))
    sys_EENS_mean = [0.0,0.0,13.688204,0.0,0.1930499,123.34869]
    sys_EDLC_mean = [0.0,0.0,1.440000,0.0,0.020000,9.950000]
    sys_SI_mean = [0.0,0.0,4.439417,0.0,0.062611,40.004979]
    sys_EENS_stderror = [0.0,0.0,4.973098,0.0,0.193049,15.30661]
    sys_EDLC_stderror = [0.0,0.0,0.386468,0.0,0.020000,1.2088374]
    sys_SI_stderror = [0.0,0.0,1.612896,0.0,0.062611,4.964307]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, sys.buses.keys)), 
        sys_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, sys.buses.keys)), 
        sys_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_mean; atol = 1e-4)
    
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall, sys.buses.keys)), 
        sys_EDLC_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall, sys.buses.keys)), 
        sys_EENS_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_stderror; atol = 1e-4)
end

@testset "Sequential MCS, 100 samples, RBTS, threaded, DCMPPowerModel form." begin

    sys = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
    settings.powermodel_formulation = OPF.DCMPPowerModel
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true)
    shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))
    sys_EENS_mean = [0.0,0.0,13.688204,0.0,0.1930499,123.34869]
    sys_EDLC_mean = [0.0,0.0,1.440000,0.0,0.020000,9.950000]
    sys_SI_mean = [0.0,0.0,4.439417,0.0,0.062611,40.004979]
    sys_EENS_stderror = [0.0,0.0,4.973098,0.0,0.193049,15.30661]
    sys_EDLC_stderror = [0.0,0.0,0.386468,0.0,0.020000,1.2088374]
    sys_SI_stderror = [0.0,0.0,1.612896,0.0,0.062611,4.964307]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, sys.buses.keys)), 
        sys_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, sys.buses.keys)), 
        sys_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_mean; atol = 1e-4)
    
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall, sys.buses.keys)), 
        sys_EDLC_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall, sys.buses.keys)), 
        sys_EENS_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_stderror; atol = 1e-4)
end

@testset "Sequential MCS, 1000 samples, RBTS, threaded, DCMPPowerModel form." begin

    sys = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
    settings.powermodel_formulation = OPF.DCMPPowerModel
    method = CompositeAdequacy.SequentialMCS(samples=1000, seed=100, threaded=true)
    shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))

    sys_EDLC_mean = [0.0, 0.0, 1.21599, 0.0, 0.00199, 10.37499]
    sys_EENS_mean = [0.0, 0.0, 9.80189, 0.0, 0.01930, 127.66720]
    sys_SI_mean = [0.0, 0.0, 3.17899, 0.0, 0.00626, 41.40557]
    sys_EDLC_stderror = [0.0, 0.0, 0.13298, 0.0, 0.00200, 0.45122]
    sys_EENS_stderror= [0.0, 0.0, 1.37436, 0.0, 0.01930, 5.63966]
    sys_SI_stderror = [0.0, 0.0, 0.44574, 0.0, 0.00626, 1.82908]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, sys.buses.keys)), 
        sys_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, sys.buses.keys)), 
        sys_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_mean; atol = 1e-4)

    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall, sys.buses.keys)), 
        sys_EDLC_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall, sys.buses.keys)), 
        sys_EENS_stderror; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_stderror; atol = 1e-4)
end

@testset "Sequential MCS, 100 samples, RTS, non-threaded, DCMPPowerModel form." begin
    
    sys = BaseModule.SystemModel(rawfile_rts, relfile_rts, tseriesfile_rts)
    settings.powermodel_formulation = OPF.DCMPPowerModel
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=false)
    shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))

    sys_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.02, 0.0, 9.71, 0.16, 0.0, 0.0, 
        0.0, 2.51, 0.0, 0.0, 0.0, 0.0, 0.70000, 0.0, 0.0, 0.0, 0.0, 0.0]  
    sys_EENS_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 313.14204, 0.0, 836.48611, 7.11353, 
        0.0, 0.0, 0.0, 223.98704, 0.0, 0.0, 0.0, 0.0, 71.97868, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_SI_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 6.59246, 0.0, 17.61023, 0.14975, 0.0, 
        0.0, 0.0, 4.7155, 0.0, 0.0, 0.0, 0.0, 1.51534, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.57322, 0.0, 3.33650, 0.11970, 0.0, 
        0.0, 0.0, 1.85522, 0.0, 0.0, 0.0, 0.0, 1.02965, 0.0, 0.0, 0.0, 0.0, 0.0]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, sys.buses.keys)), 
        sys_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, sys.buses.keys)), 
        sys_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_stderror; atol = 1e-4)
end

@testset "Sequential MCS, 100 samples, RTS, threaded, DCMPPowerModel form." begin
    
    sys = BaseModule.SystemModel(rawfile_rts, relfile_rts, tseriesfile_rts)
    settings.powermodel_formulation = OPF.DCMPPowerModel
    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true)
    shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))

    sys_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.02, 0.0, 9.71, 0.16, 0.0, 0.0, 
        0.0, 2.51, 0.0, 0.0, 0.0, 0.0, 0.70000, 0.0, 0.0, 0.0, 0.0, 0.0]  
    sys_EENS_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 313.14204, 0.0, 836.48611, 7.11353, 
        0.0, 0.0, 0.0, 223.98704, 0.0, 0.0, 0.0, 0.0, 71.97868, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_SI_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 6.59246, 0.0, 17.61023, 0.14975, 0.0, 
        0.0, 0.0, 4.7155, 0.0, 0.0, 0.0, 0.0, 1.51534, 0.0, 0.0, 0.0, 0.0, 0.0]
    sys_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.57322, 0.0, 3.33650, 0.11970, 0.0, 
        0.0, 0.0, 1.85522, 0.0, 0.0, 0.0, 0.0, 1.02965, 0.0, 0.0, 0.0, 0.0, 0.0]

    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, sys.buses.keys)), 
        sys_EDLC_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, sys.buses.keys)), 
        sys_EENS_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.val.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_mean; atol = 1e-4)
    @test isapprox(
        CompositeAdequacy.stderror.(CompositeSystems.SI.(shortfall, sys.buses.keys)), 
        sys_SI_stderror; atol = 1e-4)
end
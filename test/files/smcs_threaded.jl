settings = CompositeSystems.Settings(;
   optimizer = gurobi_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.DCMPPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = true
)

@testset verbose=true "Sequential Monte Carlo Simulations using Gurobi, RBTS" begin

    sys = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)

    @testset "Sequential MCS, 10 samples, RBTS, threaded, DCPPowerModel form." begin
        
        settings.powermodel_formulation = OPF.DCPPowerModel
        method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true)
        shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))
        sys_EENS_mean = [0.0, 0.0, 28.823827, 0.0, 0.0, 79.665336]
        sys_EDLC_mean = [0.0, 0.0, 1.7, 0.0, 0.0, 6.6]
        sys_SI_mean = [0.0, 0.0, 9.348267, 0.0, 0.0, 25.837404]
        sys_EENS_stderror = [0.0, 0.0, 28.154107, 0.0, 0.0, 44.054396]
        sys_EDLC_stderror = [0.0, 0.0, 1.491085, 0.0, 0.0, 3.818668]
        sys_SI_stderror = [0.0, 0.0, 9.131061, 0.0, 0.0, 14.287911]    

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

    @testset "Sequential MCS, 10 samples, RBTS, threaded, DCMPPowerModel form." begin
        
        settings.powermodel_formulation = OPF.DCMPPowerModel
        method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true)
        shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))
        sys_EENS_mean = [0.0, 0.0, 28.823827, 0.0, 0.0, 79.665336]
        sys_EDLC_mean = [0.0, 0.0, 1.7, 0.0, 0.0, 6.6]
        sys_SI_mean = [0.0, 0.0, 9.348267, 0.0, 0.0, 25.837404]
        sys_EENS_stderror = [0.0, 0.0, 28.154107, 0.0, 0.0, 44.054396]
        sys_EDLC_stderror = [0.0, 0.0, 1.491085, 0.0, 0.0, 3.818668]
        sys_SI_stderror = [0.0, 0.0, 9.131061, 0.0, 0.0, 14.287911]

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

    @testset "Sequential MCS, 10 samples, RBTS, threaded, LPACCPowerModel form." begin
        
        settings.powermodel_formulation = OPF.LPACCPowerModel
        method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true)
        shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))
        sys_EENS_mean = [0.0, 0.0, 36.756045, 0.0, 0.0, 84.439255]
        sys_EDLC_mean = [0.0, 0.0, 2.0, 0.0, 0.0, 7.9]
        sys_SI_mean = [0.0, 0.0, 11.920878, 0.0, 0.0, 27.385702]
        sys_EENS_stderror = [0.0, 0.0, 35.343386, 0.0, 0.0, 45.733081]
        sys_EDLC_stderror = [0.0, 0.0, 1.605546, 0.0, 0.0, 4.622289]
        sys_SI_stderror = [0.0, 0.0, 11.462719, 0.0, 0.0, 14.832349]    

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
end

@testset verbose=true "Sequential Monte Carlo Simulations using Gurobi, RTS" begin

    sys = BaseModule.SystemModel(rawfile_rts, relfile_rts, tseriesfile_rts)

    @testset "Sequential MCS, 10 samples, RTS, threaded, DCPPowerModel form." begin
        
        settings.powermodel_formulation = OPF.DCPPowerModel
        method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true)
        shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))
        sys_EENS_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 363.005903, 0.0, 551.424678, 0.0, 0.0, 0.0, 0.0, 28.25952, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.1, 0.0, 7.7, 0.0, 0.0, 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_SI_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 7.642229, 0.0, 11.60894, 0.0, 0.0, 0.0, 0.0, 0.594937, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_EENS_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 204.927776, 0.0, 222.691654, 0.0, 0.0, 0.0, 0.0, 16.672288, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_EDLC_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.340228, 0.0, 2.932765, 0.0, 0.0, 0.0, 0.0, 0.366667, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.314269, 0.0, 4.688245, 0.0, 0.0, 0.0, 0.0, 0.350996, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]    

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

    @testset "Sequential MCS, 10 samples, RTS, threaded, DCMPPowerModel form." begin
    
        settings.powermodel_formulation = OPF.DCMPPowerModel
        method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true)
        shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))
        sys_EENS_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 363.005903, 0.0, 551.424678, 0.0, 0.0, 0.0, 0.0, 28.25952, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.1, 0.0, 7.7, 0.0, 0.0, 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_SI_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 7.642229, 0.0, 11.60894, 0.0, 0.0, 0.0, 0.0, 0.594937, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_EENS_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 204.927776, 0.0, 222.691654, 0.0, 0.0, 0.0, 0.0, 16.672288, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_EDLC_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.340228, 0.0, 2.932765, 0.0, 0.0, 0.0, 0.0, 0.366667, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.314269, 0.0, 4.688245, 0.0, 0.0, 0.0, 0.0, 0.350996, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]        
    
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

    @testset "Sequential MCS, 10 samples, RTS, threaded, LPACCPowerModel form." begin
    
        settings.powermodel_formulation = OPF.LPACCPowerModel
        method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true)
        shortfall = first(CompositeSystems.assess(sys, method, settings, CompositeAdequacy.Shortfall()))
        sys_EENS_mean = [8.895296e-7, 1.542952e-6, 2.329097e-6, 8.934530e-7, 9.604839e-7, 2.946249e-6, 363.005904, 1.115191e-6, 735.560518, 
            5.726296e-6, 0.0, 0.0, 1.070441e-6, 49.192042, 2.446211e-6, 1.743777e-6, 0.0, 2.584625e-6, 1.033463e-5, 3.197025e-6, 0.0, 0.0, 0.0, 0.0]
        sys_EDLC_mean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.1, 0.0, 10.1, 0.0, 0.0, 0.0, 0.0, 1.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_SI_mean = [1.872693e-8, 3.248319e-8, 4.903361e-8, 1.880953e-8, 2.022071e-8, 6.202629e-8, 7.642229, 2.347770e-8, 15.485484, 
            1.205536e-7, 0.0, 0.0, 2.253560e-8, 1.035622, 5.149917e-8, 3.671109e-8, 0.0, 5.441316e-8, 2.175712e-7, 6.730578e-8, 0.0, 0.0, 0.0, 0.0]
        sys_EENS_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 204.927776, 0.0, 286.279892, 0.0, 0.0, 0.0, 0.0, 24.156352, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_EDLC_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.340228, 0.0, 3.436568, 0.0, 0.0, 0.0, 0.0, 0.458258, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        sys_SI_stderror = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.314269, 0.0, 6.026945, 0.0, 0.0, 0.0, 0.0, 0.508555, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]        

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
end
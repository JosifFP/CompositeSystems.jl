
settings = CompositeSystems.Settings(;
   optimizer = gurobi_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.DCMPPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = true
)

@testset "ELCC capacity value, 100 samples, RBTS, threaded" begin

    method = CompositeAdequacy.SequentialMCS(samples=100, seed=100, threaded=true)
    loads = [1 => 0.2/1.85, 2 => 0.85/1.85, 3 => 0.4/1.85, 4 => 0.2/1.85, 5 => 0.2/1.85]

    system_base = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
    system_augmented = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
    system_base.generators.pmax[1] = 0.001
    max_load = 40.0
    tolerance = 7.0
    cc = CompositeAdequacy.assess(
        system_base, system_augmented, CompositeAdequacy.ELCC{CompositeAdequacy.SI}(
        max_load, loads; tolerance=tolerance, p_value=0.5), settings, method)

    @test isapprox(CompositeAdequacy.val(cc.target_metric), 130.73325; atol = 1e-5)
    @test isapprox(CompositeAdequacy.val(cc.si_metric), 130.73325; atol = 1e-5)
    @test isapprox(CompositeAdequacy.val(cc.eens_metric), 403.094218; atol = 1e-5)
    @test isapprox(CompositeAdequacy.val(cc.edlc_metric), 36.089999; atol = 1e-5)
    @test isapprox(cc.capacity_value, 31; atol = 1e-5)
    @test isapprox(cc.tolerance_error, 7.0; atol = 1e-5)
end
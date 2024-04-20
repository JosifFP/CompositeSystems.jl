settings = CompositeSystems.Settings(;
   optimizer = gurobi_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.DCMPPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = true
)


@testset "Equivalent Transmission Capacity (ETC), 10 samples, RBTS, threaded" begin

   loads = [
      1 => 0.2/1.85,
      2 => 0.85/1.85,
      3 => 0.4/1.85,
      4 => 0.2/1.85,
      5 => 0.2/1.85
   ]

   sys_transmission_unsolved = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
   sys_transmission_solved = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
   sys_storage_augmented = BaseModule.SystemModel(rawfile_rbts_strg, relfile_rbts_strg, tseriesfile_rbts)
   sys_transmission_unsolved.generators.pmax[1] = 0.1
   sys_storage_augmented.generators.pmax[1] = 0.1
   method = CompositeAdequacy.SequentialMCS(samples=10, seed=100, threaded=true, verbose=false)

   shortfall_unsolved = first(CompositeAdequacy.assess(sys_transmission_unsolved, method, settings, CompositeAdequacy.Shortfall()))
   shortfall_solved = first(CompositeAdequacy.assess(sys_transmission_solved, method, settings, CompositeAdequacy.Shortfall()))

   max_load = 40.0
   tolerance = 1.0
   cc = CompositeAdequacy.assess(
      sys_transmission_unsolved, sys_transmission_solved, CompositeAdequacy.ELCC{CompositeAdequacy.SI}(
         max_load, loads; tolerance=tolerance, p_value=0.5, verbose=false), settings, method, shortfall_unsolved)
   #
   elcc_target = cc.capacity_value
   sys_storage_augmented.storages.buses[1] = 1
   sys_storage_augmented.storages.charge_rating[1] = 1.0
   sys_storage_augmented.storages.discharge_rating[1] = 1.0
   sys_storage_augmented.storages.thermal_rating[1] = 1.0
   sys_storage_augmented.storages.energy_rating[1] = 1.0
   energy_capacity_range = (50.0, 300.0)
   power_capacity = 100.0
   storage_key = 1

   ETC_final = CompositeAdequacy.assess(
      sys_transmission_solved, sys_storage_augmented, CompositeAdequacy.ETC{CompositeAdequacy.SI}(
      energy_capacity_range, power_capacity, storage_key, elcc_target, loads; p_value=0.5, verbose=false), settings, method
   )

   @test isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_unsolved)), 83.496204; atol = 1e-4)
   @test isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall_solved)), 35.1856715; atol = 1e-4)
   @test isapprox(elcc_target, 25; atol = 1e-1)
   @test isapprox(ETC_final.capacity_value, 206; atol = 1e-1)
   @test isapprox(CompositeAdequacy.val(ETC_final.target_metric), 75.2150147; atol = 1e-4)
   @test isapprox(CompositeAdequacy.val(ETC_final.eens_metric), 263.2525695; atol = 1e-4)
   @test isapprox(ETC_final.tolerance_error, 0.3475017; atol = 1e-4)
end
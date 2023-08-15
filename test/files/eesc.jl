settings = CompositeSystems.Settings(;
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.DCMPPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = true,
   set_string_names_on_creation = false
)

@testset "Sequential MCS, 100 samples, RBTS, threaded" begin

   loads = [
      1 => 0.2/1.85,
      2 => 0.85/1.85,
      3 => 0.4/1.85,
      4 => 0.2/1.85,
      5 => 0.2/1.85
   ]

   timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
   rawfile = "test/data/RBTS/Base/RBTS.m"
   Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
   timeseriesfile_2 = "test/data/RBTS/SYSTEM_LOADS.xlsx"
   rawfile_2 = "test/data/others/Storage/RBTS_strg.m"
   Base_reliabilityfile_2 = "test/data/others/Storage/R_RBTS_strg.m"

   sys_transmission_unsolved = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
   sys_transmission_solved = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
   sys_storage_augmented = BaseModule.SystemModel(rawfile_2, Base_reliabilityfile_2, timeseriesfile_2)
   sys_transmission_unsolved.generators.pmax[1] = 0.2
   sys_storage_augmented.generators.pmax[1] = 0.2
   method = CompositeAdequacy.SequentialMCS(samples=50, seed=100, threaded=true, count_samples=true)


   shortfall = first(CompositeAdequacy.assess(sys_transmission_unsolved, simulationspec, settings, CompositeAdequacy.Shortfall()))
   @test isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall)), 49.45343882; atol = 1e-4)

   shortfall = first(CompositeAdequacy.assess(sys_transmission_solved, simulationspec, settings, CompositeAdequacy.Shortfall()))
   @test isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall)), 38.41040458; atol = 1e-4)

   max_load = 20.0
   tolerance = 1.0
   cc = CompositeAdequacy.assess(
      sys_transmission_unsolved, sys_transmission_solved, CompositeAdequacy.ELCC{CompositeAdequacy.SI}(
         max_load, loads; tolerance=tolerance, p_value=0.5), settings, method, shortfall)
   #
   elcc_target = cc.capacity_value

   # elcc_loads, base_load, sys_var = CompositeAdequacy.copy_load(sys_transmission_solved, Tuple.(loads))
   # CompositeAdequacy.update_load!(sys_var, elcc_loads, base_load, Float64(elcc_target))
   # shortfall = first(CompositeAdequacy.assess(sys_var, simulationspec, settings, CompositeAdequacy.Shortfall()))
   # isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall)), 48.06177989; atol = 1e-4)

   # elcc_loads, base_load, sys_var = CompositeAdequacy.copy_load(sys_transmission_unsolved, Tuple.(loads))
   # CompositeAdequacy.update_load!(sys_var, elcc_loads, base_load, Float64(elcc_target))
   # shortfall = first(CompositeAdequacy.assess(sys_var, simulationspec, settings, CompositeAdequacy.Shortfall()))
   # isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall)), 80.5419221; atol = 1e-4)

   sys_storage_augmented.storages.buses[1] = 1
   sys_storage_augmented.storages.charge_rating[1] = 0.1
   sys_storage_augmented.storages.discharge_rating[1] = 0.1
   sys_storage_augmented.storages.thermal_rating[1] = 0.1
   sys_storage_augmented.storages.energy_rating[1] = 0.1

   # sys_storage_augmented.storages.energy_rating[1] = 0.1
   # elcc_loads, base_load, sys_var = CompositeAdequacy.copy_load(sys_storage_augmented, Tuple.(loads))
   # CompositeAdequacy.update_load!(sys_var, elcc_loads, base_load, Float64(elcc_target))
   # shortfall = first(CompositeAdequacy.assess(sys_var, simulationspec, settings, CompositeAdequacy.Shortfall()))
   # CompositeAdequacy.val.(CompositeSystems.SI.(shortfall))
   # isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall)), 48.485434379; atol = 1e-4)

   # sys_storage_augmented.storages.energy_rating[1] = 0.2
   # elcc_loads, base_load, sys_var = CompositeAdequacy.copy_load(sys_storage_augmented, Tuple.(loads))
   # CompositeAdequacy.update_load!(sys_var, elcc_loads, base_load, Float64(elcc_target))
   # shortfall = first(CompositeAdequacy.assess(sys_var, simulationspec, settings, CompositeAdequacy.Shortfall()))
   # CompositeAdequacy.val.(CompositeSystems.SI.(shortfall))
   # isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall)), 45.6419266437; atol = 1e-4)

   # sys_storage_augmented.storages.energy_rating[1] = 0.4
   # elcc_loads, base_load, sys_var = CompositeAdequacy.copy_load(sys_storage_augmented, Tuple.(loads))
   # CompositeAdequacy.update_load!(sys_var, elcc_loads, base_load, Float64(elcc_target))
   # shortfall = first(CompositeAdequacy.assess(sys_var, simulationspec, settings, CompositeAdequacy.Shortfall()))
   # CompositeAdequacy.val.(CompositeSystems.SI.(shortfall))
   # isapprox(CompositeAdequacy.val.(CompositeSystems.SI.(shortfall)), 41.6895980; atol = 1e-4)
   #@info("lower_bound_metric=$(CompositeAdequacy.val(CompositeAdequacy.SI(shortfall)))")
   energy_capacity_range = (10.0, 20.0)
   power_capacity = 10.0
   storage_key = 1

   EESC = CompositeAdequacy.assess(
      sys_transmission_solved, sys_storage_augmented, CompositeAdequacy.EESC{CompositeAdequacy.SI}(
      energy_capacity_range, power_capacity, storage_key, elcc_target, loads; p_value=0.5), settings, method
   )

   @test isapprox(EESC.capacity_value, 11; atol = 1e-1)
   @test isapprox(CompositeAdequacy.val(EESC.target_metric), 48.06177989138; atol = 1e-4)
   @test isapprox(CompositeAdequacy.val(EESC.eens_metric), 157.00181736; atol = 1e-4)
   @test isapprox(EESC.tolerance_error, 0.08038217; atol = 1e-4)
end
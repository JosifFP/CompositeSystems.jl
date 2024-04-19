
@testset "test SystemModel" begin

   data_mp = PowerModels.parse_file("./test/data/others/case7_tplgy.m")
   data_pti = PowerModels.parse_file("./test/data/others/case7_tplgy.raw")
   PowerModels.deactivate_isolated_components!(data_mp)
   PowerModels.simplify_network!(data_mp)
   PowerModels.deactivate_isolated_components!(data_pti)
   PowerModels.simplify_network!(data_pti)
   
   sys_mp = BaseModule.SystemModel("./test/data/others/case7_tplgy.m")
   sys_pti = BaseModule.SystemModel("./test/data/others/case7_tplgy.m")

   active_buses_pm = active_buses_pti = 0
   active_branches_pm = active_branches_pti = 0
   active_generators_pm = active_generators_pti = 0
   active_storage_pm = active_storage_pti = 0

   for (i,bus) in data_mp["bus"]
      if i in Set(["2", "4", "5", "7"])
         @test bus["bus_type"] != 4
         active_buses_pm = active_buses_pm + 1
      else
         @test bus["bus_type"] == 4
      end
   end

   for (i,strg) in data_mp["storage"]
      if i in Set([])
         @test strg["status"] != 0
         active_storage_pm = active_storage_pm + 1
      else
         @test strg["status"] == 0
      end
   end

   for (i,branch) in data_mp["branch"]
      if i in Set(["8"])
         @test branch["br_status"] == 1
         active_branches_pm = active_branches_pm + 1
      else
         @test branch["br_status"] == 0
      end
   end

   for (i,gen) in data_mp["gen"]
      if i in Set(["2", "3"])
         @test gen["gen_status"] == 1
         active_generators_pm = active_generators_pm + 1
      else
         @test gen["gen_status"] == 0
      end
   end

   for (i,bus) in data_pti["bus"]
      if i in Set(["2", "4", "5", "7"])
         @test bus["bus_type"] != 4
         active_buses_pti = active_buses_pti + 1
      else
         @test bus["bus_type"] == 4
      end
   end

   for (i,strg) in data_pti["storage"]
      if i in Set([])
         @test strg["status"] != 0
         active_storage_pti = active_storage_pti + 1
      else
         @test strg["status"] == 0
      end
   end

   for (i,branch) in data_pti["branch"]
      if i in Set(["7"])
         @test branch["br_status"] == 1
         active_branches_pti = active_branches_pti + 1
      else
         @test branch["br_status"] == 0
      end
   end

   for (i,gen) in data_pti["gen"]
      if i in Set(["2", "3"])
         @test gen["gen_status"] == 1
         active_generators_pti = active_generators_pti + 1
      else
         @test gen["gen_status"] == 0
      end
   end

   @test length(sys_mp.buses) == length(sys_pti.buses) == active_buses_pm == active_buses_pti
   @test length(sys_mp.generators) == length(sys_pti.generators) == active_generators_pm == active_generators_pti
   @test length(sys_mp.branches) == length(sys_pti.branches) == active_branches_pm == active_branches_pti
   @test length(sys_mp.storages) == length(sys_pti.storages) == active_storage_pm == active_storage_pti

   data_mp = CompositeSystems.DataSanityCheck(data_mp)
   data_mp_symbol = CompositeSystems.ref_initialize(data_mp)
   data_pti = CompositeSystems.DataSanityCheck(data_pti)
   data_pti_symbol = CompositeSystems.ref_initialize(data_pti)   
   @test CompositeSystems.check_consistency(data_mp_symbol, sys_pti.buses, sys_pti.loads, sys_pti.branches, sys_pti.shunts, sys_pti.generators, sys_pti.storages) == false
   @test CompositeSystems.check_connectivity(data_pti_symbol, sys_pti.buses, sys_pti.loads, sys_pti.branches, sys_pti.shunts, sys_pti.generators, sys_pti.storages) === nothing
end
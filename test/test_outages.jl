
@testset "RBTS system, sequential outages" begin
    @testset "test sequentially split situations w/o isolated buses, RBTS system, LPACCPowerModel" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        rawfile = "test/data/RBTS/Base/RBTS_AC.m"
        reliabilityfile = "test/data/RBTS/Base/R_RBTS_FULL.m"
        timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
        system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
        for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
        pm = OPF.abstract_model(system, settings)
        systemstates = OPF.SystemStates(system, available=true)
        CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)

        t=1
        OPF._update!(pm, system, systemstates, settings, t)
        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) #THIS RESULT IS NOT OPTIMAL, BUT SAFE
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) #THIS RESULT IS NOT OPTIMAL, BUT SAFE
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        t=2
        OPF._update!(pm, system, systemstates, settings, t)  
        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) #THIS RESULT IS NOT OPTIMAL, BUT SAFE
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) #THIS RESULT IS NOT OPTIMAL, BUT SAFE
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        t=3
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        CompositeSystems.field(systemstates, :generators)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[8,t] = 0
        CompositeSystems.field(systemstates, :generators)[9,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "G3, G7, G8 and G9 on outage" begin
            @test isapprox(sum(systemstates.plc[:]), 0.3716; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0.3716; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5000; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.1169; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(systemstates.qlc[3]/systemstates.plc[3], CompositeAdequacy.field(system, :loads, :pf)[2]; atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        t=4
        CompositeSystems.field(systemstates, :branches)[5,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)
        
        @testset "L5 and L8 on outage" begin
            @test isapprox(sum(systemstates.plc[:]), 0.4; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0.2; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0.2; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5552; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5830; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(systemstates.qlc[5]/systemstates.plc[5], CompositeAdequacy.field(system, :loads, :pf)[4]; atol = 1e-4)
            @test isapprox(systemstates.qlc[6]/systemstates.plc[6], CompositeAdequacy.field(system, :loads, :pf)[5]; atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        t=5
        OPF._update!(pm, system, systemstates, settings, t)  

        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) #THIS RESULT IS NOT OPTIMAL, BUT SAFE
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) #THIS RESULT IS NOT OPTIMAL, BUT SAFE
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        t=6
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)  

        @testset "L3, L4 and L8 on outage" begin
            @test isapprox(sum(systemstates.plc[:]), 0.7703; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0.2000; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0.1703; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0.4000; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(systemstates.qlc[2]/systemstates.plc[2], CompositeAdequacy.field(system, :loads, :pf)[1]; atol = 1e-4)
            @test isapprox(systemstates.qlc[3]/systemstates.plc[3], CompositeAdequacy.field(system, :loads, :pf)[2]; atol = 1e-4)
            @test isapprox(systemstates.qlc[4]/systemstates.plc[4], CompositeAdequacy.field(system, :loads, :pf)[3]; atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        t=7
        CompositeSystems.field(systemstates, :branches)[2,t] = 0
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[1,t] = 0
        CompositeSystems.field(systemstates, :generators)[2,t] = 0
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)   

        @testset "L2 and L7 on outage, generation reduced" begin
            @test isapprox(sum(systemstates.plc[:]), 0.9792; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0.8500; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0.1292; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(systemstates.qlc[4]/systemstates.plc[4], CompositeAdequacy.field(system, :loads, :pf)[3]; atol = 1e-4)
            @test isapprox(systemstates.qlc[6]/systemstates.plc[6], CompositeAdequacy.field(system, :loads, :pf)[5]; atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        t=8
        OPF._update!(pm, system, systemstates, settings, t)  
        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) #THIS RESULT IS NOT OPTIMAL, BUT SAFE
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) #THIS RESULT IS NOT OPTIMAL, BUT SAFE
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end
    end
end

@testset "RTS system, sequential outages" begin
    @testset "test sequentially split situations w/o isolated buses, RTS system, LPACCPowerModel" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = false,
            deactivate_isolated_bus_gens_stors = false,
            set_string_names_on_creation = true
        )

        timeseriesfile = "test/data/RTS/Loads_system.xlsx"
        rawfile = "test/data/RTS/Base/RTS.m"
        reliabilityfile = "test/data/RTS/Base/R_RTS2.m"
        system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)    

        data = OPF.build_network(rawfile, symbol=false)
        load_pd = Dict{Int, Float64}()
        for (k,v) in data["load"]
            load_pd[parse(Int,k)] = v["pd"]
            system.loads.qd[parse(Int,k)] = v["qd"]
        end
        
        for t in 1:8736
            for i in system.loads.keys
                system.loads.pd[i,t] = load_pd[i]
            end
        end
        
        pm = OPF.abstract_model(system, settings)
        systemstates = OPF.SystemStates(system, available=true)
        CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)

        t=1
        OPF._update!(pm, system, systemstates, settings, t)
        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(systemstates.branches[:,t])
        end
        
        t=2
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        @testset "Outages of L29, L36, L37" begin
            t=3
            CompositeSystems.field(systemstates, :branches)[29,t] = 0
            CompositeSystems.field(systemstates, :branches)[36,t] = 0
            CompositeSystems.field(systemstates, :branches)[37,t] = 0
            OPF._update!(pm, system, systemstates, settings, t)
            @test isapprox(sum(systemstates.plc[:]), 3.09; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 1.81; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 1.28; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.9103; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 12.3375; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

            @test isapprox(systemstates.qlc[19]/systemstates.plc[19], CompositeAdequacy.field(system, :loads, :pf)[16]; atol = 1e-4)
            @test isapprox(systemstates.qlc[20]/systemstates.plc[20], CompositeAdequacy.field(system, :loads, :pf)[17]; atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        @testset "No outages" begin
            
            t=4
            OPF._update!(pm, system, systemstates, settings, t)
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        @testset "Outages of L25, L26, L28" begin
            t=5
            CompositeSystems.field(systemstates, :branches)[25,t] = 0
            CompositeSystems.field(systemstates, :branches)[26,t] = 0
            CompositeSystems.field(systemstates, :branches)[28,t] = 0
            OPF._update!(pm, system, systemstates, settings, t)
            @test isapprox(sum(systemstates.plc[:]), 2.3544; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 1.75; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0.6044; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.8532; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 6.6031; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

            @test isapprox(systemstates.qlc[9]/systemstates.plc[9], CompositeAdequacy.field(system, :loads, :pf)[9]; atol = 1e-4)
            @test isapprox(systemstates.qlc[14]/systemstates.plc[14], CompositeAdequacy.field(system, :loads, :pf)[12]; atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        @testset "Outages of L1, L8, L10" begin
            t=6
            CompositeSystems.field(systemstates, :branches)[1,t] = 0
            CompositeSystems.field(systemstates, :branches)[8,t] = 0
            CompositeSystems.field(systemstates, :branches)[10,t] = 0
            OPF._update!(pm, system, systemstates, settings, t)
            @test isapprox(sum(systemstates.plc[:]), 1.1654; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 1.1654; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.7494; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.2094; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 0; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(systemstates.qlc[6]/systemstates.plc[6], CompositeAdequacy.field(system, :loads, :pf)[6]; atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        @testset "Outages of L7, L19, L29" begin
            t=7
            CompositeSystems.field(systemstates, :branches)[7,t] = 0
            CompositeSystems.field(systemstates, :branches)[19,t] = 0
            CompositeSystems.field(systemstates, :branches)[29,t] = 0
            OPF._update!(pm, system, systemstates, settings, t)
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.5599; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 10.1106; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end

        @testset "Outages of L7, L23, L29" begin
            t=8
            CompositeSystems.field(systemstates, :branches)[7,t] = 0
            CompositeSystems.field(systemstates, :branches)[23,t] = 0
            CompositeSystems.field(systemstates, :branches)[29,t] = 0
            OPF._update!(pm, system, systemstates, settings, t)
            @test isapprox(sum(systemstates.plc[:]), 1.9497; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 1.75; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0.1997; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 27.4628; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 8.3110; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(systemstates.qlc[9]/systemstates.plc[9], CompositeAdequacy.field(system, :loads, :pf)[9]; atol = 1e-4)
            @test isapprox(systemstates.qlc[14]/systemstates.plc[14], CompositeAdequacy.field(system, :loads, :pf)[12]; atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(systemstates, :branches)[:,t])
        end
    end

    @testset "test sequentially split situations w/o isolated buses, RTS system, DCMPPowerModel" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = false,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        timeseriesfile = "test/data/RTS/Loads_system.xlsx"
        rawfile = "test/data/RTS/Base/RTS.m"
        reliabilityfile = "test/data/RTS/Base/R_RTS2.m"
        system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)    

        data = OPF.build_network(rawfile, symbol=false)
        load_pd = Dict{Int, Float64}()
        for (k,v) in data["load"]
            load_pd[parse(Int,k)] = v["pd"]
            system.loads.qd[parse(Int,k)] = v["qd"]
        end
        
        for t in 1:8736
            for i in system.loads.keys
                system.loads.pd[i,t] = load_pd[i]
            end
        end
        
        pm = OPF.abstract_model(system, settings)
        systemstates = OPF.SystemStates(system, available=true)
        CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)

        t=1
        OPF._update!(pm, system, systemstates, settings, t)
        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        end
        
        t=2
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        end

        t=3
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        CompositeSystems.field(systemstates, :branches)[36,t] = 0
        CompositeSystems.field(systemstates, :branches)[37,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "Outages of L29, L36, L37" begin
            @test isapprox(sum(systemstates.plc[:]), 3.09; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 1.81; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 1.28; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-3.09; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        end

        t=4
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "No outages" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        end

        t=5
        CompositeSystems.field(systemstates, :branches)[25,t] = 0
        CompositeSystems.field(systemstates, :branches)[26,t] = 0
        CompositeSystems.field(systemstates, :branches)[28,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "Outages of L25, L26, L28" begin
            @test isapprox(sum(systemstates.plc[:]), 2.12; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 1.75; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0.37; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 2.12; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        end

        t=6
        CompositeSystems.field(systemstates, :branches)[1,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        CompositeSystems.field(systemstates, :branches)[10,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "Outages of L1, L8, L10" begin
            @test isapprox(sum(systemstates.plc[:]), 1.150; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 1.150; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 1.150; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1, atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        end

        t=7
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :branches)[19,t] = 0
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "Outages of L7, L19, L29" begin
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        end

        t=8
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :branches)[23,t] = 0
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "Outages of L7, L23, L29" begin
            @test isapprox(sum(systemstates.plc[:]), 1.65; atol = 1e-2)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[7], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[8], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[9], 1.65; atol = 1e-2)
            @test isapprox(systemstates.plc[10], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[11], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[12], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[13], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[14], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[15], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[16], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[17], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[18], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-1.65; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        end

    end
end

@testset "RBTS system, OPF formulation, non-sequential outages" begin
    @testset "test OPF, RBTS system, DCPPowerModel, outages" begin
        rawfile = "test/data/RBTS/Base/RBTS_AC.m"
        system = BaseModule.SystemModel(rawfile)
        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #OUTAGE BRANCH 1
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch #1" begin
            states.branches[1] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["1"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        #OUTAGE BRANCH 6
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch #6" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[6] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["6"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        #NO OUTAGE
        @testset "DC-OPF with DCPPowerModel, RBTS, no outage" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 3" begin
    
            #OUTAGE BRANCH 3
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 2" begin
    
            #OUTAGE BRANCH 2
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 7" begin
    
            #OUTAGE BRANCH 7
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 4" begin
    
            #OUTAGE BRANCH 4
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 5" begin
    
            #OUTAGE BRANCH 5
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[5] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 8" begin
    
            #OUTAGE BRANCH 8
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["8"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 9" begin
    
            #OUTAGE BRANCH 9
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[9] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["9"]["br_status"] = 0
            data["load"]["5"]["status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end
            
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        #NO OUTAGE
        @testset "DC-OPF with DCPPowerModel, RBTS, no outage" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #1 and #5" begin
    
            #OUTAGE BRANCH #1 AND #5
            states.branches[1] = 0
            states.branches[5] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["1"]["br_status"] = 0
            data["branch"]["5"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
        
        #OUTAGE BRANCH #2 AND #7
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #2 and #7" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[2] = 0
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            data["branch"]["7"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #5 AND #8
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #5 and #8" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[5] = 0
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            data["branch"]["8"]["br_status"] = 0
            data["load"]["5"]["status"] = 0
            data["load"]["4"]["status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    end
    
    @testset "test OPF, RBTS system, DCMPPowerModel, outages" begin
    
        rawfile = "test/data/RBTS/Base/RBTS_AC.m"
        system = BaseModule.SystemModel(rawfile)
        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #OUTAGE BRANCH 1
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch #1" begin
    
            states.branches[1] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["1"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 6
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch #6" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[6] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["6"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #NO OUTAGE
        @testset "DC-OPF with DCMPPowerModel, RBTS, no outage" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 3
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 3" begin
    
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 2
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 2" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 7
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 7" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 4
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 4" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 5
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 5" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[5] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 8
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 8" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["8"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 9
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 9" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[9] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["9"]["br_status"] = 0
            data["load"]["5"]["status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end
            
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
      
        #NO OUTAGE
        @testset "DC-OPF with DCMPPowerModel, RBTS, no outage" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #1 AND #5
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #1 and #5" begin
    
            states.branches[1] = 0
            states.branches[5] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["1"]["br_status"] = 0
            data["branch"]["5"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #2 AND #7
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #2 and #7" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[2] = 0
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #5 AND #8
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #5 and #8" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[5] = 0
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            data["branch"]["8"]["br_status"] = 0
            data["load"]["5"]["status"] = 0
            data["load"]["4"]["status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    end

    @testset "test OPF, RBTS system, LPACCPowerModel, outages" begin

        rawfile = "test/data/RBTS/Base/RBTS_AC.m"
        system = BaseModule.SystemModel(rawfile)
        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #NO OUTAGE
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 3
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 3" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 2
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 2" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 7
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 7" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 4
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 4" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 5
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 5" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)            
        end
    
        #OUTAGE BRANCH 8
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 8" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["8"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)      
        end
    
        #OUTAGE BRANCH 9
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 9" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[9] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["9"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)        
        end
        
        #NO OUTAGE
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        #OUTAGE BRANCH #5 AND #8
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH #5 AND #8" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[5] = 0
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            data["branch"]["8"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)        
        end
    end

    @testset "test OPF, RBTS system, LPACCPowerModel, outages" begin

        rawfile = "test/data/RBTS/Base/RBTS_AC.m"
        system = BaseModule.SystemModel(rawfile)
        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #NO OUTAGE
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 3
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 3" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 2
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 2" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 7
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 7" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 4
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 4" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
        end
    
        #OUTAGE BRANCH 5
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 5" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)            
        end
    
        #OUTAGE BRANCH 8
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 8" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["8"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)      
        end
    
        #OUTAGE BRANCH 9
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 9" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[9] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["9"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)        
        end
        
        #NO OUTAGE
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(CompositeSystems.field(states, :branches)[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        #OUTAGE BRANCH #5 AND #8
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH #5 AND #8" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[5] = 0
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            data["branch"]["8"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)        
        end
    end
end

@testset "RTS system, OPF formulation, non-sequential outages" begin
    @testset "test OPF, RTS system, DCPPowerModel, outages" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #OUTAGE BRANCH 1
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #1" begin

            states.branches[1] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = PowerModels.parse_file(rawfile)
            data["branch"]["1"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
            
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH 25 - 26
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #25 and #26" begin

            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[25] = 0
            states.branches[26] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["25"]["br_status"] = 0
            data["branch"]["26"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH 14 - 16
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #14 and #16" begin

            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[14] = 0
            states.branches[16] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["14"]["br_status"] = 0
            data["branch"]["16"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 6
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #6" begin

            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[6] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["6"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
            
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #NO OUTAGE
        @testset "DC-OPF with DCPPowerModel, RTS, no outage" begin

            states = CompositeAdequacy.SystemStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 3
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 3" begin
    
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 2
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 2" begin

            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 33
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 7" begin

            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[33] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["33"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 4
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 4" begin

            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 5
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 5" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 8" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 9
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 9" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, no outage" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #1 AND #6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, branch #1 and #6" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #20
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[20] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["20"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, branch #20" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #12
        @testset "DC-OPF with DCPPowerModel, RTS, branch #12" begin
            states = CompositeAdequacy.SystemStates(system, available=true)
            states.branches[12] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["12"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    end

    @testset "test OPF, RTS system, DCMPPowerModel, outages" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #OUTAGE BRANCH 1
        states.branches[1] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #1" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH 25 - 26
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[25] = 0
        states.branches[26] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["25"]["br_status"] = 0
        data["branch"]["26"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #25 and #26" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH 14 - 16
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[14] = 0
        states.branches[16] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["14"]["br_status"] = 0
        data["branch"]["16"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #14 and #16" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch #6" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, no outage" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 3
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[3] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["3"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 3" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 2
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 2" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 33
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[33] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["33"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 7" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 4
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[4] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["4"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 4" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 5
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 5" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 8" begin
            
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 9
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 9" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, no outage" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #1 AND #6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #1 and #6" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #20
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[20] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["20"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #20" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #12
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[12] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["12"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #12" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH #7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        data["bus"]["24"]["bus_type"] = 4
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #7" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH #7 AND #27
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        states.branches[27] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        data["branch"]["27"]["br_status"] = 0
        data["bus"]["24"]["bus_type"] = 4
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #7 and 27" begin
            
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
    end
end

@testset "test OPF, RTS system, LPACCPowerModel, outages" begin

    rawfile = "test/data/RTS/Base/RTS.m"
    system = BaseModule.SystemModel(rawfile)
    settings = CompositeSystems.Settings(
        juniper_optimizer_2;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.LPACCPowerModel,
        select_largest_splitnetwork = true,
        deactivate_isolated_bus_gens_stors = true,
        set_string_names_on_creation = true
    )
    states = CompositeAdequacy.SystemStates(system, available=true)
    pm = OPF.solve_opf(system, settings)

    #OUTAGE BRANCH 1
    states.branches[1] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["1"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)

    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #1" begin
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0

        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 25 - 26
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[25] = 0
    states.branches[26] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["25"]["br_status"] = 0
    data["branch"]["26"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #25 and #26" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 14 - 16
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[14] = 0
    states.branches[16] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["14"]["br_status"] = 0
    data["branch"]["16"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)

    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #14 and #16" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 6
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[6] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["6"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #6" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #NO OUTAGE
    states = CompositeAdequacy.SystemStates(system, available=true)
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, no outage" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 3
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[3] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["3"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 3" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 2
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[2] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["2"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 2" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 33
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[33] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["33"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 7" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 4
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[4] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["4"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 4" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 5
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[5] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["5"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 5" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 8
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[8] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["8"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 8" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 9
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[9] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["9"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 9" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #NO OUTAGE
    states = CompositeAdequacy.SystemStates(system, available=true)
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, no outage" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #1 AND #6
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[1] = 0
    states.branches[6] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["1"]["br_status"] = 0
    data["branch"]["6"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #1 and #6" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #20
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[20] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["20"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #20" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #12
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[12] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["12"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #12" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #7
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[7] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["7"]["br_status"] = 0
    data["bus"]["24"]["bus_type"] = 4
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #7" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #7 and #27
    states = CompositeAdequacy.SystemStates(system, available=true)
    states.branches[7] = 0
    states.branches[27] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_pf = OPF.build_sol_branch_values(pm, system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["7"]["br_status"] = 0
    data["branch"]["27"]["br_status"] = 0
    data["bus"]["24"]["bus_type"] = 4
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #7 and #27" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    end
end
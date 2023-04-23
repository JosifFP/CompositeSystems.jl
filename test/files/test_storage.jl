@testset "RBTS system, sequential outages, storage at bus 6" begin
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    rawfile = "test/data/others/Storage/RBTS_strg.m"
    reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
    settings = CompositeSystems.Settings(
        juniper_optimizer_1;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = false
    )
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
    for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
    
    system.storages.buses[1] = 6
    system.storages.charge_rating[1] = 0.25
    system.storages.discharge_rating[1] = 0.25
    system.storages.thermal_rating[1] = 0.25
    system.storages.energy_rating[1] = 2
    pm = OPF.abstract_model(system, settings)
    componentstates = OPF.ComponentStates(system, available=true)
    OPF.build_problem!(pm, system, 1)
    OPF.OPF.field(system, :storages, :energy)[1] = 0.0
    
    t=1
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=1, No outages" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(system.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
    end
    
    t=2
    OPF.update!(pm, system, componentstates, settings, t)  
    @testset "t=2, No outages" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(componentstates.stored_energy[t], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
    end
    
    t=3
    componentstates.stored_energy[t-1] = OPF.field(system, :storages, :energy_rating)[1] #stored_energy(t-1) = 2.0
    componentstates.generators[3,t] = 0
    componentstates.generators[7,t] = 0
    componentstates.generators[8,t] = 0
    componentstates.generators[9,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=3, G3, G7, G8 and G9 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.1; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.1; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 2.0 - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end
    
    t=4
    componentstates.branches[5,t] = 0
    componentstates.branches[8,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=4, L5 and L8 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.15; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0.15; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.75 - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end
    
    t=5
    componentstates.branches[3,t] = 0
    componentstates.branches[4,t] = 0
    componentstates.branches[8,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)  
    
    @testset "t=5, L3, L4 and L8 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.15; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.15; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.15; atol = 1e-4)
    end
    
    t=6
    componentstates.branches[2,t] = 0
    componentstates.branches[7,t] = 0
    componentstates.generators[1,t] = 0
    componentstates.generators[2,t] = 0
    componentstates.generators[3,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 
    
    @testset "L2 and L7 on outage, generation reduced" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.49; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.49; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15 - 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.25; atol = 1e-4)
    end

    t=7
    componentstates.branches[2,t] = 0
    componentstates.generators[1,t] = 0
    componentstates.generators[2,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L2 on outage, generation reduced" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15 - 0.25 - 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end

    t=8
    componentstates.branches[1,t] = 0
    componentstates.branches[6,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L1 and L6 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.23; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15 - 0.25 - 0.25 - 0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[2]["from"], 0.71; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[7]["from"], 0.71; atol = 1e-4)
    end

    t=9
    componentstates.branches[4,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L4 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15 - 0.25 - 0.25 - 0.23 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

end

@testset "RBTS system, sequential outages, storage at bus 2" begin
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    rawfile = "test/data/others/Storage/RBTS_strg.m"
    reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
    settings = CompositeSystems.Settings(
        juniper_optimizer_1;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = false
    )
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
    for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
    
    system.storages.buses[1] = 2
    system.storages.charge_rating[1] = 0.25
    system.storages.discharge_rating[1] = 0.25
    system.storages.thermal_rating[1] = 0.25
    system.storages.energy_rating[1] = 2
    pm = OPF.abstract_model(system, settings)
    componentstates = OPF.ComponentStates(system, available=true)
    OPF.build_problem!(pm, system, 1)
    OPF.OPF.field(system, :storages, :energy)[1] = 0.0
    
    t=1
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=1, No outages" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(system.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
    end
    
    t=2
    OPF.update!(pm, system, componentstates, settings, t)  
    @testset "t=2, No outages" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(componentstates.stored_energy[t], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
    end
    
    t=3
    componentstates.stored_energy[t-1] = 1.0 #stored_energy(t-1) = 2.0
    componentstates.generators[3,t] = 0
    componentstates.generators[7,t] = 0
    componentstates.generators[8,t] = 0
    componentstates.generators[9,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=3, G3, G7, G8 and G9 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.1; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.1; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end
    
    t=4
    componentstates.branches[5,t] = 0
    componentstates.branches[8,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=4, L5 and L8 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.40; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0.20; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0.20; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 0.75 + system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end
    
    t=5
    componentstates.branches[3,t] = 0
    componentstates.branches[4,t] = 0
    componentstates.branches[8,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "t=5, L3, L4 and L8 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.15; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.15; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
    end

    t=6
    componentstates.branches[2,t] = 0
    componentstates.branches[7,t] = 0
    componentstates.generators[1,t] = 0
    componentstates.generators[2,t] = 0
    componentstates.generators[3,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L2 and L7 on outage, generation reduced" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.74; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.74; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[3]["from"], 0.71; atol = 1e-4)
    end

    t=7
    componentstates.branches[2,t] = 0
    componentstates.generators[1,t] = 0
    componentstates.generators[2,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L2 on outage, generation reduced" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end

    t=8
    componentstates.branches[1,t] = 0
    componentstates.branches[6,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L1 and L6 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.23; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.23; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[2]["from"], 0.71; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[7]["from"], 0.71; atol = 1e-4)
    end

    t=9
    componentstates.branches[4,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L1 and L6 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25 + 0.25 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

end

@testset "RBTS system, sequential outages, storage at bus 6" begin
    
    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/others/Storage/RBTS_strg.m"
    reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"

    settings = CompositeSystems.Settings(;
        optimizer = juniper_optimizer,
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
    OPF.build_problem!(pm, system)
    OPF.field(system, :storages, :energy)[1] = 0.0
    
    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(system.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.25
    end
    
    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.50
    end
    
    @testset "t=3, G3, G7, G8 and G9 on outage" begin
        t=3
        OPF.topology(pm, :stored_energy)[1] = OPF.field(system, :storages, :energy_rating)[1] #stored_energy(t-1) = 2.0
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.1; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.1; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.75
    end
    
    @testset "t=4, L5 and L8 on outage" begin
        t=4
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.15; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0.15; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.50; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] =  1.50
    end  
    
    @testset "t=5, L3, L4 and L8 on outage" begin
        t=5
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) - 0.15; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.35; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.15; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.15; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.35
    end
    
    @testset "t=6, L2 and L7 on outage, generation reduced" begin
        t=6
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, system, settings, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.49; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.49; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) - 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.1; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.25; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.1
    end

    @testset "t=7, L2 on outage, generation reduced" begin
        t=7
        pm.topology.branches_available[2] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        OPF.solve!(pm, system, settings, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) - 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.85; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.85
    end

    @testset "t=8, L1 and L6 on outage" begin
        t=8
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[6] = 0
        OPF.solve!(pm, system, settings, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) - 0.23; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.62; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[2]["from"], 0.71; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[7]["from"], 0.71; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.62
    end

    @testset "t=9, L4 on outage" begin
        t=9
        pm.topology.branches_available[4] = 0
        OPF.solve!(pm, system, settings, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.62 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.62 + 0.25
    end

end

@testset "RBTS system, sequential outages, storage at bus 2" begin
    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/others/Storage/RBTS_strg.m"
    reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
    
    settings = CompositeSystems.Settings(;
        optimizer = juniper_optimizer,
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
    OPF.build_problem!(pm, system)
    OPF.field(system, :storages, :energy)[1] = 0.0
    
    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(system.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.25
    end
    
    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.50
    end
    
    @testset "t=3, G3, G7, G8 and G9 on outage" begin
        t=3
        OPF.topology(pm, :stored_energy)[1] = 1.0 #stored_energy(t-1) = 2.0
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.1; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.1; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.75
    end
    
    @testset "t=4, L5 and L8 on outage" begin
        t=4
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.40; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0.20; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0.20; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.75 + 0.25
    end

    @testset "t=5, L3, L4 and L8 on outage" begin
        t=5
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.15; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.15; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.0 + 0.25
    end

    @testset "t=6, L2 and L7 on outage, generation reduced" begin
        t=6
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, system, settings, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.74; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.74; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.25 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[3]["from"], 0.71; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.25 + 0.25
    end

    @testset "t=7, L2 on outage, generation reduced" begin
        t=7
        pm.topology.branches_available[2] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        OPF.solve!(pm, system, settings, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) - 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.0 + 0.25
    end

    @testset "t=8, L1 and L6 on outage" begin
        t=8
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[6] = 0
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.23; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.23; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.25 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[2]["from"], 0.71; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[7]["from"], 0.71; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.25 + 0.25
    end

    @testset "t=9, L1 and L6 on outage" begin
        t=9
        pm.topology.branches_available[4] = 0
        OPF.solve!(pm, system, settings, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.buses_curtailed_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.7499; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.7499
    end
end

@testset "RTS system, sequential outages, storage at bus 8" begin

    settings = CompositeSystems.Settings(;
    optimizer = juniper_optimizer,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = true
    )

    timeseriesfile = "test/data/RTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/others/Storage/RTS_strg.m"
    Base_reliabilityfile = "test/data/others/Storage/R_RTS_strg.m"
    resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

    system.branches.rate_a[11] = system.branches.rate_a[11]*0.75
    system.branches.rate_a[12] = system.branches.rate_a[12]*0.75
    system.branches.rate_a[13] = system.branches.rate_a[13]*0.75

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

    system.storages.buses[1] = 8
    system.storages.charge_rating[1] = 1.0
    system.storages.discharge_rating[1] = 1.0
    system.storages.thermal_rating[1] = 1.0
    system.storages.energy_rating[1] = 2.0
    pm = OPF.abstract_model(system, settings)
    OPF.build_problem!(pm, system)
    OPF.field(system, :storages, :energy)[1] = 0.0

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
    end

    @testset "t=2, Outages on L11, L12, L13" begin
        t=2
        pm.topology.branches_available[11] = 0 #(7,8)
        pm.topology.branches_available[12] = 0 #(8,9)
        pm.topology.branches_available[13] = 0 #(8,10)
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 2.96; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 1.71; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "t=3, Outages on L11, L12, L13" begin
        t=3
        pm.topology.branches_available[11] = 0 #(7,8)
        pm.topology.branches_available[12] = 0 #(8,9)
        pm.topology.branches_available[13] = 0 #(8,10)
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 2.96; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 1.71; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "t=4, Outages on L11, L12, L13" begin
        t=4
        pm.topology.branches_available[11] = 0 #(7,8)
        pm.topology.branches_available[12] = 0 #(8,9)
        pm.topology.branches_available[13] = 0 #(8,10)
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 2.96; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 1.71; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "t=5, No outages" begin
        t=5
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.0
    end

    @testset "t=6, No outages" begin
        t=6
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 2.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 2.0
    end

    @testset "t=7, Outages on storage device and lines L29, L36, L37" begin
        t=7
        pm.topology.storages_available[1] = 0
        pm.topology.branches_available[29] = 0
        pm.topology.branches_available[36] = 0
        pm.topology.branches_available[37] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 3.09; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 1.81; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 1.28; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "t=8, Outages on L5, L11, L12, L13, L15" begin
        t=8
        pm.topology.storages_available[1] = 0
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[11] = 0
        pm.topology.branches_available[12] = 0
        pm.topology.branches_available[13] = 0
        pm.topology.branches_available[15] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 2.210+0.75; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0.96+0.75; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "t=9, Outages on L5, L11, L12, L13, L15" begin
        t=9
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[11] = 0
        pm.topology.branches_available[12] = 0
        pm.topology.branches_available[13] = 0
        pm.topology.branches_available[15] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 2.210+0.75; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0.96+0.75; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "t=10, No outages" begin
        t=10
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 1.0
    end
end

@testset "RTS system, sequential outages, storage at bus 9" begin

    settings = CompositeSystems.Settings(;
    optimizer = juniper_optimizer,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = true
    )

    timeseriesfile = "test/data/RTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/others/Storage/RTS_strg.m"
    Base_reliabilityfile = "test/data/others/Storage/R_RTS_strg.m"
    resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

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

    system.storages.buses[1] = 9
    system.storages.charge_rating[1] = 0.75
    system.storages.discharge_rating[1] = 0.75
    system.storages.thermal_rating[1] = 0.75
    system.storages.energy_rating[1] = 1.50
    system.branches.rate_a[7] = system.branches.rate_a[7]*0.50
    system.branches.rate_a[14] = system.branches.rate_a[14]*0.50
    system.branches.rate_a[15] = system.branches.rate_a[15]*0.50
    system.branches.rate_a[16] = system.branches.rate_a[16]*0.50
    system.branches.rate_a[17] = system.branches.rate_a[17]*0.50


    pm = OPF.abstract_model(system, settings)
    OPF.build_problem!(pm, system)
    OPF.field(system, :storages, :energy)[1] = 0.0

    @testset "No outages" begin
        t=1
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.75
    end

    @testset "Outages on T15, T16, L17" begin
        t=2
        pm.topology.storages_available[1] = 0
        pm.topology.branches_available[15] = 0.0
        pm.topology.branches_available[16] = 0.0
        pm.topology.branches_available[17] = 0.0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 1.38; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 1.38; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "No outages" begin
        t=3
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.75
    end

    @testset "Outages on T15, T16, L17" begin
        t=4
        pm.topology.branches_available[15] = 0.0
        pm.topology.branches_available[16] = 0.0
        pm.topology.branches_available[17] = 0.0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.63; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0.63; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.75; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "No outages" begin
        t=5
        pm.topology.storages_available[1] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end

    @testset "Outages on T15, T16, L17" begin
        t=6
        pm.topology.storages_available[1] = 0
        pm.topology.branches_available[15] = 0.0
        pm.topology.branches_available[16] = 0.0
        pm.topology.branches_available[17] = 0.0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 1.38; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 1.38; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        OPF._reset!(pm.topology)
        #OPF.topology(pm, :stored_energy)[1] = 0.0
    end
end
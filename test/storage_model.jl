@testset verbose=true "RBTS system, seq. outages, storage at bus 6, DCPPowerModel form." begin
    
    sys_rbts_tseries_strg.storages.buses[1] = 6
    sys_rbts_tseries_strg.storages.charge_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.discharge_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.thermal_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.energy_rating[1] = 2
    pm = OPF.abstract_model(sys_rbts_tseries_strg, settings_DCPPowerModel)
    OPF.build_problem!(pm, sys_rbts_tseries_strg)
    OPF.field(sys_rbts_tseries_strg, :storages, :energy)[1] = 0.0
    
    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(sys_rbts_tseries_strg.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "t=3, Outages on G3, G7, G8 and G9" begin
        t=3
        OPF.topology(pm, :stored_energy)[1] = OPF.field(sys_rbts_tseries_strg, :storages, :energy_rating)[1] #stored_energy(t-1) = 2.0
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.1; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.1; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) - sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "t=4, Outages on L5 and L8" begin
        t=4
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.15; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0.15; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) - sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.50; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        _reset!(pm.topology)
    end  
    
    @testset "t=5, Outages on L3, L4 and L8" begin
        t=5
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) - 0.15; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.35; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.15; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.15; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "t=6, Outages on L2 and L7, generation reduced" begin
        t=6
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.49; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.49; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) - 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.1; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.25; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=7, Outage on L2, generation reduced" begin
        t=7
        pm.topology.branches_available[2] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) - 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.85; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=8, Outages on L1 and L6" begin
        t=8
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[6] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) - 0.23; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.62; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), sys_rbts_tseries_strg.branches)[2]["from"], 0.71; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), sys_rbts_tseries_strg.branches)[7]["from"], 0.71; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=9, Outage on L4" begin
        t=9
        pm.topology.branches_available[4] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.62 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end
end

@testset verbose=true "RBTS system, seq. outages, storage at bus 2, DCPPowerModel form." begin
    
    sys_rbts_tseries_strg.storages.buses[1] = 2
    sys_rbts_tseries_strg.storages.charge_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.discharge_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.thermal_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.energy_rating[1] = 2
    pm = OPF.abstract_model(sys_rbts_tseries_strg, settings_DCPPowerModel)
    OPF.build_problem!(pm, sys_rbts_tseries_strg)
    OPF.field(sys_rbts_tseries_strg, :storages, :energy)[1] = 0.0
    
    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + 0.25; atol = 1e-4) 
        @test isapprox(sys_rbts_tseries_strg.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + 0.25; atol = 1e-4) 
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "t=3, Outages on G3, G7, G8 and G9" begin
        t=3
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.1; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.1; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) - 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "t=4, Outages on L5 and L8" begin
        t=4
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.40; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0.20; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0.20; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.50; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=5, Outages on L3, L4 and L8" begin
        t=5
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.15; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.15; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=6, Outages on L2 and L7, generation reduced" begin
        t=6
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.74; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.74; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.00; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), sys_rbts_tseries_strg.branches)[3]["from"], 0.71; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=7, Outage on L2, generation reduced" begin
        t=7
        pm.topology.branches_available[2] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) - 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=8, Outages on L1 and L6" begin
        t=8
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[6] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.23; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.23; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.00; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), sys_rbts_tseries_strg.branches)[2]["from"], 0.71; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), sys_rbts_tseries_strg.branches)[7]["from"], 0.71; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=9, Outages on L1 and L6" begin
        t=9
        pm.topology.branches_available[4] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_DCPPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]) + 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end
end

@testset verbose=true "RTS system, seq. outages, storage at bus 8, DCMPPowerModel form." begin

    settings_DCMPPowerModel.deactivate_isolated_bus_gens_stors = true
    sys_rts_tseries_strg.branches.rate_a[11] = sys_rts_tseries_strg.branches.rate_a[11]*0.75
    sys_rts_tseries_strg.branches.rate_a[12] = sys_rts_tseries_strg.branches.rate_a[12]*0.75
    sys_rts_tseries_strg.branches.rate_a[13] = sys_rts_tseries_strg.branches.rate_a[13]*0.75
    sys_rts_tseries_strg.storages.buses[1] = 8
    sys_rts_tseries_strg.storages.charge_rating[1] = 1.0
    sys_rts_tseries_strg.storages.discharge_rating[1] = 1.0
    sys_rts_tseries_strg.storages.thermal_rating[1] = 1.0
    sys_rts_tseries_strg.storages.energy_rating[1] = 2.0
    pm = OPF.abstract_model(sys_rts_tseries_strg, settings_DCMPPowerModel)
    OPF.build_problem!(pm, sys_rts_tseries_strg)
    OPF.field(sys_rts_tseries_strg, :storages, :energy)[1] = 0.0

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=2, Outages on L11, L12, L13" begin
        t=2
        pm.topology.branches_available[11] = 0 #(7,8)
        pm.topology.branches_available[12] = 0 #(8,9)
        pm.topology.branches_available[13] = 0 #(8,10)
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.96; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 1.71; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=3, Outages on L11, L12, L13" begin
        t=3
        pm.topology.branches_available[11] = 0 #(7,8)
        pm.topology.branches_available[12] = 0 #(8,9)
        pm.topology.branches_available[13] = 0 #(8,10)
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.96; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 1.71; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=4, Outages on L11, L12, L13" begin
        t=4
        pm.topology.branches_available[11] = 0 #(7,8)
        pm.topology.branches_available[12] = 0 #(8,9)
        pm.topology.branches_available[13] = 0 #(8,10)
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.96; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 1.71; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=5, No outages" begin
        t=5
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=6, No outages" begin
        t=6
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 2.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=7, Outages on storage device and lines L29, L36, L37" begin
        t=7
        pm.topology.storages_available[1] = 0
        pm.topology.branches_available[29] = 0
        pm.topology.branches_available[36] = 0
        pm.topology.branches_available[37] = 0
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 3.09; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 1.81; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 1.28; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=8, Outages on L5, L11, L12, L13, L15" begin
        t=8
        pm.topology.storages_available[1] = 0
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[11] = 0
        pm.topology.branches_available[12] = 0
        pm.topology.branches_available[13] = 0
        pm.topology.branches_available[15] = 0
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.210+0.75; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0.96+0.75; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=9, Outages on L5, L11, L12, L13, L15" begin
        t=9
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[11] = 0
        pm.topology.branches_available[12] = 0
        pm.topology.branches_available[13] = 0
        pm.topology.branches_available[15] = 0
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.210+0.75; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 1.25; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0.96+0.75; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=10, No outages" begin
        t=10
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    for i in 1:length(sys_rts_tseries_strg.branches.rate_a)
        sys_rts_tseries_strg.branches.rate_a[i] = rates_rts[i]
    end
    settings_DCMPPowerModel.deactivate_isolated_bus_gens_stors = false
end

@testset verbose=true "RTS system, seq. outages, storage at bus 9, DCMPPowerModel form." begin

    settings_DCMPPowerModel.deactivate_isolated_bus_gens_stors = true
    sys_rts_tseries_strg.branches.rate_a[7] = sys_rts_tseries_strg.branches.rate_a[7]*0.50
    sys_rts_tseries_strg.branches.rate_a[14] = sys_rts_tseries_strg.branches.rate_a[14]*0.50
    sys_rts_tseries_strg.branches.rate_a[15] = sys_rts_tseries_strg.branches.rate_a[15]*0.50
    sys_rts_tseries_strg.branches.rate_a[16] = sys_rts_tseries_strg.branches.rate_a[16]*0.50
    sys_rts_tseries_strg.branches.rate_a[17] = sys_rts_tseries_strg.branches.rate_a[17]*0.50
    sys_rts_tseries_strg.storages.buses[1] = 9
    sys_rts_tseries_strg.storages.charge_rating[1] = 0.75
    sys_rts_tseries_strg.storages.discharge_rating[1] = 0.75
    sys_rts_tseries_strg.storages.thermal_rating[1] = 0.75
    sys_rts_tseries_strg.storages.energy_rating[1] = 1.50

    pm = OPF.abstract_model(sys_rts_tseries_strg, settings_DCMPPowerModel)
    OPF.build_problem!(pm, sys_rts_tseries_strg)
    OPF.field(sys_rts_tseries_strg, :storages, :energy)[1] = 0.0

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=2, Outages on T15, T16, L17" begin
        t=2
        pm.topology.storages_available[1] = 0
        pm.topology.branches_available[15] = 0.0
        pm.topology.branches_available[16] = 0.0
        pm.topology.branches_available[17] = 0.0
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 1.38; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 1.38; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=3, No outages" begin
        t=3
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=4, Outages on T15, T16, L17" begin
        t=4
        pm.topology.branches_available[15] = 0.0
        pm.topology.branches_available[16] = 0.0
        pm.topology.branches_available[17] = 0.0
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.63; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0.63; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.75; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=5, No outages" begin
        t=5
        pm.topology.storages_available[1] = 0
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=6, Outages on T15, T16, L17" begin
        t=6
        pm.topology.storages_available[1] = 0
        pm.topology.branches_available[15] = 0.0
        pm.topology.branches_available[16] = 0.0
        pm.topology.branches_available[17] = 0.0
        OPF.solve!(pm, sys_rts_tseries_strg, settings_DCMPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 1.38; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 1.38; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    for i in 1:length(sys_rts_tseries_strg.branches.rate_a)
        sys_rts_tseries_strg.branches.rate_a[i] = rates_rts[i]
    end
    settings_DCMPPowerModel.deactivate_isolated_bus_gens_stors = false
end

@testset verbose=true "RBTS system, seq. outages, storage at bus 2, LPACCPowerModel form." begin
    sys_rbts_tseries_strg.storages.buses[1] = 2
    sys_rbts_tseries_strg.storages.charge_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.discharge_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.thermal_rating[1] = 0.25
    sys_rbts_tseries_strg.storages.energy_rating[1] = 2
    pm = OPF.abstract_model(sys_rbts_tseries_strg, settings_LPACCPowerModel)
    OPF.build_problem!(pm, sys_rbts_tseries_strg)
    OPF.field(sys_rbts_tseries_strg, :storages, :energy)[1] = 0.0

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_LPACCPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 2.183867; atol = 1e-4) 
        @test isapprox(sys_rbts_tseries_strg.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_LPACCPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 2.1838679; atol = 1e-4) 
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=3, Outages on G3, G7, G8 and G9" begin
        t=3
        OPF.topology(pm, :stored_energy)[1] = 1.0
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_LPACCPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.1293105; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.1293105; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.500000; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=4, Outages on L5 and L8" begin
        t=4
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_LPACCPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.40; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0.20; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0.20; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5553; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=5, Outages on L3, L4 and L8" begin
        t=5
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_LPACCPowerModel, t)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.170307; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.170307; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.976389; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=6, Outages on L2 and L7, generation reduced" begin
        t=6
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, sys_rbts_tseries_strg, settings_LPACCPowerModel, t) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.979255; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.85; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0.129255; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.15110; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :stored_energy)[1], 1.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], sys_rbts_tseries_strg.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), sys_rbts_tseries_strg.branches)[3]["from"], 0.50111; atol = 1e-4)
        _reset!(pm.topology)
    end
end
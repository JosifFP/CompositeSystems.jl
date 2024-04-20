@testset verbose=true "Testing load minimization with isolated buses, RBTS system, DCPPowerModel form." begin

    pm = OPF.abstract_model(sys_rbts, settings_DCPPowerModel)
    OPF.build_problem!(pm, sys_rbts)
    t=1

    @testset "No outages" begin
        OPF.solve!(pm, sys_rbts, settings_DCPPowerModel, t, force=true)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end
    
    @testset "Outages on G3, G7, G8 and G9" begin
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, sys_rbts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), .35; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], .35; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end
    
    @testset "Outages on L5 and L8" begin
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), .4; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], .2; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], .2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L5 and L8" begin
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), .4; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], .2; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], .2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L3, L4 and L8, largest system selected" begin
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        settings_DCPPowerModel.select_largest_splitnetwork = true
        OPF.solve!(pm, sys_rbts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), .750; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], .2; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], .15; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], .4; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
        settings_DCPPowerModel.select_largest_splitnetwork = false
    end

    @testset "Outages on L3, L4 and L8" begin
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), .150; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], .150; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on G3, G7, G8 and G11" begin
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[11] = 0
        OPF.solve!(pm, sys_rbts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), .35; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], .35; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L2 and L7, generation reduced" begin
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, sys_rbts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), .74; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], .74; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(pm.topology.busshortfall_pd[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end
end

@testset verbose=true "Testing load minimization with isolated buses, IEEE-RTS system, DCPPowerModel form." begin

    pm = OPF.abstract_model(sys_rts, settings_DCPPowerModel)
    OPF.build_problem!(pm, sys_rts)
    t=1

    @testset "No outages" begin
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - sum(pm.topology.busshortfall_pd); atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L12, L13" begin
        pm.topology.branches_available[12] = 0
        pm.topology.branches_available[13] = 0
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end    
    
    @testset "Outages on L12, L13, largest system selected" begin
        pm.topology.branches_available[12] = 0
        pm.topology.branches_available[13] = 0
        settings_DCPPowerModel.select_largest_splitnetwork = true
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.9600; atol = 1e-4)
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
        _reset!(pm.topology)
        settings_DCPPowerModel.select_largest_splitnetwork = false
    end

    @testset "Outages on L1, L4, L10" begin
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[10] = 0
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), .410; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], .410; atol = 1e-4)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L1, L8, L10" begin
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[8] = 0
        pm.topology.branches_available[10] = 0
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 1.150; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 1.150; atol = 1e-4)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L7, L19, L29" begin
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[19] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L7, L23, L29" begin
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[23] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 1.65; atol = 1e-2)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 1.65; atol = 1e-2)
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
        _reset!(pm.topology)
    end

    @testset "Outages on L25, L26, L28, largest system selected" begin
        pm.topology.branches_available[25] = 0
        pm.topology.branches_available[26] = 0
        pm.topology.branches_available[28] = 0
        settings_DCPPowerModel.select_largest_splitnetwork = true
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 5.45; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 1.75; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], .37; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[15], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[16], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[17], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[18], 3.33; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[19], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[20], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[21], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[22], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[23], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
        settings_DCPPowerModel.select_largest_splitnetwork = false
    end

    @testset "Outages on L25, L26, L28" begin
        pm.topology.branches_available[25] = 0
        pm.topology.branches_available[26] = 0
        pm.topology.branches_available[28] = 0
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.12; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[9], 1.75; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[14], .37; atol = 1e-4)
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
        _reset!(pm.topology)
    end

    @testset "Outages on L29, L36, L37, largest system selected" begin
        pm.topology.branches_available[29] = 0
        pm.topology.branches_available[36] = 0
        pm.topology.branches_available[37] = 0
        settings_DCPPowerModel.select_largest_splitnetwork = true
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
        settings_DCPPowerModel.select_largest_splitnetwork = false
    end

    @testset "Outages on L29, L36, L37" begin
        pm.topology.branches_available[29] = 0
        pm.topology.branches_available[36] = 0
        pm.topology.branches_available[37] = 0
        OPF.solve!(pm, sys_rts, settings_DCPPowerModel, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end
end
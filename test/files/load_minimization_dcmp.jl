@testset verbose=true "Testing load minimization w/o isolated buses, RTS system, DCMPPowerModel form." begin

    settings_DCMPPowerModel.deactivate_isolated_bus_gens_stors = true
    pm = OPF.abstract_model(sys_rts, settings_DCMPPowerModel)
    OPF.build_problem!(pm, sys_rts)
    t=1

    @testset "No outages" begin
        OPF.solve!(pm, sys_rts, settings_DCMPPowerModel, t, force=true)
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

    @testset "Outages on L29, L36, L37" begin
        pm.topology.branches_available[29] = 0
        pm.topology.branches_available[36] = 0
        pm.topology.branches_available[37] = 0
        OPF.solve!(pm, sys_rts, settings_DCMPPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-3.09; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L25, L26, L28" begin
        pm.topology.branches_available[25] = 0
        pm.topology.branches_available[26] = 0
        pm.topology.branches_available[28] = 0
        OPF.solve!(pm, sys_rts, settings_DCMPPowerModel, t)
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
        @test isapprox(pm.topology.busshortfall_pd[14], 0.37; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 2.12; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L1, L8, L10" begin
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[8] = 0
        pm.topology.branches_available[10] = 0
        OPF.solve!(pm, sys_rts, settings_DCMPPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 1.150; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1, atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L7, L19, L29" begin
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[19] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts, settings_DCMPPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L7, L23, L29" begin
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[23] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts, settings_DCMPPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-1.65; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end
    settings_DCMPPowerModel.deactivate_isolated_bus_gens_stors = false
end

@testset verbose=true "Testing sequential load minimization w/o isolated buses, RTS system, DCMPPowerModel form." begin

    settings_DCMPPowerModel.deactivate_isolated_bus_gens_stors = true
    pm = OPF.abstract_model(sys_rts_tseries, settings_DCMPPowerModel)
    OPF.build_problem!(pm, sys_rts_tseries)

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, sys_rts_tseries, settings_DCMPPowerModel, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, sys_rts_tseries, settings_DCMPPowerModel, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=3, Outages on L29, L36, L37" begin
        t=3
        pm.topology.branches_available[29] = 0
        pm.topology.branches_available[36] = 0
        pm.topology.branches_available[37] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_DCMPPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-3.09; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=4, No outages" begin
        t=4
        OPF.solve!(pm, sys_rts_tseries, settings_DCMPPowerModel, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=5, Outages on L25, L26, L28" begin
        t=5
        pm.topology.branches_available[25] = 0
        pm.topology.branches_available[26] = 0
        pm.topology.branches_available[28] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_DCMPPowerModel, t)
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
        @test isapprox(pm.topology.busshortfall_pd[14], 0.37; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 2.12; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=6, Outages on L1, L8, L10" begin
        t=6
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[8] = 0
        pm.topology.branches_available[10] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_DCMPPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 1.150; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1, atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=7, Outages on L7, L19, L29" begin
        t=7
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[19] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_DCMPPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=8, Outages on L7, L23, L29" begin
        t=8
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[23] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_DCMPPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-1.65; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end
    settings_DCMPPowerModel.deactivate_isolated_bus_gens_stors = false
end
@testset verbose=true "Testing load minimization w/o isolated buses, RBTS system, LPACCPowerModel form." begin

    settings_LPACCPowerModel.deactivate_isolated_bus_gens_stors = true
    pm = OPF.abstract_model(sys_rbts, settings_LPACCPowerModel)
    OPF.build_problem!(pm, sys_rbts)
    t=1

    @testset "No outages" begin
        OPF.solve!(pm, sys_rbts, settings_LPACCPowerModel, t, force=true)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on G3, G7, G8 and G9" begin
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, sys_rbts, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.3716; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.3716; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5000; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.1169; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[3]/pm.topology.busshortfall_pd[3], CompositeAdequacy.field(sys_rbts, :loads, :pf)[2]; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "Outages on L5 and L8" begin
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.4; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0.2; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5552; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5830; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[5]/pm.topology.busshortfall_pd[5], CompositeAdequacy.field(sys_rbts, :loads, :pf)[4]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[6]/pm.topology.busshortfall_pd[6], CompositeAdequacy.field(sys_rbts, :loads, :pf)[5]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "Outages on L3, L4 and L8, largest system selected" begin
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        settings_LPACCPowerModel.select_largest_splitnetwork = true
        OPF.solve!(pm, sys_rbts, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.7703; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0.2000; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.1703; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0.4000; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[2]/pm.topology.busshortfall_pd[2], CompositeAdequacy.field(sys_rbts, :loads, :pf)[1]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[3]/pm.topology.busshortfall_pd[3], CompositeAdequacy.field(sys_rbts, :loads, :pf)[2]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[4]/pm.topology.busshortfall_pd[4], CompositeAdequacy.field(sys_rbts, :loads, :pf)[3]; atol = 1e-4)
        _reset!(pm.topology)
        settings_LPACCPowerModel.select_largest_splitnetwork = false
    end

    @testset "Outages on L3, L4 and L8" begin
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.1703; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.1703; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[3]/pm.topology.busshortfall_pd[3], CompositeAdequacy.field(sys_rbts, :loads, :pf)[2]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "Outages on L2 and L7, generation reduced" begin
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, sys_rbts, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.9792; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.8500; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0.1292; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[3]/pm.topology.busshortfall_pd[3], CompositeAdequacy.field(sys_rbts, :loads, :pf)[3]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[6]/pm.topology.busshortfall_pd[6], CompositeAdequacy.field(sys_rbts, :loads, :pf)[5]; atol = 1e-4)
        _reset!(pm.topology)
    end
    settings_LPACCPowerModel.deactivate_isolated_bus_gens_stors = false
end

@testset verbose=true "Testing sequential load minimization w/o isolated buses, RBTS system, LPACCPowerModel form." begin

    settings_LPACCPowerModel.deactivate_isolated_bus_gens_stors = true
    pm = OPF.abstract_model(sys_rbts_tseries, settings_LPACCPowerModel)
    OPF.build_problem!(pm, sys_rbts_tseries)

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t, force=true)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t, force=true)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=3, Outages on G3, G7, G8 and G9" begin
        t=3
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.3716; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.3716; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5000; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.1169; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[3]/pm.topology.busshortfall_pd[3], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[2]; atol = 1e-4)
        _reset!(pm.topology)
    end
    
    @testset "t=4, Outages on L5 and L8" begin
        t=4
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.4; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0.2; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5552; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5830; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[5]/pm.topology.busshortfall_pd[5], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[4]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[6]/pm.topology.busshortfall_pd[6], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[5]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=5, No outages" begin
        t=5
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t, force=true)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=6, Outages on L3, L4 and L8, largest system selected" begin
        t=6
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        settings_LPACCPowerModel.select_largest_splitnetwork = true
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.7703; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0.2000; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.1703; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0.4000; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[2]/pm.topology.busshortfall_pd[2], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[1]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[3]/pm.topology.busshortfall_pd[3], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[2]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[4]/pm.topology.busshortfall_pd[4], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[3]; atol = 1e-4)
        _reset!(pm.topology)
        settings_LPACCPowerModel.select_largest_splitnetwork = false
    end

    @testset "t=6, Outages on L3, L4 and L8" begin
        t=6
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.1703; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.1703; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[3]/pm.topology.busshortfall_pd[3], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[2]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=7, Outages on L2 and L7, generation reduced" begin
        t=7
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0.9792; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0.8500; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0.1292; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[3]/pm.topology.busshortfall_pd[3], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[3]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[6]/pm.topology.busshortfall_pd[6], CompositeAdequacy.field(sys_rbts_tseries, :loads, :pf)[5]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=8, No outages" begin
        t=8
        OPF.solve!(pm, sys_rbts_tseries, settings_LPACCPowerModel, t, force=true)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end
    settings_LPACCPowerModel.deactivate_isolated_bus_gens_stors = false
end

@testset verbose=true "Testing sequential load minimization w/o isolated buses, RTS system, LPACCPowerModel form." begin
    
    pm = OPF.abstract_model(sys_rts_tseries, settings_LPACCPowerModel)
    OPF.build_problem!(pm, sys_rts_tseries)
    t=1

    @testset "No outages" begin
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1494; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L29, L36, L37" begin
        pm.topology.branches_available[29] = 0
        pm.topology.branches_available[36] = 0
        pm.topology.branches_available[37] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.9065; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 12.3479; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[19]/pm.topology.busshortfall_pd[19], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[16]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[20]/pm.topology.busshortfall_pd[20], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[17]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "Outages on L25, L26, L28" begin
        pm.topology.branches_available[25] = 0
        pm.topology.branches_available[26] = 0
        pm.topology.branches_available[28] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.3491; atol = 1e-4)
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
        @test isapprox(pm.topology.busshortfall_pd[14], 0.5991; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.8537; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 6.6871; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[9]/pm.topology.busshortfall_pd[9], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[14]/pm.topology.busshortfall_pd[14], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[12]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "Outages on L1, L8, L10" begin
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[8] = 0
        pm.topology.branches_available[10] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 1.1654; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 1.1654; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.7513; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.2293; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[6]/pm.topology.busshortfall_pd[6], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[6]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "Outages on L7, L19, L29" begin
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[19] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.5612; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 10.1471; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "Outages on L7, L23, L29" begin
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[23] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 1.9450; atol = 1e-4)
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
        @test isapprox(pm.topology.busshortfall_pd[14], 0.1950; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 27.4632; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 8.3319; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[9]/pm.topology.busshortfall_pd[9], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[14]/pm.topology.busshortfall_pd[14], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[12]; atol = 1e-4)
        _reset!(pm.topology)
    end
end

@testset verbose=true "Testing sequential load minimization w/o isolated buses, RTS system, LPACCPowerModel form." begin
    
    pm = OPF.abstract_model(sys_rts_tseries, settings_LPACCPowerModel)
    OPF.build_problem!(pm, sys_rts_tseries)

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1494; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        _reset!(pm.topology)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1494; atol = 1e-4)
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
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.9065; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 12.3479; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(pm.topology.busshortfall_qd[19]/pm.topology.busshortfall_pd[19], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[16]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[20]/pm.topology.busshortfall_pd[20], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[17]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=4, No outages" begin
        t=4
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1494; atol = 1e-4)
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
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 2.3491; atol = 1e-4)
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
        @test isapprox(pm.topology.busshortfall_pd[14], 0.5991; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.8537; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 6.6871; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(pm.topology.busshortfall_qd[9]/pm.topology.busshortfall_pd[9], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[14]/pm.topology.busshortfall_pd[14], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[12]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=6, Outages on L1, L8, L10" begin
        t=6
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[8] = 0
        pm.topology.branches_available[10] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 1.1654; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_pd[6], 1.1654; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.7513; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.2293; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[6]/pm.topology.busshortfall_pd[6], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[6]; atol = 1e-4)
        _reset!(pm.topology)
    end

    @testset "t=7, Outages on L7, L19, L29" begin
        t=7
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[19] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.5612; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 10.1472; atol = 1e-4)
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
        OPF.solve!(pm, sys_rts_tseries, settings_LPACCPowerModel, t)
        @test isapprox(sum(pm.topology.busshortfall_pd[:]), 1.9450; atol = 1e-4)
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
        @test isapprox(pm.topology.busshortfall_pd[14], 0.1950; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 27.4632; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 8.3319; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(pm.topology.busshortfall_qd[9]/pm.topology.busshortfall_pd[9], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(pm.topology.busshortfall_qd[14]/pm.topology.busshortfall_pd[14], CompositeAdequacy.field(sys_rts_tseries, :loads, :pf)[12]; atol = 1e-4)
        _reset!(pm.topology)
    end
end
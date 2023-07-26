
@testset "RBTS system, test sequentially split situations w/o isolated buses, RBTS system, LPACCPowerModel" begin

    settings = CompositeSystems.Settings(;
        optimizer = juniper_optimizer,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.LPACCPowerModel,
        select_largest_splitnetwork = true,
        deactivate_isolated_bus_gens_stors = true,
        set_string_names_on_creation = true
    )

    rawfile = "test/data/RBTS/Base/RBTS.m"
    reliabilityfile = "test/data/RBTS/Base/R_RBTS_FULL.m"
    timeseriesfile = "test/data/RBTS/SYSTEM_LOADS.xlsx"
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
    for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
    pm = OPF.abstract_model(system, settings)
    OPF.build_problem!(pm, system)

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, system, settings, t, force=true)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm.topology)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, system, settings, t, force=true)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm.topology)
    end

    @testset "t=3, G3, G7, G8 and G9 on outage" begin
        t=3
        pm.topology.generators_available[3] = 0
        pm.topology.generators_available[7] = 0
        pm.topology.generators_available[8] = 0
        pm.topology.generators_available[9] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.3716; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.3716; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5000; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.1169; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[3]/pm.topology.buses_curtailed_pd[3], CompositeAdequacy.field(system, :loads, :pf)[2]; atol = 1e-4)
        OPF._reset!(pm.topology)
    end
    
    @testset "t=4, L5 and L8 on outage" begin
        t=4
        pm.topology.branches_available[5] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.4; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0.2; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5552; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5830; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[5]/pm.topology.buses_curtailed_pd[5], CompositeAdequacy.field(system, :loads, :pf)[4]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[6]/pm.topology.buses_curtailed_pd[6], CompositeAdequacy.field(system, :loads, :pf)[5]; atol = 1e-4)
        OPF._reset!(pm.topology)
    end

    @testset "t=5, No outages" begin
        t=5
        OPF.solve!(pm, system, settings, t, force=true)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm.topology)
    end

    @testset "t=6, L3, L4 and L8 on outage" begin
        t=6
        pm.topology.branches_available[3] = 0
        pm.topology.branches_available[4] = 0
        pm.topology.branches_available[8] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.7703; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0.2000; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.1703; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0.4000; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[2]/pm.topology.buses_curtailed_pd[2], CompositeAdequacy.field(system, :loads, :pf)[1]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[3]/pm.topology.buses_curtailed_pd[3], CompositeAdequacy.field(system, :loads, :pf)[2]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[4]/pm.topology.buses_curtailed_pd[4], CompositeAdequacy.field(system, :loads, :pf)[3]; atol = 1e-4)
        OPF._reset!(pm.topology)
    end  

    @testset "t=7, L2 and L7 on outage, generation reduced" begin
        t=7
        pm.topology.branches_available[2] = 0
        pm.topology.branches_available[7] = 0
        pm.topology.generators_available[1] = 0
        pm.topology.generators_available[2] = 0
        pm.topology.generators_available[3] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0.9792; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0.8500; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0.1292; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[4]/pm.topology.buses_curtailed_pd[4], CompositeAdequacy.field(system, :loads, :pf)[3]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[6]/pm.topology.buses_curtailed_pd[6], CompositeAdequacy.field(system, :loads, :pf)[5]; atol = 1e-4)
        OPF._reset!(pm.topology)
    end

    @testset "t=8, No outages" begin
        t=8
        OPF.solve!(pm, system, settings, t, force=true)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm.topology)
    end
end

@testset "RTS system, test sequentially split situations w/o isolated buses, RTS system, LPACCPowerModel" begin

    settings = CompositeSystems.Settings(;
        optimizer = juniper_optimizer,
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.LPACCPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = false,
        set_string_names_on_creation = true
    )

    timeseriesfile = "test/data/RTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RTS/Base/RTS.m"
    reliabilityfile = "test/data/RTS/Base/R_RTS.m"
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)

    CompositeSystems.field(system, :loads, :cost)[:] = [
        8981.5; 7360.6; 5899; 9599.2; 9232.3; 6523.8; 
        7029.1; 7774.2; 3662.3; 5194; 7281.3; 4371.7; 
        5974.4; 7230.5; 5614.9; 4543; 5683.6;
    ]

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
    OPF.build_problem!(pm, system)

    @testset "t=1, No outages" begin
        t=1
        OPF.solve!(pm, system, settings, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm.topology)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF.solve!(pm, system, settings, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm.topology)
    end

    @testset "t=3, Outages on L29, L36, L37" begin
        t=3
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.9107; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 12.3390; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[19]/pm.topology.buses_curtailed_pd[19], CompositeAdequacy.field(system, :loads, :pf)[16]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[20]/pm.topology.buses_curtailed_pd[20], CompositeAdequacy.field(system, :loads, :pf)[17]; atol = 1e-4)
        OPF._reset!(pm.topology)
    end

    @testset "t=4, No outages" begin
        t=4
        OPF.solve!(pm, system, settings, t, force=true)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm.topology)
    end

    @testset "t=5, Outages on L25, L26, L28" begin
        t=5
        pm.topology.branches_available[25] = 0
        pm.topology.branches_available[26] = 0
        pm.topology.branches_available[28] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 2.3543; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 1.75; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0.6043; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.8532; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 6.6026; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[9]/pm.topology.buses_curtailed_pd[9], CompositeAdequacy.field(system, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[14]/pm.topology.buses_curtailed_pd[14], CompositeAdequacy.field(system, :loads, :pf)[12]; atol = 1e-4)
        OPF._reset!(pm.topology)
    end

    @testset "t=6, Outages on L1, L8, L10" begin
        t=6
        pm.topology.branches_available[1] = 0
        pm.topology.branches_available[8] = 0
        pm.topology.branches_available[10] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 1.1654; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 1.1654; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.7494; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.2094; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[6]/pm.topology.buses_curtailed_pd[6], CompositeAdequacy.field(system, :loads, :pf)[6]; atol = 1e-4)
        OPF._reset!(pm.topology)
    end

    @testset "t=7, Outages on L7, L19, L29" begin
        t=7
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[19] = 0
        pm.topology.branches_available[29] = 0
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.5599; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 10.1106; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm.topology)
    end

    @testset "t=8, Outages on L7, L23, L29" begin
        t=8
        pm.topology.branches_available[7] = 0
        pm.topology.branches_available[23] = 0
        pm.topology.branches_available[29] = 0
        OPF.solve!(pm, system, settings, t)
        @test isapprox(sum(pm.topology.buses_curtailed_pd[:]), 1.9487; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[1], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[2], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[3], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[4], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[5], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[6], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[7], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[8], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[9], 1.75; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[10], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[11], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[12], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[13], 0; atol = 1e-4)
        @test isapprox(pm.topology.buses_curtailed_pd[14], 0.1987; atol = 1e-4)
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
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 27.4628; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 8.2908; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[9]/pm.topology.buses_curtailed_pd[9], CompositeAdequacy.field(system, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[14]/pm.topology.buses_curtailed_pd[14], CompositeAdequacy.field(system, :loads, :pf)[12]; atol = 1e-4)
        OPF._reset!(pm.topology)
    end
end
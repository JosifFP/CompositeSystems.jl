#include(joinpath(@__DIR__, "..","solvers.jl"))

@testset "test 5 Split situations with isolated buses, RBTS system" begin

    settings = CompositeSystems.Settings(
        juniper_optimizer_1;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = true,
        deactivate_isolated_bus_gens_stors = true
    )

    settings_2 = CompositeSystems.Settings(
        juniper_optimizer_1;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = false
    )

    rawfile = "test/data/RBTS/Base/RBTS.m"
    reliabilityfile = "test/data/RBTS/Base/R_RBTS_FULL.m"
    system = BaseModule.SystemModel(rawfile, reliabilityfile)
    CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    pm = OPF.abstract_model(system, settings)
    OPF.build_problem!(pm, system)
    state = OPF.States(system)
    t=1

    @testset "G3, G7, G8 and G9 on outage" begin
        state.generators_available[3] = 0
        state.generators_available[7] = 0
        state.generators_available[8] = 0
        state.generators_available[9] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.35; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0.35; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(OPF.topology(pm, :buses_curtailed_pd)[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end
    
    @testset "L5 and L8 on outage" begin
        state.branches_available[5] = 0
        state.branches_available[8] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.4; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0.2; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(OPF.topology(pm, :buses_curtailed_pd)[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "L5 and L8 on outage" begin
        state.branches_available[5] = 0
        state.branches_available[8] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.4; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0.2; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(OPF.topology(pm, :buses_curtailed_pd)[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "L3, L4 and L8 on outage, largest system selected" begin
        state.branches_available[3] = 0
        state.branches_available[4] = 0
        state.branches_available[8] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.750; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0.2; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0.150; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0.4; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(OPF.topology(pm, :buses_curtailed_pd)[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "L3, L4 and L8 on outage" begin
        state.branches_available[3] = 0
        state.branches_available[4] = 0
        state.branches_available[8] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.150; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0.150; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(OPF.topology(pm, :buses_curtailed_pd)[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "G3, G7, G8 and G11 on outage" begin
        state.generators_available[3] = 0
        state.generators_available[7] = 0
        state.generators_available[8] = 0
        state.generators_available[11] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.35; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0.35; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(OPF.topology(pm, :buses_curtailed_pd)[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "L2 and L7 on outage, generation reduced" begin
        state.branches_available[2] = 0
        state.branches_available[7] = 0
        state.generators_available[1] = 0
        state.generators_available[2] = 0
        state.generators_available[3] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.74; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0.74; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(OPF.topology(pm, :buses_curtailed_pd)[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end
end

@testset "test 7 Split situations with isolated buses, IEEE-RTS system" begin
    
    settings = CompositeSystems.Settings(
        juniper_optimizer_1;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = true,
        deactivate_isolated_bus_gens_stors = true
    )

    settings_2 = CompositeSystems.Settings(
        juniper_optimizer_1;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = false
    )

    rawfile = "test/data/RTS/Base/RTS.m"
    reliabilityfile = "test/data/RTS/Base/R_RTS.m"
    system = BaseModule.SystemModel(rawfile, reliabilityfile)

    CompositeSystems.field(system, :loads, :cost)[:] = [
        8981.5; 7360.6; 5899; 9599.2; 9232.3; 6523.8; 
        7029.1; 7774.2; 3662.3; 5194; 7281.3; 4371.7; 
        5974.4; 7230.5; 5614.9; 4543; 5683.6;
    ]
    
    pm = OPF.abstract_model(system, settings)
    state = OPF.States(system)
    OPF.build_problem!(pm, system)
    t=1

    @testset "Outages on L12, L13" begin
        state.branches_available[12] = 0
        state.branches_available[13] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end    
    
    @testset "Outages on L12, L13" begin
        state.branches_available[12] = 0
        state.branches_available[13] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 2.9600; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 1.25; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 1.71; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "Outages on L1, L4, L10" begin
        state.branches_available[1] = 0
        state.branches_available[4] = 0
        state.branches_available[10] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.410; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0.410; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "Outages on L1, L8, L10" begin
        state.branches_available[1] = 0
        state.branches_available[8] = 0
        state.branches_available[10] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 1.150; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 1.150; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "Outages on L7, L19, L29" begin
        state.branches_available[7] = 0
        state.branches_available[19] = 0
        state.branches_available[29] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "Outages on L7, L23, L29" begin
        state.branches_available[7] = 0
        state.branches_available[23] = 0
        state.branches_available[29] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 1.65; atol = 1e-2)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 1.65; atol = 1e-2)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "Outages on L25, L26, L28" begin
        state.branches_available[25] = 0
        state.branches_available[26] = 0
        state.branches_available[28] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 5.45; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 1.75; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0.37; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 3.33; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "Outages on L25, L26, L28" begin
        state.branches_available[25] = 0
        state.branches_available[26] = 0
        state.branches_available[28] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 2.12; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 1.75; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0.37; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "Outages on L29, L36, L37" begin
        state.branches_available[29] = 0
        state.branches_available[36] = 0
        state.branches_available[37] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 3.09; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 1.81; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 1.28; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "Outages on L29, L36, L37" begin
        state.branches_available[29] = 0
        state.branches_available[36] = 0
        state.branches_available[37] = 0
        OPF._update!(pm, system, state, settings_2, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 3.09; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 1.81; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 1.28; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end
end

@testset "RBTS system, test sequentially split situations w/o isolated buses, RBTS system, LPACCPowerModel" begin

    settings = CompositeSystems.Settings(
        juniper_optimizer_1;
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
    state = OPF.States(system)
    OPF.build_problem!(pm, system)

    @testset "t=1, No outages" begin
        t=1
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF._update!(pm, system, state, settings, t) 
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=3, G3, G7, G8 and G9 on outage" begin
        t=3
        state.generators_available[3] = 0
        state.generators_available[7] = 0
        state.generators_available[8] = 0
        state.generators_available[9] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.3716; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0.3716; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5000; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.1169; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[3]/OPF.topology(pm, :buses_curtailed_pd)[3], CompositeAdequacy.field(system, :loads, :pf)[2]; atol = 1e-4)
        OPF._reset!(pm, state, system)
    end
    
    @testset "t=4, L5 and L8 on outage" begin
        t=4
        state.branches_available[5] = 0
        state.branches_available[8] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.4; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0.2; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5552; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5830; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[5]/OPF.topology(pm, :buses_curtailed_pd)[5], CompositeAdequacy.field(system, :loads, :pf)[4]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[6]/OPF.topology(pm, :buses_curtailed_pd)[6], CompositeAdequacy.field(system, :loads, :pf)[5]; atol = 1e-4)
        OPF._reset!(pm, state, system)
    end

    @testset "t=5, No outages" begin
        t=5
        OPF._update!(pm, system, state, settings, t)  
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=6, L3, L4 and L8 on outage" begin
        t=6
        state.branches_available[3] = 0
        state.branches_available[4] = 0
        state.branches_available[8] = 0
        OPF._update!(pm, system, state, settings, t)  
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.7703; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0.2000; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0.1703; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0.4000; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[2]/OPF.topology(pm, :buses_curtailed_pd)[2], CompositeAdequacy.field(system, :loads, :pf)[1]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[3]/OPF.topology(pm, :buses_curtailed_pd)[3], CompositeAdequacy.field(system, :loads, :pf)[2]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[4]/OPF.topology(pm, :buses_curtailed_pd)[4], CompositeAdequacy.field(system, :loads, :pf)[3]; atol = 1e-4)
        OPF._reset!(pm, state, system)
    end  

    @testset "t=7, L2 and L7 on outage, generation reduced" begin
        t=7
        state.branches_available[2] = 0
        state.branches_available[7] = 0
        state.generators_available[1] = 0
        state.generators_available[2] = 0
        state.generators_available[3] = 0
        OPF._update!(pm, system, state, settings, t) 
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0.9792; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0.8500; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0.1292; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[4]/OPF.topology(pm, :buses_curtailed_pd)[4], CompositeAdequacy.field(system, :loads, :pf)[3]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[6]/OPF.topology(pm, :buses_curtailed_pd)[6], CompositeAdequacy.field(system, :loads, :pf)[5]; atol = 1e-4)
        OPF._reset!(pm, state, system)
    end

    @testset "t=8, No outages" begin
        t=8
        OPF._update!(pm, system, state, settings, t)  
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end
end

@testset "RTS system, test sequentially split situations w/o isolated buses, RTS system, LPACCPowerModel" begin

    settings = CompositeSystems.Settings(
        juniper_optimizer_1;
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
    state = OPF.States(system)
    OPF.build_problem!(pm, system)

    @testset "t=1, No outages" begin
        t=1
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=3, Outages on L29, L36, L37" begin
        t=3
        state.branches_available[29] = 0
        state.branches_available[36] = 0
        state.branches_available[37] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 3.09; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 1.81; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 1.28; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.9101; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 12.3378; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[19]/OPF.topology(pm, :buses_curtailed_pd)[19], CompositeAdequacy.field(system, :loads, :pf)[16]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[20]/OPF.topology(pm, :buses_curtailed_pd)[20], CompositeAdequacy.field(system, :loads, :pf)[17]; atol = 1e-4)
        OPF._reset!(pm, state, system)
    end

    @testset "t=4, No outages" begin
        t=4
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 30.1971; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.1221; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=5, Outages on L25, L26, L28" begin
        t=5
        state.branches_available[25] = 0
        state.branches_available[26] = 0
        state.branches_available[28] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 2.3544; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 1.75; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0.6044; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.8532; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 6.6031; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[9]/OPF.topology(pm, :buses_curtailed_pd)[9], CompositeAdequacy.field(system, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[14]/OPF.topology(pm, :buses_curtailed_pd)[14], CompositeAdequacy.field(system, :loads, :pf)[12]; atol = 1e-4)
        OPF._reset!(pm, state, system)
    end

    @testset "t=6, Outages on L1, L8, L10" begin
        t=6
        state.branches_available[1] = 0
        state.branches_available[8] = 0
        state.branches_available[10] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 1.1654; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 1.1654; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.7494; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 14.2094; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[6]/OPF.topology(pm, :buses_curtailed_pd)[6], CompositeAdequacy.field(system, :loads, :pf)[6]; atol = 1e-4)
        OPF._reset!(pm, state, system)
    end

    @testset "t=7, Outages on L7, L19, L29" begin
        t=7
        state.branches_available[7] = 0
        state.branches_available[19] = 0
        state.branches_available[29] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.5599; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 10.1106; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=8, Outages on L7, L23, L29" begin
        t=8
        state.branches_available[7] = 0
        state.branches_available[23] = 0
        state.branches_available[29] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 1.9497; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 1.75; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0.1997; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 27.4628; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 8.3110; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[9]/OPF.topology(pm, :buses_curtailed_pd)[9], CompositeAdequacy.field(system, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_qd)[14]/OPF.topology(pm, :buses_curtailed_pd)[14], CompositeAdequacy.field(system, :loads, :pf)[12]; atol = 1e-4)
        OPF._reset!(pm, state, system)
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

    timeseriesfile = "test/data/RTS/SYSTEM_LOADS.xlsx"
    rawfile = "test/data/RTS/Base/RTS.m"
    reliabilityfile = "test/data/RTS/Base/R_RTS.m"
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)

    CompositeSystems.field(system, :loads, :cost)[:] = [
        8981.5; 7360.6; 5899; 9599.2; 9232.3; 6523.8; 
        7029.1; 7774.2; 3662.3; 5194; 7281.3; 4371.7; 
        5974.4; 7230.5; 5614.9; 4543; 5683.6;
    ]

    # CompositeSystems.field(system, :loads, :cost)[:] = [
    #     6200.0; 4890.0; 5300.0; 5620.0; 6110.0; 5500.0; 
    #     5410.0; 5400.0; 2300.0; 4140.0; 5390.0; 3410.0;
    #     3010.0; 3540.0; 3750.0; 2290.0; 3640.0;
    # ]

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
    state = OPF.States(system)
    OPF.build_problem!(pm, system)

    @testset "t=1, No outages" begin
        t=1
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=2, No outages" begin
        t=2
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=3, Outages on L29, L36, L37" begin
        t=3
        state.branches_available[29] = 0
        state.branches_available[36] = 0
        state.branches_available[37] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 3.09; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 1.81; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 1.28; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-3.09; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=4, No outages" begin
        t=4
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=5, Outages on L25, L26, L28" begin
        t=5
        state.branches_available[25] = 0
        state.branches_available[26] = 0
        state.branches_available[28] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 2.12; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 1.75; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0.37; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 2.12; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=6, Outages on L1, L8, L10" begin
        t=6
        state.branches_available[1] = 0
        state.branches_available[8] = 0
        state.branches_available[10] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 1.150; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 1.150; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 1.150; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1, atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=7, Outages on L7, L19, L29" begin
        t=7
        state.branches_available[7] = 0
        state.branches_available[19] = 0
        state.branches_available[29] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

    @testset "t=8, Outages on L7, L23, L29" begin
        t=8
        state.branches_available[7] = 0
        state.branches_available[23] = 0
        state.branches_available[29] = 0
        OPF._update!(pm, system, state, settings, t)
        @test isapprox(sum(OPF.topology(pm, :buses_curtailed_pd)[:]), 1.65; atol = 1e-2)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[1], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[2], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[3], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[4], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[5], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[6], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[7], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[8], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[9], 1.65; atol = 1e-2)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[10], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[11], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[12], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[13], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[14], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[15], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[16], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[17], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[18], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[19], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[20], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[21], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[22], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[23], 0; atol = 1e-4)
        @test isapprox(OPF.topology(pm, :buses_curtailed_pd)[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-1.65; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        OPF._reset!(pm, state, system)
    end

end
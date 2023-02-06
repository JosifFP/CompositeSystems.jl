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

    rawfile = "test/data/RBTS/Base/RBTS_AC.m"
    reliabilityfile = "test/data/RBTS/Base/R_RBTS_FULL.m"
    system = BaseModule.SystemModel(rawfile, reliabilityfile)
    CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    pm = OPF.abstract_model(system, settings)
    systemstates = OPF.SystemStates(system, available=true)
    CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
    t=1

    @testset "G3, G7, G8 and G9 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        CompositeSystems.field(systemstates, :generators)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[8,t] = 0
        CompositeSystems.field(systemstates, :generators)[9,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
        @test isapprox(sum(systemstates.plc[:]), 0.35; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.35; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        
    end
    
    @testset "L5 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[5,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
        @test isapprox(sum(systemstates.plc[:]), 0.4; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0.2; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "L5 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[5,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
        @test isapprox(sum(systemstates.plc[:]), 0.4; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0.2; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "L3, L4 and L8 on outage, largest system selected" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)
        @test isapprox(sum(systemstates.plc[:]), 0.750; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0.2; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.150; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0.4; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "L3, L4 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
        @test isapprox(sum(systemstates.plc[:]), 0.150; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.150; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "G3, G7, G8 and G11 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        CompositeSystems.field(systemstates, :generators)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[8,t] = 0
        CompositeSystems.field(systemstates, :generators)[11,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
        @test isapprox(sum(systemstates.plc[:]), 0.35; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.35; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "L2 and L7 on outage, generation reduced" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[2,t] = 0
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[1,t] = 0
        CompositeSystems.field(systemstates, :generators)[2,t] = 0
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
        @test isapprox(sum(systemstates.plc[:]), 0.74; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.74; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]); atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
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

    CompositeSystems.field(system, :loads, :cost)[:] = 
        [8981.5; 7360.6; 5899; 9599.2; 9232.3; 6523.8; 7029.1; 
        7774.2; 3662.3; 5194; 7281.3; 4371.7; 5974.4; 7230.5; 5614.9; 4543; 5683.6
    ]
    
    pm = OPF.abstract_model(system, settings)
    systemstates = OPF.SystemStates(system, available=true)
    CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
    t=1

    @testset "Outages of L12, L13" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[12,t] = 0
        CompositeSystems.field(systemstates, :branches)[13,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end    
    
    @testset "Outages of L12, L13" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[12,t] = 0
        CompositeSystems.field(systemstates, :branches)[13,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)
        @test isapprox(sum(systemstates.plc[:]), 2.9600; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7], 1.25; atol = 1e-4)
        @test isapprox(systemstates.plc[8], 1.71; atol = 1e-4)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "Outages of L1, L4, L10" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[1,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[10,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
        @test isapprox(sum(systemstates.plc[:]), 0.410; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0.410; atol = 1e-4)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "Outages of L1, L8, L10" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[1,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        CompositeSystems.field(systemstates, :branches)[10,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "Outages of L7, L19, L29" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :branches)[19,t] = 0
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "Outages of L7, L23, L29" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :branches)[23,t] = 0
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "Outages of L25, L26, L28" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[25,t] = 0
        CompositeSystems.field(systemstates, :branches)[26,t] = 0
        CompositeSystems.field(systemstates, :branches)[28,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)
        @test isapprox(sum(systemstates.plc[:]), 5.45; atol = 1e-4)
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
        @test isapprox(systemstates.plc[18], 3.33; atol = 1e-4)
        @test isapprox(systemstates.plc[19], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "Outages of L25, L26, L28" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[25,t] = 0
        CompositeSystems.field(systemstates, :branches)[26,t] = 0
        CompositeSystems.field(systemstates, :branches)[28,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "Outages of L29, L36, L37" begin
        systemstates = OPF.SystemStates(system, available=true)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "Outages of L29, L36, L37" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        CompositeSystems.field(systemstates, :branches)[36,t] = 0
        CompositeSystems.field(systemstates, :branches)[37,t] = 0
        OPF._update!(pm, system, systemstates, settings_2, t)
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
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

end

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
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
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
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
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
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
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
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371; atol = 1e-4) 
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231; atol = 1e-4) 
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
#include(joinpath(@__DIR__, "..","solvers.jl"))

settings = CompositeSystems.Settings(gurobi_optimizer_2, modelmode = JuMP.AUTOMATIC, powermodel = OPF.DCPPowerModel)
#settings = CompositeSystems.Settings(juniper_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.DCPPowerModel)

@testset "test 5 Split situations with isolated buses, RBTS system" begin

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
        OPF._update!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.35; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.35; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
        @test isapprox(pg, 1.5; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        
    end
    
    @testset "L5 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[5,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.4; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0.2; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0.2; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "L5 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[5,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        pm.topology.isolated_bus_gens[1] = 0
        OPF._update!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.4; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0.2; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0.2; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        pm.topology.isolated_bus_gens[1] = 1
    end

    @testset "L3, L4 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.750; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0.2; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.150; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0.4; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

    @testset "L3, L4 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        pm.topology.isolated_bus_gens[1] = 0
        OPF._update!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.150; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.150; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
        @test isapprox(pg, 1.7; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        pm.topology.isolated_bus_gens[1] = 1
    end

    @testset "G3, G7, G8 and G11 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        CompositeSystems.field(systemstates, :generators)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[8,t] = 0
        CompositeSystems.field(systemstates, :generators)[11,t] = 0
        OPF._update!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.35; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.35; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
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
        OPF._update!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.74; atol = 1e-4)
        @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3], 0.74; atol = 1e-4)
        @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    end

end

@testset "test 7 Split situations with isolated buses, IEEE-RTS system" begin

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
        pm.topology.isolated_bus_gens[1] = 0
        OPF._update!(pm, system, systemstates, t)
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
        pm.topology.isolated_bus_gens[1] = 1
    end    
    
    @testset "Outages of L12, L13" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[12,t] = 0
        CompositeSystems.field(systemstates, :branches)[13,t] = 0
        OPF._update!(pm, system, systemstates, t)
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
        pm.topology.isolated_bus_gens[1] = 0
        OPF._update!(pm, system, systemstates, t)
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
        pm.topology.isolated_bus_gens[1] = 1
    end

    @testset "Outages of L1, L8, L10" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[1,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        CompositeSystems.field(systemstates, :branches)[10,t] = 0
        OPF._update!(pm, system, systemstates, t)
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
        OPF._update!(pm, system, systemstates, t)
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
        OPF._update!(pm, system, systemstates, t)
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
        OPF._update!(pm, system, systemstates, t)
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
        OPF._update!(pm, system, systemstates, t)
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
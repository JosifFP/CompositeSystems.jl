include("solvers.jl")

settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    modelmode = JuMP.AUTOMATIC,
)

@testset "test 5 Split situations RBTS system" begin

    RawFile = "test/data/RBTS/Base/RBTS.m"
    ReliabilityFile = "test/data/RBTS/Base/R_RBTS.m"
    system = BaseModule.SystemModel(RawFile, ReliabilityFile)

    CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    model = OPF.jump_model(settings.modelmode, deepcopy(settings.optimizer))
    pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)
    OPF.initialize_pm_containers!(pm, system; timeseries=false)
    t=1

    @testset "G3, G7, G8 and G9 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        CompositeSystems.field(systemstates, :generators)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[8,t] = 0
        CompositeSystems.field(systemstates, :generators)[9,t] = 0
        systemstates.system[t] = 0
        OPF.update_topology!(pm, system, systemstates, t)
        OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc), 0.35; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0.35; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
        @test isapprox(pg, 1.5; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
        

        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.1503; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0.1503; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
        @test isapprox(pg, 1.7; atol = 1e-2)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
        
    end
    
    @testset "L5 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[5,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.4; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0.2; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0.2; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
        
    end

    @testset "L3, L4 and L8 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        systemstates.system[t] = 0
       OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.150; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0.150; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
        @test isapprox(pg, 1.7; atol = 1e-2)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
        
    end

    @testset "G3, G7, G8 and G11 on outage" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        CompositeSystems.field(systemstates, :generators)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[8,t] = 0
        CompositeSystems.field(systemstates, :generators)[11,t] = 0
        systemstates.system[t] = 0
       OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.35; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0.35; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
        
    end

    @testset "L2 and L7 on outage, generation reduced" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[2,t] = 0
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[1,t] = 0
        CompositeSystems.field(systemstates, :generators)[2,t] = 0
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        systemstates.system[t] = 0
       OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 0.7045; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0.7045; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
        #println(pg)
        #println(values(OPF.build_sol_values(OPF.var(pm, :va, t))).*180/pi)
        OPF.empty_model!(pm)
        
    end

end

@testset "test 7 Split situations IEEE-RTS system" begin

    RawFile = "test/data/RTS/Base/RTS.m"
    ReliabilityFile = "test/data/RTS/Base/R_RTS.m"
    system = BaseModule.SystemModel(RawFile, ReliabilityFile)

    CompositeSystems.field(system, :loads, :cost)[:] = 
        [8981.5; 7360.6; 5899; 9599.2; 9232.3; 6523.8; 7029.1; 
        7774.2; 3662.3; 5194; 7281.3; 4371.7; 5974.4; 7230.5; 5614.9; 4543; 5683.6
    ]
    
    model = OPF.jump_model(settings.modelmode, deepcopy(settings.optimizer))
    pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)
    OPF.initialize_pm_containers!(pm, system; timeseries=false)
    t=1
    
    @testset "Outages of L12, L13" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[12,t] = 0
        CompositeSystems.field(systemstates, :branches)[13,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)

        @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
    end

    @testset "Outages of L1, L4, L10" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[1,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[10,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)

        @test isapprox(sum(systemstates.plc[:]), 0.411; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[6,t], 0.411; atol = 1e-3)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
    end

    @testset "Outages of L1, L8, L10" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[1,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        CompositeSystems.field(systemstates, :branches)[10,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)

        @test isapprox(sum(systemstates.plc[:]), 1.151; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[6,t], 1.151; atol = 1e-3)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
    end

    @testset "Outages of L7, L19, L29" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :branches)[19,t] = 0
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)

        @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
    end

    @testset "Outages of L7, L23, L29" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :branches)[23,t] = 0
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 1.65; atol = 1e-2)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[9,t], 1.65; atol = 1e-2)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
    end

    @testset "Outages of L25, L26, L28" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[25,t] = 0
        CompositeSystems.field(systemstates, :branches)[26,t] = 0
        CompositeSystems.field(systemstates, :branches)[28,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 2.12; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[9,t], 1.75; atol = 1e-3)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[12,t], 0.37; atol = 1e-3)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
    end

    @testset "Outages of L29, L36, L37" begin
        systemstates = OPF.SystemStates(system, available=true)
        CompositeSystems.field(systemstates, :branches)[29,t] = 0
        CompositeSystems.field(systemstates, :branches)[36,t] = 0
        CompositeSystems.field(systemstates, :branches)[37,t] = 0
        systemstates.system[t] = 0
        OPF.solve!(pm, system, systemstates, t)
        @test isapprox(sum(systemstates.plc[:]), 3.09; atol = 1e-3)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-3)
        @test isapprox(systemstates.plc[16,t], 1.81; atol = 1e-3)
        @test isapprox(systemstates.plc[17,t], 1.28; atol = 1e-3)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        OPF.empty_model!(pm)
    end

end
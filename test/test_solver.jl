
@testset "test 4 Split situations RBTS system" begin

    nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
    optimizer = optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])

    RawFile = "test/data/RBTS.m"
    system = PRATSBase.SystemModel(RawFile)
    CompositeAdequacy.field(system, Loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]

    pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCOPF, Model(optimizer; add_bridges = false), CompositeAdequacy.Topology(system))
    t=1
    
    @testset "L5 and L8 on outage" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[5,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[8,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)
        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0.2; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0.2; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "L3, L4 and L8 on outage" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[3,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[4,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[8,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)
        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0.1503; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "G3, 7, 8 and 11 on outage" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :generators)[3] = 0
        CompositeAdequacy.field(systemstates, :generators)[7] = 0
        CompositeAdequacy.field(systemstates, :generators)[8] = 0
        CompositeAdequacy.field(systemstates, :generators)[11] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)
        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0.35; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "L2 and L7 on outage, generation reduced" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[2,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[7,t] = 0
        CompositeAdequacy.field(systemstates, :generators)[1,t] = 0
        CompositeAdequacy.field(systemstates, :generators)[2,t] = 0
        CompositeAdequacy.field(systemstates, :generators)[3,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)
        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0.7046; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

end

@testset "test 4 Split situations RTS system" begin

    nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
    optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])

    RawFile = "test/data/RTS.m"
    system = PRATSBase.SystemModel(RawFile)
    CompositeAdequacy.field(system, Loads, :cost)[:] = [6240; 4890; 5300; 5620; 6110; 5500; 5410; 5400; 2300; 4140; 5390; 3410; 3010; 3540; 3750; 2290; 3640]

    pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCOPF, JuMP.Model(optimizer; add_bridges = false), CompositeAdequacy.Topology(system))
    t=1
    
    @testset "Outages of L12, L13" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[12,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[13,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)

        @test isapprox(sum(values(pm.topology.plc)[:,t]), 0; atol = 1e-3)

        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[6,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[7,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[8,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[9,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[10,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[11,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[12,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[13,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[14,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[15,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[16,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "Outages of L1, L4, L10" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[1,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[4,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[10,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)

        @test isapprox(sum(values(pm.topology.plc)[:,t]), 0.4111; atol = 1e-3)

        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0.4111; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[6,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[7,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[8,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[9,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[10,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[11,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[12,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[13,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[14,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[15,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[16,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "Outages of L1, L8, L10" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[1,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[8,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[10,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)

        @test isapprox(sum(values(pm.topology.plc)[:,t]), 1.151; atol = 1e-3)

        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0.97; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[6,t], 0.1812; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[7,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[8,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[9,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[10,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[11,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[12,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[13,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[14,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[15,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[16,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "Outages of L7, L19, L29" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[7,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[19,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[29,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)

        @test isapprox(sum(values(pm.topology.plc)[:,t]), 0; atol = 1e-3)

        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[6,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[7,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[8,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[9,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[10,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[11,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[12,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[13,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[14,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[15,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[16,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "Outages of L7, L23, L29" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[7,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[23,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[29,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)

        @test isapprox(sum(values(pm.topology.plc)[:,t]), 1.653; atol = 1e-3)

        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[6,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[7,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[8,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[9,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[10,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[11,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[12,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[13,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[14,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[15,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[16,t], 1.653; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "Outages of L25, L26, L28" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[25,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[26,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[28,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)

        @test isapprox(sum(values(pm.topology.plc)[:,t]), 2.125; atol = 1e-3)

        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[6,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[7,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[8,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[9,t], 0.3147; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[10,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[11,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[12,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[13,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[14,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[15,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[16,t], 1.81; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

    @testset "Outages of L29, L36, L37" begin
        systemstates = CompositeAdequacy.SystemStates(system)
        CompositeAdequacy.field(systemstates, :branches)[29,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[36,t] = 0
        CompositeAdequacy.field(systemstates, :branches)[37,t] = 0
        CompositeAdequacy.field(systemstates, :condition)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, systemstates, system, t)

        @test isapprox(sum(values(pm.topology.plc)[:,t]), 3.09; atol = 1e-3)

        @test isapprox(values(pm.topology.plc)[1,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[2,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[3,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[4,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[5,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[6,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[7,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[8,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[9,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[10,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[11,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[12,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[13,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[14,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[15,t], 0; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[16,t], 1.81; atol = 1e-3)
        @test isapprox(values(pm.topology.plc)[17,t], 1.28; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm)
    end

end
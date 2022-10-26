
@testset "test 5 Split situations RBTS system" begin

    RawFile = "test/data/RBTS.m"
    nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
    optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])
    
    system = PRATSBase.SystemModel(RawFile)
    field(system, CompositeAdequacy.Loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    method = PRATS.SequentialMCS(samples=1, seed=1, threaded=false)
    pm = CompositeAdequacy.PowerFlowProblem(system, method, field(method, :settings))
    t=1

    @testset "G3, G7, G8 and G9 on outage" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :generators)[3,t] = 0
        field(systemstates, :generators)[7,t] = 0
        field(systemstates, :generators)[8,t] = 0
        field(systemstates, :generators)[9,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 0.35; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0.35; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        pg = sum(values(CompositeAdequacy.build_sol_values(CompositeAdequacy.var(pm, :pg, 0))))
        @test isapprox(pg, 1.5; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end
    
    @testset "L5 and L8 on outage" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[5,t] = 0
        field(systemstates, :branches)[8,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 0.4; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0.2; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0.2; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "L3, L4 and L8 on outage" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[3,t] = 0
        field(systemstates, :branches)[4,t] = 0
        field(systemstates, :branches)[8,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 0.1503; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0.1503; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        pg = sum(values(CompositeAdequacy.build_sol_values(CompositeAdequacy.var(pm, :pg, 0))))
        @test isapprox(pg, 1.699; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "G3, G7, G8 and G11 on outage" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :generators)[3,t] = 0
        field(systemstates, :generators)[7,t] = 0
        field(systemstates, :generators)[8,t] = 0
        field(systemstates, :generators)[11,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 0.35; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0.35; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "L2 and L7 on outage, generation reduced" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[2,t] = 0
        field(systemstates, :branches)[7,t] = 0
        field(systemstates, :generators)[1,t] = 0
        field(systemstates, :generators)[2,t] = 0
        field(systemstates, :generators)[3,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 0.7046; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0.65; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0.0542; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

end

@testset "test 7 Split situations IEEE-RTS system" begin

    optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
    #optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])

    RawFile = "test/data/RTS.m"
    system = PRATSBase.SystemModel(RawFile)
    field(system, CompositeAdequacy.Loads, :cost)[:] = [6240; 4890; 5300; 5620; 6110; 5500; 5410; 5400; 2300; 4140; 5390; 3410; 3010; 3540; 3750; 2290; 3640]
    method = PRATS.SequentialMCS(samples=1, seed=1, threaded=false)
    pm = CompositeAdequacy.PowerFlowProblem(system, method, field(method, :settings))
    t=1
    
    @testset "Outages of L12, L13" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[12,t] = 0
        field(systemstates, :branches)[13,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)

        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 0; atol = 1e-3)

        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[6,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[7,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[8,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[9,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[10,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[11,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[12,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[13,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[14,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[15,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[16,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "Outages of L1, L4, L10" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[1,t] = 0
        field(systemstates, :branches)[4,t] = 0
        field(systemstates, :branches)[10,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)

        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 0.4111; atol = 1e-3)

        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0.4111; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[6,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[7,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[8,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[9,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[10,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[11,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[12,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[13,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[14,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[15,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[16,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "Outages of L1, L8, L10" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[1,t] = 0
        field(systemstates, :branches)[8,t] = 0
        field(systemstates, :branches)[10,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)

        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 1.151; atol = 1e-3)

        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0.411; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0.74; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[6,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[7,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[8,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[9,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[10,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[11,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[12,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[13,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[14,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[15,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[16,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "Outages of L7, L19, L29" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[7,t] = 0
        field(systemstates, :branches)[19,t] = 0
        field(systemstates, :branches)[29,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)

        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 0; atol = 1e-3)

        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[6,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[7,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[8,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[9,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[10,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[11,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[12,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[13,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[14,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[15,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[16,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "Outages of L7, L23, L29" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[7,t] = 0
        field(systemstates, :branches)[23,t] = 0
        field(systemstates, :branches)[29,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)

        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 1.653; atol = 1e-3)

        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[6,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[7,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[8,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[9,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[10,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[11,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[12,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[13,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[14,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[15,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[16,t], 1.653; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "Outages of L25, L26, L28" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[25,t] = 0
        field(systemstates, :branches)[26,t] = 0
        field(systemstates, :branches)[28,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)

        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 2.125; atol = 1e-3)

        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[6,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[7,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[8,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[9,t], 0.3147; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[10,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[11,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[12,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[13,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[14,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[15,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[16,t], 1.81; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[17,t], 0; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

    @testset "Outages of L29, L36, L37" begin
        systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
        field(systemstates, :branches)[29,t] = 0
        field(systemstates, :branches)[36,t] = 0
        field(systemstates, :branches)[37,t] = 0
        field(systemstates, :system)[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)

        @test isapprox(sum(values(field(pm, Topology, :plc))[:]), 3.09; atol = 1e-3)

        @test isapprox(values(field(pm, Topology, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[2,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[5,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[6,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[7,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[8,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[9,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[10,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[11,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[12,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[13,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[14,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[15,t], 0; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[16,t], 1.81; atol = 1e-3)
        @test isapprox(values(field(pm, Topology, :plc))[17,t], 1.28; atol = 1e-3)
        CompositeAdequacy.empty_model!(pm,t)
    end

end
include("solvers.jl")

settings = PRATS.Settings(
    juniper_optimizer_2, 
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)


@testset "test 5 Split situations RBTS system" begin

    TimeSeriesFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/Loads.xlsx"
    RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/RBTS.m"
    ReliabilityFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS/R_RBTS.m"
    
    timeseries_load, SParametrics = extract_timeseriesload(TimeSeriesFile)
    system = SystemModel(RawFile, ReliabilityFile, timeseries_load, SParametrics)

    field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]

    method = PRATS.SequentialMCS(samples=1, seed=1, threaded=false)
    topology = Topology(system)
    pm = Initialize_model(system, topology, settings)
    systemstates = SystemStates(system, method)

    @testset "G3, G7, G8 and G9 on outage" begin
        t=1
        field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
        field(systemstates, :generators)[3,t] = 0
        field(systemstates, :generators)[7,t] = 0
        field(systemstates, :generators)[8,t] = 0
        field(systemstates, :generators)[9,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:,t]), 0.35; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0.35; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0; atol = 1e-3)
        pg = sum(values(CompositeAdequacy.build_sol_values(CompositeAdequacy.var(pm, :pg, 0))))
        @test isapprox(pg, 1.5; atol = 1e-3)
        CompositeAdequacy.empty!(pm.model)
        
        t=2
        field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
        field(systemstates, :branches)[3,t] = 0
        field(systemstates, :branches)[4,t] = 0
        field(systemstates, :branches)[8,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:,t]), 0.1503; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0.1503; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0; atol = 1e-3)
        pg = sum(values(CompositeAdequacy.build_sol_values(CompositeAdequacy.var(pm, :pg, 0))))
        @test isapprox(pg, 1.699; atol = 1e-3)
        CompositeAdequacy.empty!(pm.model)
        
        t=3
        field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
        field(systemstates, :branches)[2,t] = 0
        field(systemstates, :branches)[7,t] = 0
        field(systemstates, :generators)[1,t] = 0
        field(systemstates, :generators)[2,t] = 0
        field(systemstates, :generators)[3,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:,t]), 0.7046; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0.7046; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0; atol = 1e-3)
        CompositeAdequacy.empty!(pm.model)
        
    end
    
    @testset "L5 and L8 on outage" begin
        t=4
        field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
        field(systemstates, :branches)[5,t] = 0
        field(systemstates, :branches)[8,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:,t]), 0.4; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0.2; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0.2; atol = 1e-3)
        CompositeAdequacy.empty!(pm.model)
        
    end

    @testset "L3, L4 and L8 on outage" begin
        t=5
        field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
        field(systemstates, :branches)[3,t] = 0
        field(systemstates, :branches)[4,t] = 0
        field(systemstates, :branches)[8,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:,t]), 0.1503; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0.1503; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0; atol = 1e-3)
        pg = sum(values(CompositeAdequacy.build_sol_values(CompositeAdequacy.var(pm, :pg, 0))))
        @test isapprox(pg, 1.699; atol = 1e-3)
        CompositeAdequacy.empty!(pm.model)
        
    end

    @testset "G3, G7, G8 and G11 on outage" begin
        t=6
        field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
        field(systemstates, :generators)[3,t] = 0
        field(systemstates, :generators)[7,t] = 0
        field(systemstates, :generators)[8,t] = 0
        field(systemstates, :generators)[11,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:,t]), 0.35; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0.35; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0; atol = 1e-3)
        CompositeAdequacy.empty!(pm.model)
        
    end

    @testset "L2 and L7 on outage, generation reduced" begin
        t=7
        field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
        field(systemstates, :branches)[2,t] = 0
        field(systemstates, :branches)[7,t] = 0
        field(systemstates, :generators)[1,t] = 0
        field(systemstates, :generators)[2,t] = 0
        field(systemstates, :generators)[3,t] = 0
        systemstates.system[t] = 0
        CompositeAdequacy.update!(pm.topology, systemstates, system, t)
        CompositeAdequacy.solve!(pm, system, t)
        @test isapprox(sum(values(sol(pm, :plc))[:,t]), 0.7046; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[1,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[2,t], 0.7046; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[3,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[4,t], 0; atol = 1e-3)
        @test isapprox(values(sol(pm, :plc))[5,t], 0; atol = 1e-3)
        CompositeAdequacy.empty!(pm.model)
        
    end

end
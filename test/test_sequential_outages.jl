
@testset "test sequentially 5 Split situations RBTS system, LPACCPowerModel" begin

    settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
    #settings = CompositeSystems.Settings(ipopt_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
    rawfile = "test/data/RBTS/Base/RBTS.m"
    reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
    for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
    CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    model = OPF.jump_model(JuMP.AUTOMATIC, deepcopy(settings.optimizer))
    pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)
    systemstates = OPF.SystemStates(system, available=true)
    CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
    
    t=2
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.91; atol = 1e-2)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.39; atol = 1e-2)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=3
    CompositeSystems.field(systemstates, :generators_de)[3,t] = 0
    CompositeSystems.field(systemstates, :generators_de)[7,t] = 0
    CompositeSystems.field(systemstates, :generators_de)[8,t] = 0
    CompositeSystems.field(systemstates, :generators_de)[9,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "G3, G7, G8 and G9 on outage" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0.37; atol = 1e-2)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0.37; atol = 1e-2)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5; atol = 1e-2)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.11; atol = 1e-2)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=4
    CompositeSystems.field(systemstates, :branches)[5,t] = 0
    CompositeSystems.field(systemstates, :branches)[8,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)
    
    @testset "L5 and L8 on outage" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0.4; atol = 1e-2)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0.2; atol = 1e-2)
        @test isapprox(systemstates.plc[5,t], 0.2; atol = 1e-2)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=5
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.91; atol = 1e-2)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.40; atol = 1e-2)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=6
    CompositeSystems.field(systemstates, :branches)[3,t] = 0
    CompositeSystems.field(systemstates, :branches)[4,t] = 0
    CompositeSystems.field(systemstates, :branches)[8,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "L3, L4 and L8 on outage" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0.17; atol = 1e-2)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0.17; atol = 1e-2)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR  
    end

    t=7
    CompositeSystems.field(systemstates, :branches)[2,t] = 0
    CompositeSystems.field(systemstates, :branches)[7,t] = 0
    CompositeSystems.field(systemstates, :generators_de)[1,t] = 0
    CompositeSystems.field(systemstates, :generators_de)[2,t] = 0
    CompositeSystems.field(systemstates, :generators_de)[3,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)   

    @testset "L2 and L7 on outage, generation reduced" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0.97; atol = 1e-2)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0.84; atol = 1e-2)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0.129; atol = 1e-2)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

end

@testset "test sequentially split situations RBTS system, LPACCPowerModel" begin

    settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
    #settings = CompositeSystems.Settings(ipopt_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
    rawfile = "test/data/RBTS/Base/RBTS_AC.m"
    reliabilityfile = "test/data/RBTS/Base/R_RBTS_FULL.m"
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
    for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
    CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
    model = OPF.jump_model(JuMP.AUTOMATIC, deepcopy(settings.optimizer), string_names = true)
    pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)
    systemstates = OPF.SystemStates(system, available=true)
    CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)

    t=2
    OPF._update!(pm, system, systemstates, t)  

    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9165; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.4124; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=3
    CompositeSystems.field(systemstates, :generators)[3,t] = 0
    CompositeSystems.field(systemstates, :generators)[7,t] = 0
    CompositeSystems.field(systemstates, :generators)[8,t] = 0
    CompositeSystems.field(systemstates, :generators)[9,t] = 0
    systemstates.system[t] = 0
    OPF._update!(pm, system, systemstates, t)

    @testset "G3, G7, G8 and G9 on outage" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0.3731; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0.3731; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5000; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.1245; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test isapprox(systemstates.qlc[3,t]/systemstates.plc[3,t], CompositeAdequacy.field(system, :loads, :pf)[2]; atol = 1e-4)
    end

    t=4
    CompositeSystems.field(systemstates, :branches)[5,t] = 0
    CompositeSystems.field(systemstates, :branches)[8,t] = 0
    systemstates.system[t] = 0
    OPF._update!(pm, system, systemstates, t)
    
    @testset "L5 and L8 on outage" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0.4; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0.2; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0.2; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.5146; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.3693; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test isapprox(systemstates.qlc[5,t]/systemstates.plc[5,t], CompositeAdequacy.field(system, :loads, :pf)[4]; atol = 1e-4)
        @test isapprox(systemstates.qlc[6,t]/systemstates.plc[6,t], CompositeAdequacy.field(system, :loads, :pf)[5]; atol = 1e-4)
    end

    t=5
    OPF._update!(pm, system, systemstates, t)  

    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9165; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.4124; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=6
    CompositeSystems.field(systemstates, :branches)[3,t] = 0
    CompositeSystems.field(systemstates, :branches)[4,t] = 0
    CompositeSystems.field(systemstates, :branches)[8,t] = 0
    systemstates.system[t] = 0
    OPF._update!(pm, system, systemstates, t)  

    @testset "L3, L4 and L8 on outage" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0.1717; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0.1717; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR  
        @test isapprox(systemstates.qlc[3,t]/systemstates.plc[3,t], CompositeAdequacy.field(system, :loads, :pf)[2]; atol = 1e-4)
    end

    t=7
    CompositeSystems.field(systemstates, :branches)[2,t] = 0
    CompositeSystems.field(systemstates, :branches)[7,t] = 0
    CompositeSystems.field(systemstates, :generators)[1,t] = 0
    CompositeSystems.field(systemstates, :generators)[2,t] = 0
    CompositeSystems.field(systemstates, :generators)[3,t] = 0
    systemstates.system[t] = 0
    OPF._update!(pm, system, systemstates, t)   

    @testset "L2 and L7 on outage, generation reduced" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0.9886; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0.8500; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0.1386; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test isapprox(systemstates.qlc[4,t]/systemstates.plc[4,t], CompositeAdequacy.field(system, :loads, :pf)[3]; atol = 1e-4)
        @test isapprox(systemstates.qlc[6,t]/systemstates.plc[6,t], CompositeAdequacy.field(system, :loads, :pf)[5]; atol = 1e-4)
    end

end


@testset "test sequentially split situations RTS system, LPACCPowerModel" begin

    settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
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
    
    model = OPF.jump_model(JuMP.AUTOMATIC, deepcopy(settings.optimizer), string_names = true)
    pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)
    systemstates = OPF.SystemStates(system, available=true)
    CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)

    t=1
    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.4549; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 9.2003; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end
    
    t=2
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.4549; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 9.2003; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=3
    CompositeSystems.field(systemstates, :branches)[29,t] = 0
    CompositeSystems.field(systemstates, :branches)[36,t] = 0
    CompositeSystems.field(systemstates, :branches)[37,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L29, L36, L37" begin
        @test isapprox(sum(systemstates.plc[:,t]), 3.09; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 1.81; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 1.28; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.4269; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 9.2977; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR

        @test isapprox(systemstates.qlc[19,t]/systemstates.plc[19,t], CompositeAdequacy.field(system, :loads, :pf)[16]; atol = 1e-4)
        @test isapprox(systemstates.qlc[20,t]/systemstates.plc[20,t], CompositeAdequacy.field(system, :loads, :pf)[17]; atol = 1e-4)

    end

    t=4
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.4549; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 9.2003; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=5
    CompositeSystems.field(systemstates, :branches)[25,t] = 0
    CompositeSystems.field(systemstates, :branches)[26,t] = 0
    CompositeSystems.field(systemstates, :branches)[28,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L25, L26, L28" begin
        @test isapprox(sum(systemstates.plc[:]), 5.4448; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 1.75; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0.6048; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 26.7339; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 5.669; atol = 1e-3)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR

        @test isapprox(systemstates.qlc[9,t]/systemstates.plc[9,t], CompositeAdequacy.field(system, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(systemstates.qlc[14,t]/systemstates.plc[14,t], CompositeAdequacy.field(system, :loads, :pf)[12]; atol = 1e-4)

    end

    t=6
    CompositeSystems.field(systemstates, :branches)[1,t] = 0
    CompositeSystems.field(systemstates, :branches)[8,t] = 0
    CompositeSystems.field(systemstates, :branches)[10,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L1, L8, L10" begin
        @test isapprox(sum(systemstates.plc[:,t]), 1.1654; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 1.1654; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.3247; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 11.1658; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test isapprox(systemstates.qlc[6,t]/systemstates.plc[6,t], CompositeAdequacy.field(system, :loads, :pf)[6]; atol = 1e-4)
    end

    t=7
    CompositeSystems.field(systemstates, :branches)[7,t] = 0
    CompositeSystems.field(systemstates, :branches)[19,t] = 0
    CompositeSystems.field(systemstates, :branches)[29,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L7, L19, L29" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 29.2406; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 7.6009; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=8
    CompositeSystems.field(systemstates, :branches)[7,t] = 0
    CompositeSystems.field(systemstates, :branches)[23,t] = 0
    CompositeSystems.field(systemstates, :branches)[29,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L7, L23, L29" begin
        @test isapprox(sum(systemstates.plc[:,t]), 1.95; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 1.75; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0.20; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 27.306; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 7.0827; atol = 1e-3)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR

        @test isapprox(systemstates.qlc[9,t]/systemstates.plc[9,t], CompositeAdequacy.field(system, :loads, :pf)[9]; atol = 1e-4)
        @test isapprox(systemstates.qlc[14,t]/systemstates.plc[14,t], CompositeAdequacy.field(system, :loads, :pf)[12]; atol = 1e-4)
    end

end


@testset "test sequentially split situations RTS system, DCMPPowerModel" begin

    settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.DCMPPowerModel)
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
    
    model = OPF.jump_model(JuMP.AUTOMATIC, deepcopy(settings.optimizer), string_names = true)
    pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)
    systemstates = OPF.SystemStates(system, available=true)
    CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)

    t=1
    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end
    
    t=2
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=3
    CompositeSystems.field(systemstates, :branches)[29,t] = 0
    CompositeSystems.field(systemstates, :branches)[36,t] = 0
    CompositeSystems.field(systemstates, :branches)[37,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L29, L36, L37" begin
        @test isapprox(sum(systemstates.plc[:,t]), 3.09; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 1.81; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 1.28; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-3.09; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR

    end

    t=4
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "No outages" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=5
    CompositeSystems.field(systemstates, :branches)[25,t] = 0
    CompositeSystems.field(systemstates, :branches)[26,t] = 0
    CompositeSystems.field(systemstates, :branches)[28,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L25, L26, L28" begin
        @test isapprox(sum(systemstates.plc[:,t]), 2.12; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 1.75; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0.37; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 2.12; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=6
    CompositeSystems.field(systemstates, :branches)[1,t] = 0
    CompositeSystems.field(systemstates, :branches)[8,t] = 0
    CompositeSystems.field(systemstates, :branches)[10,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L1, L8, L10" begin
        @test isapprox(sum(systemstates.plc[:,t]), 1.150; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 1.150; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500 - 1.150; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1, atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=7
    CompositeSystems.field(systemstates, :branches)[7,t] = 0
    CompositeSystems.field(systemstates, :branches)[19,t] = 0
    CompositeSystems.field(systemstates, :branches)[29,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L7, L19, L29" begin
        @test isapprox(sum(systemstates.plc[:,t]), 0; atol = 1e-4)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

    t=8
    CompositeSystems.field(systemstates, :branches)[7,t] = 0
    CompositeSystems.field(systemstates, :branches)[23,t] = 0
    CompositeSystems.field(systemstates, :branches)[29,t] = 0
    systemstates.system[t] = 0
    CompositeAdequacy.update!(pm, system, systemstates, t)

    @testset "Outages of L7, L23, L29" begin
        @test isapprox(sum(systemstates.plc[:,t]), 1.65; atol = 1e-2)
        @test isapprox(systemstates.plc[1,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[2,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[3,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[4,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[5,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[6,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[7,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[8,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[9,t], 1.65; atol = 1e-2)
        @test isapprox(systemstates.plc[10,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[11,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[12,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[13,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[14,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[15,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[16,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[17,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[18,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[19,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[20,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[21,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[22,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[23,t], 0; atol = 1e-4)
        @test isapprox(systemstates.plc[24,t], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 28.500-1.65; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    end

end
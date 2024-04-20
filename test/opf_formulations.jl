@testset verbose=true "test OPF formulations, IEEE RTS system" begin

    @testset "NFAPowerModel formulation, RTS" begin

        pm = solve_opf!(sys_rts, settings_NFAPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), sys_rts.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        result = PowerModels.solve_opf(data_rts, PowerModels.NFAPowerModel, juniper_optimizer)
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)
    
        key_buses = filter(i->OPF.field(sys_rts, :buses, :bus_type)[i]≠ 4, OPF.field(sys_rts, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(sys_rts, :generators, :status)[i], OPF.field(sys_rts, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(sys_rts, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(sys_rts, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    end

    @testset "DCPPowerModel form., RTS" begin

        pm = solve_opf!(sys_rts, settings_DCPPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), sys_rts.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        result = PowerModels.solve_opf(data_rts, PowerModels.DCPPowerModel, juniper_optimizer)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(sys_rts, :buses, :bus_type)[i]≠ 4, OPF.field(sys_rts, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(sys_rts, :generators, :status)[i], OPF.field(sys_rts, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(sys_rts, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(sys_rts, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "DCMPPowerModel form., RTS" begin

        pm = solve_opf!(sys_rts, settings_DCMPPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), sys_rts.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        result = PowerModels.solve_opf(data_rts, PowerModels.DCMPPowerModel, juniper_optimizer)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(sys_rts, :buses, :bus_type)[i]≠ 4, OPF.field(sys_rts, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(sys_rts, :generators, :status)[i], OPF.field(sys_rts, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(sys_rts, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(sys_rts, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "LPACCPowerModel form., RTS" begin

        pm = solve_opf!(sys_rts, settings_LPACCPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), sys_rts.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        result = PowerModels.solve_opf(data_rts, PowerModels.LPACCPowerModel, juniper_optimizer)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-0)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-0)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-0)
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.field(sys_rts, :buses, :bus_type)[i]≠ 4, OPF.field(sys_rts, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(sys_rts, :generators, :status)[i], OPF.field(sys_rts, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(sys_rts, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(sys_rts, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-0)
        end
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-0)
    
    end    

end

@testset verbose=true "test OPF, case5 system" begin

    rawfile = "../test/data/others/case5.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "NFAPowerModel formulation, case 5" begin
    
        pm = solve_opf!(system, settings_NFAPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
    
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, juniper_optimizer)
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)
    
        key_buses = filter(i->OPF.field(sys_rts, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    end

    @testset "DCPPowerModel form., case5" begin

        pm = solve_opf!(system, settings_DCPPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "DCMPPowerModel form., case5" begin

        pm = solve_opf!(system, settings_DCMPPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "LPACCPowerModel form., case5" begin

        pm = solve_opf!(system, settings_LPACCPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-3)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-3)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-3)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-3)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
            @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-2)
            @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-2)
            @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-2)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-3)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-3)
    end
end

@testset "test OPF, case9 system" begin

    rawfile = "../test/data/others/case9.m"
    system = BaseModule.SystemModel(rawfile)

    @testset " NFAPowerModel formulation, case9" begin

        pm = solve_opf!(system, settings_NFAPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, juniper_optimizer)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(key_buses)
            @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)


    end

    @testset "DCPPowerModel form., case9" begin

        pm = solve_opf!(system, settings_DCPPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "DCMPPowerModel form., case9" begin

        pm = solve_opf!(system, settings_DCMPPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "LPACCPowerModel form., case9" begin

        pm = solve_opf!(system, settings_LPACCPowerModel)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-3)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-3)
        #@test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-3)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
            @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-2)
            #@test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-2)
            #@test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-2)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-3)

        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-3)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-3)
    end
end
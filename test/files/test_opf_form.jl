#include(joinpath(@__DIR__, "..","juniper_optimizer_2s.jl"))

@testset "test OPF, RBTS system" begin

    rawfile = "test/data/RBTS/Base/RBTS.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "DC-OPF with NFAPowerModel, RBTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, juniper_optimizer_2)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-3)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-3)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(key_buses)
            @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-3)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
    end

    @testset "DC-OPF with DCPPowerModel, RBTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "DC-OPF with DCMPPowerModel, RBTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)

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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "AC-OPF with LPACCPowerModel, RBTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-4)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-4)

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
            @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
            @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end
end

@testset "test OPF IEEE RTS system" begin

    rawfile = "test/data/RTS/Base/RTS.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "DC-OPF with NFAPowerModel, RTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
    
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
    
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, juniper_optimizer_2)
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    end

    @testset "DC-OPF with DCMPPowerModel, RTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)

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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "DC-OPF with DCPPowerModel, RTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "AC-OPF with LPACCPowerModel, RTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
    
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
    
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
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
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    
        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-0)
        end
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-0)
    
    end
end

@testset "test OPF, case5 system" begin

    rawfile = "test/data/others/case5.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "DC-OPF with NFAPowerModel, case 5" begin
    
        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )    
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
    
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, juniper_optimizer_2)
    
        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end
    
        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end
    
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    end

    @testset "DC-OPF with DCPPowerModel, case5" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "DC-OPF with DCMPPowerModel, case5" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)

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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "AC-OPF with LPACCPowerModel, case5" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-3)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-3)
    end
end

@testset "test OPF, case9 system" begin

    rawfile = "test/data/others/case9.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "DC-OPF with NFAPowerModel, case9" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, juniper_optimizer_2)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
        end

        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-1)

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(key_buses)
            @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)


    end

    @testset "DC-OPF with DCPPowerModel, case9" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "DC-OPF with DCMPPowerModel, case9" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)

        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)

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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

    end

    @testset "AC-OPF with LPACCPowerModel, case9" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
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

        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end

        for i in eachindex(result["solution"]["bus"])
            @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-3)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-3)
    end
end

@testset "RBTS system, OPF formulation, non-sequential outages" begin
    @testset "test OPF, RBTS system, DCPPowerModel, outages" begin
        rawfile = "test/data/RBTS/Base/RBTS.m"
        system = BaseModule.SystemModel(rawfile)
        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        states = CompositeAdequacy.ComponentStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #OUTAGE BRANCH 1
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch #1" begin
            states.branches[1] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["1"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        #OUTAGE BRANCH 6
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch #6" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[6] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["6"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        #NO OUTAGE
        @testset "DC-OPF with DCPPowerModel, RBTS, no outage" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 3" begin
    
            #OUTAGE BRANCH 3
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 2" begin
    
            #OUTAGE BRANCH 2
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 7" begin
    
            #OUTAGE BRANCH 7
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 4" begin
    
            #OUTAGE BRANCH 4
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 5" begin
    
            #OUTAGE BRANCH 5
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[5] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 8" begin
    
            #OUTAGE BRANCH 8
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["8"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 9" begin
    
            #OUTAGE BRANCH 9
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[9] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["9"]["br_status"] = 0
            data["load"]["5"]["status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end
            
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
        
        #NO OUTAGE
        @testset "DC-OPF with DCPPowerModel, RBTS, no outage" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
        
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #1 and #5" begin
    
            #OUTAGE BRANCH #1 AND #5
            states.branches[1] = 0
            states.branches[5] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["1"]["br_status"] = 0
            data["branch"]["5"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
        
        #OUTAGE BRANCH #2 AND #7
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #2 and #7" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[2] = 0
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            data["branch"]["7"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #5 AND #8
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #5 and #8" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[5] = 0
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            data["branch"]["8"]["br_status"] = 0
            data["load"]["5"]["status"] = 0
            data["load"]["4"]["status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    end
    
    @testset "test OPF, RBTS system, DCMPPowerModel, outages" begin
    
        rawfile = "test/data/RBTS/Base/RBTS.m"
        system = BaseModule.SystemModel(rawfile)
        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        states = CompositeAdequacy.ComponentStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #OUTAGE BRANCH 1
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch #1" begin
    
            states.branches[1] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["1"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 6
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch #6" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[6] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["6"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #NO OUTAGE
        @testset "DC-OPF with DCMPPowerModel, RBTS, no outage" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 3
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 3" begin
    
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 2
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 2" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 7
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 7" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 4
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 4" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 5
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 5" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[5] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 8
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 8" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["8"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 9
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 9" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[9] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["9"]["br_status"] = 0
            data["load"]["5"]["status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end
            
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
      
        #NO OUTAGE
        @testset "DC-OPF with DCMPPowerModel, RBTS, no outage" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #1 AND #5
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #1 and #5" begin
    
            states.branches[1] = 0
            states.branches[5] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["1"]["br_status"] = 0
            data["branch"]["5"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #2 AND #7
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #2 and #7" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[2] = 0
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #5 AND #8
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #5 and #8" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[5] = 0
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            data["branch"]["8"]["br_status"] = 0
            data["load"]["5"]["status"] = 0
            data["load"]["4"]["status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    end

    @testset "test OPF, RBTS system, LPACCPowerModel, outages" begin

        rawfile = "test/data/RBTS/Base/RBTS.m"
        system = BaseModule.SystemModel(rawfile)
        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        states = CompositeAdequacy.ComponentStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #NO OUTAGE
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 3
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 3" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 2
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 2" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 7
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 7" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 4
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 4" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 5
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 5" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)            
        end
    
        #OUTAGE BRANCH 8
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 8" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["8"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)      
        end
    
        #OUTAGE BRANCH 9
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 9" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[9] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["9"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)        
        end
        
        #NO OUTAGE
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        #OUTAGE BRANCH #5 AND #8
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH #5 AND #8" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[5] = 0
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            data["branch"]["8"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)        
        end
    end

    @testset "test OPF, RBTS system, LPACCPowerModel, outages" begin

        rawfile = "test/data/RBTS/Base/RBTS.m"
        system = BaseModule.SystemModel(rawfile)
        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        states = CompositeAdequacy.ComponentStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #NO OUTAGE
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 3
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 3" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 2
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 2" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 7
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 7" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[7] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["7"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 4
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 4" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
        end
    
        #OUTAGE BRANCH 5
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 5" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)            
        end
    
        #OUTAGE BRANCH 8
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 8" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["8"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)      
        end
    
        #OUTAGE BRANCH 9
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 9" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[9] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["9"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)        
        end
        
        #NO OUTAGE
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end
            @test sum(values(OPF.build_sol_values(OPF.var(pm, :z_branch, :)))) == sum(states.branches[:])
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
        end
    
        #OUTAGE BRANCH #5 AND #8
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH #5 AND #8" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[5] = 0
            states.branches[8] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["5"]["br_status"] = 0
            data["branch"]["8"]["br_status"] = 0
            PowerModels.simplify_network!(data)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            result_q = OPF.build_sol_values(OPF.var(pm, :q, :), system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-4)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-4)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-4)
                @test isapprox(abs(result_p[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-4)
                @test isapprox(abs(result_q[parse(Int,i)]["to"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-4)
            end
        
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)        
        end
    end
end

@testset "RTS system, OPF formulation, non-sequential outages" begin
    @testset "test OPF, RTS system, DCPPowerModel, outages" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        states = CompositeAdequacy.ComponentStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #OUTAGE BRANCH 1
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #1" begin

            states.branches[1] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = PowerModels.parse_file(rawfile)
            data["branch"]["1"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
            
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH 25 - 26
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #25 and #26" begin

            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[25] = 0
            states.branches[26] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["25"]["br_status"] = 0
            data["branch"]["26"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH 14 - 16
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #14 and #16" begin

            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[14] = 0
            states.branches[16] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["14"]["br_status"] = 0
            data["branch"]["16"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 6
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #6" begin

            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[6] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["6"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
            
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #NO OUTAGE
        @testset "DC-OPF with DCPPowerModel, RTS, no outage" begin

            states = CompositeAdequacy.ComponentStates(system, available=true)
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 3
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 3" begin
    
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[3] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["3"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 2
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 2" begin

            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[2] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["2"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 33
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 7" begin

            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[33] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["33"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 4
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 4" begin

            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[4] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["4"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 5
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 5" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 8
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 8" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 9
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 9" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #NO OUTAGE
        states = CompositeAdequacy.ComponentStates(system, available=true)
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, no outage" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #1 AND #6
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, branch #1 and #6" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #20
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[20] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["20"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, branch #20" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #12
        @testset "DC-OPF with DCPPowerModel, RTS, branch #12" begin
            states = CompositeAdequacy.ComponentStates(system, available=true)
            states.branches[12] = 0
            OPF._update_opf!(pm, system, states, settings, 1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
            data = OPF.build_network(rawfile, symbol=false)
            data["branch"]["12"]["br_status"] = 0
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, juniper_optimizer_2)
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    end

    @testset "test OPF, RTS system, DCMPPowerModel, outages" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)

        settings = CompositeSystems.Settings(
            juniper_optimizer_2;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        states = CompositeAdequacy.ComponentStates(system, available=true)
        pm = OPF.solve_opf(system, settings)
    
        #OUTAGE BRANCH 1
        states.branches[1] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #1" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH 25 - 26
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[25] = 0
        states.branches[26] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["25"]["br_status"] = 0
        data["branch"]["26"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #25 and #26" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH 14 - 16
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[14] = 0
        states.branches[16] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["14"]["br_status"] = 0
        data["branch"]["16"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #14 and #16" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 6
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch #6" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #NO OUTAGE
        states = CompositeAdequacy.ComponentStates(system, available=true)
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, no outage" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 3
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[3] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["3"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 3" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 2
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[2] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 2" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 33
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[33] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["33"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 7" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 4
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[4] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["4"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 4" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 5
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 5" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 8
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 8" begin
            
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH 9
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 9" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)
        
            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
        
            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        
        #NO OUTAGE
        states = CompositeAdequacy.ComponentStates(system, available=true)
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, no outage" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #1 AND #6
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #1 and #6" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #20
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[20] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["20"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #20" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
        #OUTAGE BRANCH #12
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[12] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["12"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #12" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH #7
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        data["bus"]["24"]["bus_type"] = 4
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #7" begin
    
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end

        #OUTAGE BRANCH #7 AND #27
        states = CompositeAdequacy.ComponentStates(system, available=true)
        states.branches[7] = 0
        states.branches[27] = 0
        OPF._update_opf!(pm, system, states, settings, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        data["branch"]["27"]["br_status"] = 0
        data["bus"]["24"]["bus_type"] = 4
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #7 and 27" begin
            
            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)

            key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)

        end
    
    end
end

@testset "test OPF, RTS system, LPACCPowerModel, outages" begin

    rawfile = "test/data/RTS/Base/RTS.m"
    system = BaseModule.SystemModel(rawfile)
    settings = CompositeSystems.Settings(
        juniper_optimizer_2;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.LPACCPowerModel,
        select_largest_splitnetwork = true,
        deactivate_isolated_bus_gens_stors = true,
        set_string_names_on_creation = true
    )
    states = CompositeAdequacy.ComponentStates(system, available=true)
    pm = OPF.solve_opf(system, settings)

    #OUTAGE BRANCH 1
    states.branches[1] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["1"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)

    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #1" begin
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0

        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 25 - 26
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[25] = 0
    states.branches[26] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["25"]["br_status"] = 0
    data["branch"]["26"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #25 and #26" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 14 - 16
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[14] = 0
    states.branches[16] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["14"]["br_status"] = 0
    data["branch"]["16"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)

    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #14 and #16" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 6
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[6] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["6"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #6" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #NO OUTAGE
    states = CompositeAdequacy.ComponentStates(system, available=true)
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, no outage" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 3
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[3] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["3"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 3" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 2
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[2] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["2"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 2" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 33
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[33] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["33"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 7" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 4
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[4] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["4"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 4" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 5
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[5] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["5"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 5" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 8
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[8] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["8"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 8" begin

        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH 9
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[9] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["9"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 9" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #NO OUTAGE
    states = CompositeAdequacy.ComponentStates(system, available=true)
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, no outage" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #1 AND #6
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[1] = 0
    states.branches[6] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["1"]["br_status"] = 0
    data["branch"]["6"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #1 and #6" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #20
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[20] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["20"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #20" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #12
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[12] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["12"]["br_status"] = 0
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #12" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #7
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[7] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["7"]["br_status"] = 0
    data["bus"]["24"]["bus_type"] = 4
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #7" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    
    end

    #OUTAGE BRANCH #7 and #27
    states = CompositeAdequacy.ComponentStates(system, available=true)
    states.branches[7] = 0
    states.branches[27] = 0
    OPF._update_opf!(pm, system, states, settings, 1)
    result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
    result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
    result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
    data = OPF.build_network(rawfile, symbol=false)
    data["branch"]["7"]["br_status"] = 0
    data["branch"]["27"]["br_status"] = 0
    data["bus"]["24"]["bus_type"] = 4
    result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
    @testset "AC-OPF with LPACCPowerModel, RTS, branch #7 and #27" begin
        
        pm = OPF.solve_opf(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
        
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer_2)
    
        result_pg_powermodels = 0
        result_qg_powermodels = 0
    
        for i in eachindex(result["solution"]["gen"])
            result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
            result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
        end
    
        @test isapprox(total_pg, result_pg_powermodels; atol = 1e-1)
        @test isapprox(total_qg, result_qg_powermodels; atol = 1e-1)
        @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-0)
    
        key_buses = filter(i->OPF.OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.OPF.field(system, :generators, :status)[i], OPF.OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    
        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)
    end
end
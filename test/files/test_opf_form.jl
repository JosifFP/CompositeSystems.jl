#include(joinpath(@__DIR__, "..","juniper_optimizer_2s.jl"))

@testset "test OPF, RBTS system" begin

    rawfile = "test/data/RBTS/Base/RBTS.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "DC-OPF with NFAPowerModel, RBTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf!(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, juniper_optimizer)

        for i in eachindex(result["solution"]["gen"])
            @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-3)
        end

        for i in eachindex(result["solution"]["branch"])
            @test isapprox(abs(result_p[parse(Int,i)]["from"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-3)
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
            @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-3)
        end

        @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-4)
    end

    @testset "DC-OPF with DCPPowerModel, RBTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf!(system, settings)
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

    @testset "DC-OPF with DCMPPowerModel, RBTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf!(system, settings)
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

    @testset "AC-OPF with LPACCPowerModel, RBTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        
        pm = OPF.solve_opf!(system, settings)
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
end

@testset "test OPF IEEE RTS system" begin

    rawfile = "test/data/RTS/Base/RTS.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "DC-OPF with NFAPowerModel, RTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
    
        pm = OPF.solve_opf!(system, settings)
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
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    end

    @testset "DC-OPF with DCMPPowerModel, RTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf!(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

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

    @testset "DC-OPF with DCPPowerModel, RTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf!(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

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

    @testset "AC-OPF with LPACCPowerModel, RTS" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
    
        pm = OPF.solve_opf!(system, settings)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
        result_p = OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)
        total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
        total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
    
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, juniper_optimizer)
    
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
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
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
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )    
        pm = OPF.solve_opf!(system, settings)
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
    
        key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
        pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
        pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
        key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))
    
        for k in key_generators
            pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
            pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
        end
    end

    @testset "DC-OPF with DCPPowerModel, case5" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf!(system, settings)
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

    @testset "DC-OPF with DCMPPowerModel, case5" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf!(system, settings)
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

    @testset "AC-OPF with LPACCPowerModel, case5" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        pm = OPF.solve_opf!(system, settings)
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

    rawfile = "test/data/others/case9.m"
    system = BaseModule.SystemModel(rawfile)

    @testset "DC-OPF with NFAPowerModel, case9" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.NFAPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf!(system, settings)
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

    @testset "DC-OPF with DCPPowerModel, case9" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf!(system, settings)
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

    @testset "DC-OPF with DCMPPowerModel, case9" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCMPPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf!(system, settings)
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

    @testset "AC-OPF with LPACCPowerModel, case9" begin

        settings = CompositeSystems.Settings(
            juniper_optimizer;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )
        pm = OPF.solve_opf!(system, settings)
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
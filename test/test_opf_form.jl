#include(joinpath(@__DIR__, "..","solvers.jl"))

@testset "Ipopt solver" begin
    @testset "test OPF, RBTS system" begin

        rawfile = "test/data/RBTS/Base/RBTS_AC.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, RBTS" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)


        end

        @testset "DC-OPF with DCPPowerModel, RBTS" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "DC-OPF with DCMPPowerModel, RBTS" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "AC-OPF with LPACCPowerModel, RBTS" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

    end

    @testset "test OPF IEEE RTS system" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, RTS" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)


        end

        @testset "DC-OPF with DCMPPowerModel, RTS" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-5)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "DC-OPF with DCPPowerModel, RTS" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-5)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "AC-OPF with LPACCPowerModel, RTS" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-5)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

    end

    @testset "test OPF, case5 system" begin

        rawfile = "test/data/others/case5.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, case5" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)


        end

        @testset "DC-OPF with DCPPowerModel, case5" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "DC-OPF with DCMPPowerModel, case5" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "AC-OPF with LPACCPowerModel, case5" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-4)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-3)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

    end

    @testset "test OPF, case6 system" begin

        rawfile = "test/data/others/case6.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, case6" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)


        end

        @testset "DC-OPF with DCPPowerModel, case6" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                #@test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "DC-OPF with DCMPPowerModel, case6" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, juniper_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, juniper_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                #@test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "AC-OPF with LPACCPowerModel, case6" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)

            for i in eachindex(result["solution"]["bus"])
                #@test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

    end

    @testset "test OPF, case9 system" begin

        rawfile = "test/data/others/case9.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, case9" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)


        end

        @testset "DC-OPF with DCPPowerModel, case9" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "DC-OPF with DCMPPowerModel, case9" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "AC-OPF with LPACCPowerModel, case9" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

    end

    @testset "test OPF, frankenstein_00 system" begin

        rawfile = "test/data/others/frankenstein_00.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, frankenstein_00" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)


        end

        @testset "DC-OPF with DCPPowerModel, frankenstein_00" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-4)

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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "DC-OPF with DCMPPowerModel, frankenstein_00" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        @testset "AC-OPF with LPACCPowerModel, frankenstein_00" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, ipopt_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-6)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-5)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-5)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-6)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-5)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-6)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-5)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-5)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-4)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

    end
end


@testset "Gurobi solver (not exact)" begin
    
    @testset "test OPF, RBTS system" begin

        rawfile = "test/data/RBTS/Base/RBTS_AC.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, RBTS" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, gurobi_optimizer_1)

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(key_buses)
                @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)


        end

        @testset "DC-OPF with DCPPowerModel, RBTS" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "DC-OPF with DCMPPowerModel, RBTS" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "AC-OPF with LPACCPowerModel, RBTS" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, gurobi_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-2)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

    end

    @testset "test OPF IEEE RTS system" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, RTS" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, gurobi_optimizer_1)

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)


        end

        @testset "DC-OPF with DCMPPowerModel, RTS" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, gurobi_optimizer_1)


            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "DC-OPF with DCPPowerModel, RTS" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, gurobi_optimizer_1)

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "AC-OPF with LPACCPowerModel, RTS" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, gurobi_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-2)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

    end

    @testset "test OPF, case5 system" begin

        rawfile = "test/data/others/case5.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, case5" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(key_buses)
                @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)


        end

        @testset "DC-OPF with DCPPowerModel, case5" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "DC-OPF with DCMPPowerModel, case5" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "AC-OPF with LPACCPowerModel, case5" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, gurobi_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-3)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

    end

    @testset "test OPF, case6 system" begin

        rawfile = "test/data/others/case6.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, case6" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(key_buses)
                @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)


        end

        @testset "DC-OPF with DCPPowerModel, case6" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["bus"])
                #@test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "DC-OPF with DCMPPowerModel, case6" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["bus"])
                #@test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "AC-OPF with LPACCPowerModel, case6" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, gurobi_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)

            for i in eachindex(result["solution"]["bus"])
                #@test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-2)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

    end

    @testset "test OPF, case9 system" begin

        rawfile = "test/data/others/case9.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, case9" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(key_buses)
                @test isapprox(pg_bus_compositesystems[i], pg_bus_powermodels[i]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)


        end

        @testset "DC-OPF with DCPPowerModel, case9" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "DC-OPF with DCMPPowerModel, case9" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "AC-OPF with LPACCPowerModel, case9" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, gurobi_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-0)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-2)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

    end

    @testset "test OPF, frankenstein_00 system" begin

        rawfile = "test/data/others/frankenstein_00.m"
        system = BaseModule.SystemModel(rawfile)

        @testset "DC-OPF with NFAPowerModel, frankenstein_00" begin

            pm = OPF.solve_opf(system, OPF.NFAPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.NFAPowerModel, gurobi_optimizer_1)

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)


        end

        @testset "DC-OPF with DCPPowerModel, frankenstein_00" begin

            pm = OPF.solve_opf(system, OPF.DCPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
            end

            @test isapprox(OPF.objective_value(pm.model), result["objective"]; atol = 1e-2)

            key_buses = filter(i->OPF.field(system, :buses, :bus_type)[i]≠ 4, OPF.field(system, :buses, :keys))
            pg_bus_compositesystems = Dict((i, 0.0) for i in key_buses)
            pg_bus_powermodels = Dict((i, 0.0) for i in key_buses)
            key_generators = filter(i->OPF.field(system, :generators, :status)[i], OPF.field(system, :generators, :keys))

            for k in key_generators
                pg_bus_compositesystems[OPF.field(system, :generators, :buses)[k]] += OPF.build_sol_values(OPF.var(pm, :pg, :))[k]
                pg_bus_powermodels[OPF.field(system, :generators, :buses)[k]] += result["solution"]["gen"][string(k)]["pg"]
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "DC-OPF with DCMPPowerModel, frankenstein_00" begin

            pm = OPF.solve_opf(system, OPF.DCMPPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)

            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, gurobi_optimizer_1)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
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

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

        @testset "AC-OPF with LPACCPowerModel, frankenstein_00" begin

            pm = OPF.solve_opf(system, OPF.LPACCPowerModel, gurobi_optimizer_1)
            result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
            result_qg = OPF.build_sol_values(OPF.var(pm, :qg, :))
            result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
            result_phi = OPF.build_sol_values(OPF.var(pm, :phi, :))
            result_pf = OPF.build_sol_branch_values(pm, system.branches)
            total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
            total_qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :))))
            
            data = OPF.build_network(rawfile, symbol=false)
            result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, gurobi_optimizer_1)
        
            result_pg_powermodels = 0
            result_qg_powermodels = 0
        
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
                result_pg_powermodels += result["solution"]["gen"][string(i)]["pg"]
                result_qg_powermodels += result["solution"]["gen"][string(i)]["qg"]
            end
        
            @test isapprox(total_pg, result_pg_powermodels; atol = 1e-2)
            @test isapprox(total_qg, result_qg_powermodels; atol = 1e-2)

            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-2)
                @test isapprox(result_phi[parse(Int,i)], result["solution"]["bus"][string(i)]["phi"]; atol = 1e-2)
            end

            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["pt"]), abs(result["solution"]["branch"][string(i)]["pt"]); atol = 1e-2)
                @test isapprox(abs(result_pf[parse(Int,i)]["qf"]), abs(result["solution"]["branch"][string(i)]["qf"]); atol = 1e-0)
                @test isapprox(abs(result_pf[parse(Int,i)]["qt"]), abs(result["solution"]["branch"][string(i)]["qt"]); atol = 1e-0)
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
                @test isapprox(pg_bus_compositesystems[parse(Int,i)], pg_bus_powermodels[parse(Int,i)]; atol = 1e-2)
            end

            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-2)

        end

    end

end
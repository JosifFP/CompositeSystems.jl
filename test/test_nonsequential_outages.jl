
@testset "RBTS system" begin
    @testset "test OPF, RBTS system, DCPPowerModel, outages" begin

        rawfile = "test/data/RBTS/Base/RBTS.m"
        system = BaseModule.SystemModel(rawfile)

        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)

        #OUTAGE BRANCH 1
        states.branches[1] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)

        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch #1" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch #6" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, no outage" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 3
        states.branches[3] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["3"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 3" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 2
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 2" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 7" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 4
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[4] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["4"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 4" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 5
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 5" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 8" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 9
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        data["load"]["5"]["status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, outage branch 9" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end
            
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-3)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-3)
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
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, no outage" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH #1 AND #6
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #1 and #6" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH #2 AND #7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        data["branch"]["7"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #2 and #7" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH #5 AND #8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        data["branch"]["8"]["br_status"] = 0
        data["load"]["5"]["status"] = 0
        data["load"]["4"]["status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RBTS, branch #5 and #8" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

    end

    @testset "test OPF, RBTS system, DCMPPowerModel, outages" begin

        rawfile = "test/data/RBTS/Base/RBTS.m"
        system = BaseModule.SystemModel(rawfile)

        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, OPF.DCMPPowerModel, ipopt_optimizer_1)

        #OUTAGE BRANCH 1
        states.branches[1] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)

        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch #1" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch #6" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, no outage" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 3
        states.branches[3] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["3"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 3" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 2
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 2" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 7" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 4
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[4] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["4"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 4" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 5
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 5" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 8" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 9
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        data["load"]["5"]["status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, outage branch 9" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end
            
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-3)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-3)
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
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)

        end

        
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, no outage" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH #1 AND #6
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #1 and #6" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH #2 AND #7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        data["branch"]["7"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #2 and #7" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH #5 AND #8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        data["branch"]["8"]["br_status"] = 0
        data["load"]["5"]["status"] = 0
        data["load"]["4"]["status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RBTS, branch #5 and #8" begin

            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

    end

    @testset "test OPF, RBTS system, LPACCPowerModel, outages" begin

        rawfile = "test/data/RBTS/Base/RBTS.m"
        system = BaseModule.SystemModel(rawfile)

        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, ipopt_optimizer_1)

        #OUTAGE BRANCH 1
        states.branches[1] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)

        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 1" begin

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

        #OUTAGE BRANCH 6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 6" begin

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

        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin

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

        #OUTAGE BRANCH 3
        states.branches[3] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["3"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 3" begin

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

        #OUTAGE BRANCH 2
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 2" begin

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

        #OUTAGE BRANCH 7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 7" begin

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

        #OUTAGE BRANCH 4
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[4] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["4"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 4" begin

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

        #OUTAGE BRANCH 5
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 5" begin

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

        #OUTAGE BRANCH 8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 8" begin

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

        #OUTAGE BRANCH 9
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        data["load"]["5"]["status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH 9" begin

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
        
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, NO OUTAGE" begin

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

        #OUTAGE BRANCH #1 AND #6
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH #1 AND #6" begin

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

        #OUTAGE BRANCH #2 AND #7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        data["branch"]["7"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH #2 AND #7" begin

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

        #OUTAGE BRANCH #5 AND #8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        data["branch"]["8"]["br_status"] = 0
        data["load"]["5"]["status"] = 0
        data["load"]["4"]["status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RBTS, OUTAGE BRANCH #5 AND #8" begin

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

@testset "RTS system" begin

    @testset "test OPF, RTS system, DCPPowerModel, outages" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)
    
        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, OPF.DCPPowerModel, ipopt_optimizer_1)
    
        #OUTAGE BRANCH 1
        states.branches[1] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #1" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 25 - 26
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[25] = 0
        states.branches[26] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["25"]["br_status"] = 0
        data["branch"]["26"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #25 and #26" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 14 - 16
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[14] = 0
        states.branches[16] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["14"]["br_status"] = 0
        data["branch"]["16"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #14 and #16" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #6" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, no outage" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 3
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[3] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["3"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 3" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 2
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 2" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 33
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[33] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["33"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 7" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 4
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[4] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["4"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 4" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 5
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 5" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 8" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 9
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch 9" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end
            
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-3)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-3)
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
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
        end
    
        
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, no outage" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH #1 AND #6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, branch #1 and #6" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH #20
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[20] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["20"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, branch #20" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH #12
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[12] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["12"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, branch #12" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
    end

    @testset "test OPF, RTS system, DCMPPowerModel, outages" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)
    
        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, OPF.DCMPPowerModel, ipopt_optimizer_1)
    
        #OUTAGE BRANCH 1
        states.branches[1] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #1" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 25 - 26
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[25] = 0
        states.branches[26] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["25"]["br_status"] = 0
        data["branch"]["26"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #25 and #26" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH 14 - 16
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[14] = 0
        states.branches[16] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["14"]["br_status"] = 0
        data["branch"]["16"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
    
        @testset "DC-OPF with DCPPowerModel, RTS, outage branch #14 and #16" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch #6" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, no outage" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 3
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[3] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["3"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 3" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 2
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 2" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 33
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[33] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["33"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 7" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 4
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[4] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["4"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 4" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 5
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 5" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 8" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH 9
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, outage branch 9" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-2)
            end
            
            for i in eachindex(result["solution"]["bus"])
                @test isapprox(result_va[parse(Int,i)], result["solution"]["bus"][string(i)]["va"]; atol = 1e-3)
            end
        
            for i in eachindex(result["solution"]["branch"])
                @test isapprox(abs(result_pf[parse(Int,i)]["pf"]), abs(result["solution"]["branch"][string(i)]["pf"]); atol = 1e-3)
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
        
            @test isapprox(sum(values(pg_bus_compositesystems)), sum(values(pg_bus_powermodels)); atol = 1e-5)
    
        end
    
        
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, no outage" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH #1 AND #6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #1 and #6" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH #20
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[20] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["20"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #20" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
        #OUTAGE BRANCH #12
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[12] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["12"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #12" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH #7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        data["bus"]["24"]["bus_type"] = 4
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #7" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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

        #OUTAGE BRANCH #7 AND #27
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        states.branches[27] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        data["branch"]["27"]["br_status"] = 0
        data["bus"]["24"]["bus_type"] = 4
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "DC-OPF with DCMPPowerModel, RTS, branch #7 and 27" begin
    
            for i in eachindex(result["solution"]["gen"])
                @test isapprox(result_pg[parse(Int,i)], result["solution"]["gen"][string(i)]["pg"]; atol = 1e-5)
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
    
    end

    @testset "test OPF, RTS system, LPACCPowerModel, outages" begin

        rawfile = "test/data/RTS/Base/RTS.m"
        system = BaseModule.SystemModel(rawfile)
    
        states = CompositeAdequacy.SystemStates(system, available=true)
        pm = OPF.solve_opf(system, OPF.LPACCPowerModel, ipopt_optimizer_1)
    
        #OUTAGE BRANCH 1
        states.branches[1] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
    
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #1" begin
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

        #OUTAGE BRANCH 25 - 26
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[25] = 0
        states.branches[26] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["25"]["br_status"] = 0
        data["branch"]["26"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.DCMPPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #25 and #26" begin

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

        #OUTAGE BRANCH 14 - 16
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[14] = 0
        states.branches[16] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["14"]["br_status"] = 0
        data["branch"]["16"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
    
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #14 and #16" begin

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
    
        #OUTAGE BRANCH 6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch #6" begin

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
    
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, no outage" begin

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
    
        #OUTAGE BRANCH 3
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[3] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["3"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 3" begin

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
    
        #OUTAGE BRANCH 2
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[2] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["2"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 2" begin

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
    
        #OUTAGE BRANCH 33
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[33] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["33"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 7" begin

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
    
        #OUTAGE BRANCH 4
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[4] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["4"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 4" begin

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
    
        #OUTAGE BRANCH 5
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[5] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["5"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 5" begin

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
    
        #OUTAGE BRANCH 8
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[8] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["8"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 8" begin

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
    
        #OUTAGE BRANCH 9
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[9] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["9"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, outage branch 9" begin
            
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
    
        #NO OUTAGE
        states = CompositeAdequacy.SystemStates(system, available=true)
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, no outage" begin
            
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
    
        #OUTAGE BRANCH #1 AND #6
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[1] = 0
        states.branches[6] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["1"]["br_status"] = 0
        data["branch"]["6"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, branch #1 and #6" begin
            
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
    
        #OUTAGE BRANCH #20
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[20] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["20"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, branch #20" begin
            
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
    
        #OUTAGE BRANCH #12
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[12] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["12"]["br_status"] = 0
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, branch #12" begin
            
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

        #OUTAGE BRANCH #7
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        data["bus"]["24"]["bus_type"] = 4
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, branch #7" begin
            
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

        #OUTAGE BRANCH #7 and #27
        states = CompositeAdequacy.SystemStates(system, available=true)
        states.branches[7] = 0
        states.branches[27] = 0
        OPF._update_opf!(pm, system, states, 1)
        result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
        result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
        result_pf = OPF.build_sol_branch_values(pm, system.branches)
        data = OPF.build_network(rawfile, symbol=false)
        data["branch"]["7"]["br_status"] = 0
        data["branch"]["27"]["br_status"] = 0
        data["bus"]["24"]["bus_type"] = 4
        result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
        
        @testset "AC-OPF with LPACCPowerModel, RTS, branch #7 and #27" begin
            
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
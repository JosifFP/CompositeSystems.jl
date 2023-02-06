using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using Test

include("solvers.jl")

timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
rawfile = "test/data/others/Storage/RBTS_strg.m"
reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"

settings = CompositeSystems.Settings(
    juniper_optimizer_1;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.LPACCPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    set_string_names_on_creation = true
)

system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
pm = OPF.abstract_model(system, settings)
systemstates = OPF.SystemStates(system, available=true)
CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
t=1
OPF._update!(pm, system, systemstates, settings, t)
println(Float32.(systemstates.se[t]*100))
systemstates.se[t]*100
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :sc, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :sd, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :qs, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :qsc, 1)*100)))))

t=2
systemstates.se[t-1] = field(system, :storages, :energy_rating)[1] #it should be energy_rating = 0.4
CompositeSystems.field(systemstates, :branches)[5,t] = 0
CompositeSystems.field(systemstates, :branches)[8,t] = 0
OPF._update!(pm, system, systemstates, settings, t)
println(Float32.(systemstates.se[t]*100))
println(Float32.(systemstates.plc[:]*100))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :sc, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :sd, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :qs, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :qsc, 1)*100)))))



@testset "RBTS system, sequential outages, storage at bus 6" begin
    @testset "test sequentially split situations w/o isolated buses, RBTS system, DCPPowerModel" begin

        timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
        rawfile = "test/data/others/Storage/RBTS_strg.m"
        reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.DCPPowerModel,
            select_largest_splitnetwork = false,
            deactivate_isolated_bus_gens_stors = false
        )
        system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
        for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
        pm = OPF.abstract_model(system, settings)
        systemstates = OPF.SystemStates(system, available=true)
        CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
        field(system, :storages, :energy)[1] = 0.05

        t=1
        OPF._update!(pm, system, systemstates, settings, t)
        @testset "t=1, No outages" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + 0.05; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.1; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        end

        t=2
        OPF._update!(pm, system, systemstates, settings, t)  
        @testset "t=2, No outages" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + 0.05; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.15; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
            #stored energy left = 0.15
        end

        t=3
        systemstates.se[t-1] = field(system, :storages, :energy_rating)[1] #it should be energy_rating = 0.4
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        CompositeSystems.field(systemstates, :generators)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[8,t] = 0
        CompositeSystems.field(systemstates, :generators)[9,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "t=3, G3, G7, G8 and G9 on outage" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0.25; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0.25; atol = 1e-4) #without storage it should be 0.35
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) - 0.10; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.3; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.10; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.00; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.10; atol = 1e-4)
            #stored energy left = 0.3
        end

        t=4
        CompositeSystems.field(systemstates, :branches)[5,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "t=4, L5 and L8 on outage" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0.30; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test xor(isapprox(systemstates.plc[5], 0.1; atol = 1e-4),isapprox(systemstates.plc[6], 0.1; atol = 1e-4)) #without storage it should be 0.2 in any of those buses
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) - 0.10; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.2; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.10; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.00; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.10; atol = 1e-4)
        end

        t=5
        OPF._update!(pm, system, systemstates, settings, t)  
        @testset "t=5, No outages" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.90 - sum(systemstates.plc[:]); atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.25; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
            #stored energy left = 0.25
        end

        t=6
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)  

        @testset "t=6, L3, L4 and L8 on outage" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0.05; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0.05; atol = 1e-4) #without storage it should be 0.15
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) - 0.10; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.15; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.10; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.00; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.10; atol = 1e-4)
            #stored energy left = 0.15
        end

        t=7
        CompositeSystems.field(systemstates, :branches)[2,t] = 0
        CompositeSystems.field(systemstates, :branches)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[1,t] = 0
        CompositeSystems.field(systemstates, :generators)[2,t] = 0
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)  

        @testset "t=7, L2 and L7 on outage, generation reduced" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0.64; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0.64; atol = 1e-4) #without storage it should be 0.74
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) - 0.10; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.10; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.00; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.10; atol = 1e-4)
            #stored energy left = 0.05
        end

        t=8
        OPF._update!(pm, system, systemstates, settings, t)  
        @testset "t=8, No outages" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + 0.05; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.10; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
            #stored energy left = 0.15
        end
    end
end

@testset "RBTS system, sequential outages, storage at bus 6" begin
    @testset "test sequentially split situations w/o isolated buses, RBTS system, LPACCPowerModel" begin

        timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
        rawfile = "test/data/others/Storage/RBTS_strg.m"
        reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
        settings = CompositeSystems.Settings(
            juniper_optimizer_1;
            jump_modelmode = JuMP.AUTOMATIC,
            powermodel_formulation = OPF.LPACCPowerModel,
            select_largest_splitnetwork = true,
            deactivate_isolated_bus_gens_stors = true,
            set_string_names_on_creation = true
        )

        system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
        for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
        pm = OPF.abstract_model(system, settings)
        systemstates = OPF.SystemStates(system, available=true)
        CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
        field(system, :storages, :energy)[1] = 0.05

        t=1
        OPF._update!(pm, system, systemstates, settings, t)
        @testset "t=1, No outages" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            ps = sum(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)))))
            qs = sum(values(sort(OPF.build_sol_values(OPF.var(pm, :qs, 1)))))
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371 - sum(systemstates.plc[:]) + ps; atol = 1e-4) 
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231 - sum(systemstates.qlc[:]) + qs; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.1; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
        end

        t=2
        OPF._update!(pm, system, systemstates, settings, t)  
        @testset "t=2, No outages" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            ps = sum(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)))))
            qs = sum(values(sort(OPF.build_sol_values(OPF.var(pm, :qs, 1)))))
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371 - sum(systemstates.plc[:]) + ps; atol = 1e-4) 
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231 - sum(systemstates.qlc[:]) + qs; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.15; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.05; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
            #stored energy left = 0.15
        end

        t=3
        systemstates.se[t-1] = field(system, :storages, :energy_rating)[1] #it should be energy_rating = 0.4
        CompositeSystems.field(systemstates, :generators)[3,t] = 0
        CompositeSystems.field(systemstates, :generators)[7,t] = 0
        CompositeSystems.field(systemstates, :generators)[8,t] = 0
        CompositeSystems.field(systemstates, :generators)[9,t] = 0
        OPF._update!(pm, system, systemstates, settings, t)

        @testset "t=3, G3, G7, G8 and G9 on outage" begin
            @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
            @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
            @test isapprox(sum(systemstates.plc[:]), 0.2699; atol = 1e-4)
            @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[3], 0.2699; atol = 1e-4)
            @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
            @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
            ps = sum(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)))))
            qs = sum(values(sort(OPF.build_sol_values(OPF.var(pm, :qs, 1)))))
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.9371 - sum(systemstates.plc[:]) + ps; atol = 1e-4) 
            @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :qg, :)))), 0.5231 - sum(systemstates.qlc[:]) + qs; atol = 1e-4) 
            @test isapprox(systemstates.se[t], 0.3; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.10; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.00; atol = 1e-4)
            @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.10; atol = 1e-4)
            #stored energy left = 0.3
        end
    end
end
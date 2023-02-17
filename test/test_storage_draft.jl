using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using Test

include("solvers.jl")
"------------------------------------------------------------------------------------------------------------------------------------------"

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

system.storages.buses[1] = 2
system.storages.charge_rating[1] = 0.25
system.storages.discharge_rating[1] = 0.25
system.storages.thermal_rating[1] = 0.25
system.storages.energy_rating[1] = 2
pm = OPF.abstract_model(system, settings)
systemstates = OPF.SystemStates(system, available=true)
CompositeAdequacy.initialize_powermodel!(pm, system, systemstates)
field(system, :storages, :energy)[1] = 0.0

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
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
    @test isapprox(system.storages.charge_rating[1], 0.25; atol = 1e-4)
    @test isapprox(systemstates.se[t], 0.25; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
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
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
    @test isapprox(systemstates.se[t], 0.5; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
end

t=3
systemstates.se[t-1] = 1.0 #se(t-1) = 2.0
systemstates.generators[3,t] = 0
systemstates.generators[7,t] = 0
systemstates.generators[8,t] = 0
systemstates.generators[9,t] = 0
OPF._update!(pm, system, systemstates, settings, t)

@testset "t=3, G3, G7, G8 and G9 on outage" begin
    @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    @test isapprox(sum(systemstates.plc[:]), 0.1; atol = 1e-4)
    @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[3], 0.1; atol = 1e-4) #without storage it should be 0.35
    @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) - system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(systemstates.se[t], 1.0 - system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
end

t=4
systemstates.branches[5,t] = 0
systemstates.branches[8,t] = 0
OPF._update!(pm, system, systemstates, settings, t)

@testset "t=4, L5 and L8 on outage" begin
    @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    @test isapprox(sum(systemstates.plc[:]), 0.40; atol = 1e-4)
    @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[3], 0; atol = 1e-4) #without storage it should be 0.35
    @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[5], 0.20; atol = 1e-4)
    @test isapprox(systemstates.plc[6], 0.20; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(systemstates.se[t], 0.75 + system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
end

t=5
systemstates.branches[3,t] = 0
systemstates.branches[4,t] = 0
systemstates.branches[8,t] = 0
OPF._update!(pm, system, systemstates, settings, t)

@testset "t=5, L3, L4 and L8 on outage" begin
    @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    @test isapprox(sum(systemstates.plc[:]), 0.15; atol = 1e-4)
    @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[3], 0.15; atol = 1e-4)
    @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + 0.25; atol = 1e-4)
    @test isapprox(systemstates.se[t], 1.0 + 0.25; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
end

t=6
systemstates.branches[2,t] = 0
systemstates.branches[7,t] = 0
systemstates.generators[1,t] = 0
systemstates.generators[2,t] = 0
systemstates.generators[3,t] = 0
OPF._update!(pm, system, systemstates, settings, t) 

@testset "L2 and L7 on outage, generation reduced" begin
    @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    @test isapprox(sum(systemstates.plc[:]), 0.74; atol = 1e-4)
    @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[3], 0.74; atol = 1e-4)
    @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + 0.25; atol = 1e-4)
    @test isapprox(systemstates.se[t], 1.0 + 0.25 + 0.25; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(pm, system.branches)[3]["pf"], 0.71; atol = 1e-4)
end

t=7
systemstates.branches[2,t] = 0
systemstates.generators[1,t] = 0
systemstates.generators[2,t] = 0
OPF._update!(pm, system, systemstates, settings, t) 

@testset "L2 on outage, generation reduced" begin
    @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
    @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) - 0.25; atol = 1e-4)
    @test isapprox(systemstates.se[t], 1.0 + 0.25; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
end

t=8
systemstates.branches[1,t] = 0
systemstates.branches[6,t] = 0
OPF._update!(pm, system, systemstates, settings, t) 

@testset "L1 and L6 on outage" begin
    @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    @test isapprox(sum(systemstates.plc[:]), 0.23; atol = 1e-4)
    @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[3], 0.23; atol = 1e-4)
    @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + 0.25; atol = 1e-4)
    @test isapprox(systemstates.se[t], 1.0 + 0.25 + 0.25; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(pm, system.branches)[2]["pf"], 0.71; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(pm, system.branches)[7]["pf"], 0.71; atol = 1e-4)
end

t=9
systemstates.branches[4,t] = 0
OPF._update!(pm, system, systemstates, settings, t) 

@testset "L1 and L6 on outage" begin
    @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
    @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
    @test isapprox(sum(systemstates.plc[:]), 0; atol = 1e-4)
    @test isapprox(systemstates.plc[1], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[2], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[3], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[4], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[5], 0; atol = 1e-4)
    @test isapprox(systemstates.plc[6], 0; atol = 1e-4)
    @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(systemstates.plc[:]) + 0.25; atol = 1e-4)
    @test isapprox(systemstates.se[t], 1.0 + 0.25 + 0.25 + 0.25; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
end


systemstates.plc[:]
systemstates.se[t]
OPF.build_sol_values(OPF.var(pm, :ps, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sc, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sd, 1))[1]
OPF.build_sol_values(pm, system.branches)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))


using PowerModels
data = PowerModels.parse_file(rawfile)
PowerModels.replicate(data, 2)
pmi = PowerModels.instantiate_model(data, PowerModels.DCPPowerModel, PowerModels.build_mn_opf_strg)
println(pmi.model)




println(Float32.(systemstates.se[t]*100))
println(Float32.(systemstates.plc[:]*100))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :sc, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :sd, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :qs, 1)*100)))))
println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :qsc, 1)*100)))))
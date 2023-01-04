using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")

settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.DCMPPowerModel)
timeseriesfile = "test/data/RTS/Loads_system.xlsx"
rawfile = "test/data/RTS/Base/RTS.m"
reliabilityfile = "test/data/RTS/Base/R_RTS.m"
system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)

data = OPF.build_network(rawfile, symbol=false)
load_pd = Dict{Int, Float64}()
for (k,v) in data["load"]
    load_pd[parse(Int,k)] = v["pd"]
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
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])


t=2
CompositeSystems.field(systemstates, :branches)[1,t] = 0
CompositeSystems.field(systemstates, :branches)[4,t] = 0
CompositeSystems.field(systemstates, :branches)[10,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=3
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=4
CompositeSystems.field(systemstates, :branches)[25,t] = 0
CompositeSystems.field(systemstates, :branches)[26,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=5
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=6
CompositeSystems.field(systemstates, :branches)[32,t] = 0
CompositeSystems.field(systemstates, :branches)[33,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=7
CompositeSystems.field(systemstates, :branches)[1,t] = 0
CompositeSystems.field(systemstates, :branches)[8,t] = 0
CompositeSystems.field(systemstates, :branches)[10,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
sum(systemstates.plc[:,t])
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=8
CompositeSystems.field(systemstates, :branches)[7,t] = 0
CompositeSystems.field(systemstates, :branches)[19,t] = 0
CompositeSystems.field(systemstates, :branches)[29,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
sum(systemstates.plc[:,t])
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=9
CompositeSystems.field(systemstates, :branches)[7,t] = 0
CompositeSystems.field(systemstates, :branches)[23,t] = 0
CompositeSystems.field(systemstates, :branches)[29,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
sum(systemstates.plc[:,t])
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=10
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
sum(systemstates.plc[:,t])
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=11
CompositeSystems.field(systemstates, :branches)[25,t] = 0
CompositeSystems.field(systemstates, :branches)[26,t] = 0
CompositeSystems.field(systemstates, :branches)[28,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
sum(systemstates.plc[:,t])
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=12
CompositeSystems.field(systemstates, :branches)[29,t] = 0
CompositeSystems.field(systemstates, :branches)[36,t] = 0
CompositeSystems.field(systemstates, :branches)[37,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
sum(systemstates.plc[:,t])
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])

t=13
CompositeSystems.field(systemstates, :generators_de)[1,t] = 0
CompositeSystems.field(systemstates, :generators_de)[2,t] = 0
CompositeSystems.field(systemstates, :generators_de)[4,t] = 0
CompositeSystems.field(systemstates, :generators_de)[6,t] = 0
CompositeSystems.field(systemstates, :branches)[1,t] = 0
CompositeSystems.field(systemstates, :branches)[4,t] = 0
CompositeSystems.field(systemstates, :branches)[10,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)
JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
systemstates.plc[:,t]
sum(systemstates.plc[:,t])
result_pg = OPF.build_sol_values(OPF.var(pm, :pg, :))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_branch_values(pm, system.branches)
total_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
total_qg = sum(system.loads.pd[:,t])




system.loads.cost
systemstates.buses[:,t]


pmi = PowerModels.instantiate_model(data, PowerModels.DCMPPowerModel, PowerModels.build_opf)
pm.model
pmi.model
println(pm.model)
println(pmi.model)


data["branch"]["9"]["br_status"] = 0
data["load"]["5"]["status"] = 0
result = PowerModels.solve_opf(data, PowerModels.DCPPowerModel, ipopt_optimizer_1)







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
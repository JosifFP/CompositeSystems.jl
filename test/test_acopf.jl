import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status, @expression
import PowerModels
import BenchmarkTools: @btime
import CompositeSystems: field
import CompositeSystems.OPF: field, topology
import InfrastructureModels

using Test
include("solvers.jl")

settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    #juniper_optimizer_1,
    modelmode = JuMP.AUTOMATIC,
    powermodel = OPF.LPACCPowerModel
)

RawFile = "test/data/RTS/Base/RTS.m"
ReliabilityFile = "test/data/RTS/Base/R_RTS.m"
TimeSeriesFile = "test/data/RTS/Loads_system.xlsx"

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Shortfall())
timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)
system = BaseModule.SystemModel(RawFile, ReliabilityFile, timeseries_load, SParametrics)

threads = Base.Threads.nthreads()
sampleseeds = Channel{Int}(2*threads)
results = CompositeAdequacy.resultchannel(method, resultspecs, threads)
Threads.@spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.


method = CompositeAdequacy.SequentialMCS(samples=1, seed=100, threaded=false)
states = CompositeAdequacy.SystemStates(system)
model = OPF.jump_model(settings.modelmode, deepcopy(settings.optimizer))
pm = OPF.abstract_model(settings.powermodel, OPF.Topology(system), model)


pm.topology.buspairs




recorders = CompositeAdequacy.accumulator.(system, method, resultspecs)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.seed!(rng, (method.seed, 1))

for s in sampleseeds
    CompositeAdequacy.initialize_states!(rng, states, system)
    CompositeAdequacy.initialize_powermodel!(pm, system, states, results=true)

    if s==8
        for t=2:8736
            CompositeAdequacy.update!(pm, system, states, t)
        end
    end
end

JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
OPF.build_sol_values(OPF.var(pm, :pg, 1))
OPF.build_sol_values(OPF.var(pm, :qg, 1))
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, 1))))
sum(values(OPF.build_sol_values(OPF.var(pm, :qg, 1))))
sum(states.plc[:,t])
sum(states.qlc[:,t])/sum(states.plc[:,t])





t=3
CompositeSystems.field(states, :branches)[3,t] = 0
states.system[t] = 0
CompositeAdequacy.update!(pm, system, states, t)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
OPF.build_sol_values(OPF.var(pm, :pg, 1))
OPF.build_sol_values(OPF.var(pm, :qg, 1))
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, 1))))
sum(values(OPF.build_sol_values(OPF.var(pm, :qg, 1))))
sum(states.plc[:,t])
sum(states.qlc[:,t])/sum(states.plc[:,t])


t=4
CompositeSystems.field(states, :branches)[3,t] = 0
CompositeSystems.field(states, :branches)[5,t] = 0
CompositeSystems.field(states, :branches)[8,t] = 0
states.system[t] = 0
CompositeAdequacy.update!(pm, system, states, t)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
OPF.build_sol_values(OPF.var(pm, :pg, 1))
OPF.build_sol_values(OPF.var(pm, :qg, 1))
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, 1))))
sum(values(OPF.build_sol_values(OPF.var(pm, :qg, 1))))
sum(states.plc[:,t])
sum(states.qlc[:,t])/sum(states.plc[:,t])

t=5
CompositeSystems.field(states, :branches)[3,t] = 0
states.system[t] = 0
CompositeAdequacy.update!(pm, system, states, t)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
OPF.build_sol_values(OPF.var(pm, :pg, 1))
OPF.build_sol_values(OPF.var(pm, :qg, 1))
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, 1))))
sum(values(OPF.build_sol_values(OPF.var(pm, :qg, 1))))
sum(states.plc[:,t])
sum(states.qlc[:,t])/sum(states.plc[:,t])

states.branches[:,t]
states.generators[:,t]

t=6
CompositeAdequacy.update!(pm, system, states, t)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
OPF.build_sol_values(OPF.var(pm, :pg, 1))
OPF.build_sol_values(OPF.var(pm, :qg, 1))
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, 1))))
sum(values(OPF.build_sol_values(OPF.var(pm, :qg, 1))))
sum(states.plc[:,t])
sum(states.qlc[:,t])/sum(states.plc[:,t])

states.branches[:,t]
states.generators[:,t]
pm.topology.branches_idxs
pm.topology.buses_idxs
pm.topology.buspairs






#CompositeSystems.field(states, :branches)[3,t] = 0
CompositeSystems.field(states, :branches)[5,t] = 0
#CompositeSystems.field(states, :branches)[8,t] = 0
#CompositeSystems.field(states, :generators)[11,t] = 0
states.system[t] = 0

OPF.update_topology!(pm, system, states, t)
states.buses








OPF.solve!(pm, system, states, t)

JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
OPF.build_sol_values(OPF.var(pm, :pg, t))
OPF.build_sol_values(OPF.var(pm, :qg, t))
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
sum(values(OPF.build_sol_values(OPF.var(pm, :qg, t))))
sum(states.plc)
sum(states.qlc)/sum(states.plc)
OPF._phi_to_vm(OPF.build_sol_values(OPF.var(pm, :phi, t)))
OPF.build_sol_values(OPF.var(pm, :va, t))
println(Float32.(values(sort(InfrastructureModels.build_solution_values(OPF.var(pm, :p, 1))))).*100)



#OPF.update_arcs!(system.branches, pm.topology, pm_ini.topology, states.branches, t)
#OPF.solve!(pm, system, states, t)

#println(pm.model)
#pm.model


data = PowerModels.parse_file(RawFile)
PowerModels.standardize_cost_terms!(data, order=1)
result = PowerModels.run_opf(data, PowerModels.LPACCPowerModel, gurobi_optimizer_1)
PowerModels._sol_data_model_lpac!(result["solution"])
result["solution"]
result["solution"]["bus"]

pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_opf)
pmi.model
println(pmi.model)






@test isapprox(sum(systemstates.plc[:]), 0.150; atol = 1e-3)
@test isapprox(systemstates.plc[1,t], 0; atol = 1e-3)
@test isapprox(systemstates.plc[2,t], 0.150; atol = 1e-3)
@test isapprox(systemstates.plc[3,t], 0; atol = 1e-3)
@test isapprox(systemstates.plc[4,t], 0; atol = 1e-3)
@test isapprox(systemstates.plc[5,t], 0; atol = 1e-3)
pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
@test isapprox(pg, 1.7; atol = 1e-2)
@test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR

qg = sum(values(OPF.build_sol_values(OPF.var(pm, :qg, t))))
OPF.build_sol_values(OPF.var(pm, :qg, t))
OPF.build_sol_values(OPF.var(pm, :va, t))
OPF.build_sol_values(OPF.var(pm, :phi, t))





using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")

settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
#settings = CompositeSystems.Settings(ipopt_optimizer_1, modelmode = JuMP.AUTOMATIC, powermodel = OPF.LPACCPowerModel)
rawfile = "test/data/RBTS/Base/RBTS.m"
reliabilityfile = "test/data/RBTS/Base/R_RBTS.m"
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
t=3
CompositeSystems.field(systemstates, :generators)[3,t] = 0
CompositeSystems.field(systemstates, :generators)[7,t] = 0
CompositeSystems.field(systemstates, :generators)[8,t] = 0
CompositeSystems.field(systemstates, :generators)[9,t] = 0
systemstates.system[t] = 0
OPF._update!(pm, system, systemstates, t)
t=4
CompositeSystems.field(systemstates, :branches)[5,t] = 0
CompositeSystems.field(systemstates, :branches)[8,t] = 0
systemstates.system[t] = 0
OPF._update!(pm, system, systemstates, t)
t=5
OPF._update!(pm, system, systemstates, t)  

JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))

systemstates.branches[:,t]
systemstates.generators[:,t]
systemstates.generators_de[:,t]
systemstates.loads[:,t]

pm.topology.buspairs


println(pm.model)
#hello

JuMP.termination_status(pm.model)






















JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))
data = OPF.build_network(rawfile, symbol=false)
data["branch"]["1"]["br_status"] = 0
data["branch"]["8"]["br_status"] = 0
data["branch"]["10"]["br_status"] = 0
data["shunt"]["1"]["status"] = 0
PowerModels.simplify_network!(data)
result = PowerModels.solve_opf(data, PowerModels.LPACCPowerModel, ipopt_optimizer_1)
pmi = PowerModels.instantiate_model(data, PowerModels.LPACCPowerModel, PowerModels.build_opf)
pm.model
pmi.model
println(pm.model)
println(pmi.model)
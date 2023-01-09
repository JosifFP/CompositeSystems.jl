using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
#using ProfileView, Profile

include("solvers.jl")

settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode = JuMP.AUTOMATIC)
timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile = "test/data/SMCS/RTS_79_A/RTS.m"
Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)    

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

t=2
CompositeSystems.field(systemstates, :branches)[11,t] = 0
systemstates.system[t] = 0
OPF._update!(pm, system, systemstates, t)
systemstates.plc[:,t]
println(pm.model)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
result_pf = OPF.build_sol_branch_values(pm, system.branches)

systemstates.generators[:,t]
systemstates.generators_de[:,t]

system.generators.pmax[1]
system.generators.pmax[2]
system.generators.pmax[3]

pm.topology.buses_idxs
pm.topology.generators_idxs



systemstates.generators[:,t]
systemstates.generators_de[:,t]
pm.topology.generators_nodes

pm.topology.ge


println(pm.model)


t=2
CompositeSystems.field(systemstates, :branches)[1,t] = 0
CompositeSystems.field(systemstates, :branches)[8,t] = 0
CompositeSystems.field(systemstates, :branches)[10,t] = 0
CompositeSystems.field(systemstates, :shunts)[1,t] = 0
systemstates.system[t] = 0
CompositeAdequacy.update!(pm, system, systemstates, t)

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
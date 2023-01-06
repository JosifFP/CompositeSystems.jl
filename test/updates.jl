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
timeseriesfile = "test/data/RTS/Loads_system.xlsx"
rawfile = "test/data/RTS/Base/RTS.m"
reliabilityfile = "test/data/RTS/Base/R_RTS2.m"
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

JuMP.termination_status(pm.model)
JuMP.primal_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))
println(pm.model)

t=2
CompositeAdequacy.update!(pm, system, systemstates, t)
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
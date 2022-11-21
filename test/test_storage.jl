include("solvers.jl")
import PowerModels, JuMP
using Test
import PRATS: PRATS, BaseModule, OPF, CompositeAdequacy
PowerModels.silence()

# gurobi_optimizer_1
# juniper_optimizer_2
# ipopt_optimizer_3
RawFile = "test/data/RBTS/RBTS.m"
RawFile_strg = "test/data/RBTS/RBTS_strg.m"
ReliabilityFile = "test/data/RBTS/R_RBTS.m"
ReliabilityFile_strg = "test/data/RBTS/R_RBTS_strg.m"
TimeSeriesFile = "test/data/RBTS/Loads.xlsx"

settings = PRATS.Settings(
    gurobi_optimizer_1,
    modelmode = JuMP.AUTOMATIC
)

timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)
system = BaseModule.SystemModel(RawFile_strg, ReliabilityFile_strg, timeseries_load, SParametrics)
PRATS.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
model = OPF.JumpModel(settings.modelmode, deepcopy(settings.optimizer))
pm = OPF.PowerModel(settings.powermodel, OPF.Topology(system), model)
OPF.initialize_pm_containers!(pm, system; timeseries=false)
systemstates = OPF.SystemStates(system, available=true)
t=1

#system.loads.pd[:,t] = system.loads.pd[:,t]*1.5
OPF.build_method!(pm, system, systemstates, t)
OPF.optimize_method!(pm)
OPF.build_result!(pm, system, systemstates, t)

sum(values(sort(OPF.build_sol_values(OPF.var(pm, :pg, 1)*100))))
sum(system.loads.pd[:,t]*100)


OPF.build_sol_values(OPF.var(pm, :se, t))[1]
OPF.build_sol_values(OPF.var(pm, :sc, t))[1]
OPF.build_sol_values(OPF.var(pm, :sd, t))[1]
OPF.build_sol_values(OPF.var(pm, :ps, t))[1]




t=1
data_strg = PowerModels.parse_file(RawFile_strg)
PowerModels.standardize_cost_terms!(data_strg, order=1)
data_strg["load"]["1"]
for (k,v) in data_strg["load"]
    v["pd"] = system.loads.pd[parse(Int,k),t]*1.5
end

result_strg = PowerModels._solve_opf_strg(data_strg, PowerModels.DCPPowerModel, ipopt_optimizer_3)
result_strg["solution"]
result_strg["solution"]["bus"]
result_strg["solution"]["gen"]
result_strg["solution"]["storage"]["1"]
@show result_strg["solution"]["branch"]

pm.topology.busarcs




for t in 1:24
    system.loads.pd[:,t] = system.loads.pd[:,t]*1.25
    OPF.build_method!(pm, system, t)
    OPF.optimize_method!(pm)
    OPF.build_result!(pm, system, systemstates, t)
    #println(values(sort(OPF.build_sol_values(OPF.var(pm, :pg, 1)*100))))
    #println(Float16.(values(sort(InfrastructureModels.build_solution_values(var(pm, :p, 1))))))
    println(values(sort(OPF.build_sol_values(OPF.var(pm, :va, 1)*180/pi))))
    OPF.empty_model!(pm)
end









JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)

OPF.build_sol_values(OPF.var(pm, :se, t))[1]
OPF.build_sol_values(OPF.var(pm, :sc, t))[1]
OPF.build_sol_values(OPF.var(pm, :sd, t))[1]
OPF.build_sol_values(OPF.var(pm, :ps, t))[1]

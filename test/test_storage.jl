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
#data = PowerModels.parse_file(RawFile)
data_strg = PowerModels.parse_file(RawFile_strg)
#@show data_strg["storage"]["1"]

settings = PRATS.Settings(
    gurobi_optimizer_1,
    modelmode = JuMP.AUTOMATIC
)

system = BaseModule.SystemModel(RawFile_strg, ReliabilityFile_strg)
PRATS.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
model = OPF.JumpModel(settings.modelmode, deepcopy(settings.optimizer))
pm = OPF.PowerModel(settings.powermodel, OPF.Topology(system), model)
OPF.initialize_pm_containers!(pm, system; timeseries=false)
systemstates = OPF.SystemStates(system, available=true)


t=1
PRATS.field(systemstates, :branches)[3,t] = 0
PRATS.field(systemstates, :branches)[4,t] = 0
PRATS.field(systemstates, :branches)[8,t] = 0
systemstates.system[t] = 0
OPF.build_method!(pm, system, t)
pm.model
println(pm.model)
pm.con


OPF.optimize_method!(pm)
OPF.build_result!(pm, system, t)
sum(values(OPF.build_sol_values(OPF.var(pm, :pg, t))))
sum(system.loads.pd)
OPF.build_sol_values(OPF.var(pm, :se, t))[1]
OPF.build_sol_values(OPF.var(pm, :sc, t))[1]
OPF.build_sol_values(OPF.var(pm, :sd, t))[1]
OPF.build_sol_values(OPF.var(pm, :ps, t))[1]




JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)


PowerModels.standardize_cost_terms!(data, order=1)
PowerModels.standardize_cost_terms!(data_strg, order=1)

result = PowerModels.solve_dc_opf(data, ipopt_optimizer_3)

result["solution"]
result["solution"]["bus"]
@show result["solution"]["branch"]


result_strg = PowerModels._solve_opf_strg(data_strg, PowerModels.DCPPowerModel, ipopt_optimizer_3)
result_strg["solution"]
result_strg["solution"]["bus"]
result_strg["solution"]["gen"]
result_strg["solution"]["storage"]["1"]

@show result_strg["solution"]["branch"]




@test result["termination_status"] == JuMP.LOCALLY_SOLVED
@test isapprox(result["objective"], 16840.7; atol = 1e0)
@test isapprox(result["solution"]["storage"]["1"]["se"],  0.0; atol = 1e0)
@test isapprox(result["solution"]["storage"]["1"]["ps"], -0.176871; atol = 1e-2)
@test isapprox(result["solution"]["storage"]["2"]["se"],  0.0; atol = 1e0)
@test isapprox(result["solution"]["storage"]["2"]["ps"], -0.2345009; atol = 1e-2)



JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
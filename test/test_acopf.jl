import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using Test
include("solvers.jl")

settings = CompositeSystems.Settings(
    gurobi_optimizer_1,
    modelmode = JuMP.AUTOMATIC,
    powermodel = OPF.LPACCPowerModel
)

RawFile = "test/data/RBTS/Base/RBTS.m"
ReliabilityFile = "test/data/RBTS/Base/R_RBTS.m"
system = BaseModule.SystemModel(RawFile, ReliabilityFile)

CompositeSystems.field(system, :loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
model = OPF.JumpModel(settings.modelmode, deepcopy(settings.optimizer))
pm = OPF.PowerModel(settings.powermodel, OPF.Topology(system), model)
OPF.initialize_pm_containers!(pm, system; timeseries=false)
systemstates = OPF.SystemStates(system, available=true)
#CompositeSystems.field(systemstates, :branches)[3,t] = 0
#CompositeSystems.field(systemstates, :branches)[4,t] = 0
#CompositeSystems.field(systemstates, :branches)[8,t] = 0
#systemstates.system[t] = 0
t=1
CompositeAdequacy.solve!(pm, system, systemstates, t)
OPF.build_sol_values(OPF.var(pm, :pg, t))
OPF.build_sol_values(OPF.var(pm, :qg, t))

sum(system.loads.pd)

data = PowerModels.parse_file(RawFile)
PowerModels.standardize_cost_terms!(data, order=1)
result = PowerModels.run_opf(data, PowerModels.LPACCPowerModel, gurobi_optimizer_1)
result["solution"]
result["solution"]["gen"]


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




JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
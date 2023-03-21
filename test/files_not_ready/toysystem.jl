import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP
import JuMP: termination_status
import BenchmarkTools: @btime
using Test
include("solvers.jl")

settings = CompositeSystems.Settings(
    juniper_optimizer_1;
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false
)

timeseriesfile = "test/data/toysystem/Loads_system.xlsx"
rawfile = "test/data/toysystem/toysystem.m"
Base_reliabilityfile = "test/data/toysystem/R_toysystem.m"
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile)
pm = OPF.abstract_model(system, settings)
systemstates = OPF.SystemStates(system, available=true)
OPF.build_problem!(pm, system, 1)
t=1
OPF._update!(pm, system, systemstates, settings, t)

systemstates.plc[:]
result_pg = sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :))))
values(OPF.build_sol_values(OPF.var(pm, :pg, :)))
result_va = OPF.build_sol_values(OPF.var(pm, :va, :))
result_pf = OPF.build_sol_values(pm, system.branches)
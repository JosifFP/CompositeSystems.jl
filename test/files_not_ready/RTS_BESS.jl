using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using XLSX, Dates
include("solvers.jl")

gurobi_optimizer = JuMP.optimizer_with_attributes(
    Gurobi.Optimizer,
    #"gurobi_env" => GRB_ENV, 
    "Presolve"=>1, 
    "PreCrush"=>1, 
    "OutputFlag"=>0, 
    "LogToConsole"=>0, 
    "NonConvex"=>2, 
    "NumericFocus"=>3, 
    "Threads"=>4
)

resultspecs = (Shortfall(), Utilization())

settings = CompositeSystems.Settings(
    gurobi_optimizer,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    set_string_names_on_creation = true,
    count_samples = true
)

timeseriesfile_before = "test/data/RTS_79_A/SYSTEM_LOADS.xlsx"
rawfile_before = "test/data/RTS_79_A/RTS_AC_HIGHRATE.m"
Base_reliabilityfile_before = "test/data/RTS_79_A/R_RTS.m"

timeseriesfile_after_100 = "test/data/RTS/SYSTEM_LOADS.xlsx"
rawfile_after_100 = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile_after_100 = "test/data/others/Storage/R_RTS_strg.m"

timeseriesfile_after_96 = "test/data/RTS/SYSTEM_LOADS.xlsx"
rawfile_after_96 = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile_after_96 = "test/data/others/Storage/R_RTS_strg_2.m"

loads = [
    1 => 0.038,
    2 => 0.034,
    3 => 0.063,
    4 => 0.026,
    5 => 0.025,
    6 => 0.048,
    7 => 0.044,
    8 => 0.06,
    9 => 0.061,
    10 => 0.068,
    11 => 0.093,
    12 => 0.068,
    13 => 0.111,
    14 => 0.035,
    15 => 0.117,
    16 => 0.064,
    17 => 0.045
]

smc = CompositeAdequacy.SequentialMCS(samples=2000, seed=100, threaded=true)
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

sys_before = BaseModule.SystemModel(rawfile_before, Base_reliabilityfile_before, timeseriesfile_before)
sys_after_100 = BaseModule.SystemModel(rawfile_after_100, Base_reliabilityfile_after_100, timeseriesfile_after_100)
sys_after_96 = BaseModule.SystemModel(rawfile_after_96, Base_reliabilityfile_after_96, timeseriesfile_after_96)

sys_before.branches.rate_a[11] = sys_before.branches.rate_a[11]*0.75
sys_before.branches.rate_a[12] = sys_before.branches.rate_a[12]*0.75
sys_before.branches.rate_a[13] = sys_before.branches.rate_a[13]*0.75

sys_after_100.branches.rate_a[11] = sys_after_100.branches.rate_a[11]*0.75
sys_after_100.branches.rate_a[12] = sys_after_100.branches.rate_a[12]*0.75
sys_after_100.branches.rate_a[13] = sys_after_100.branches.rate_a[13]*0.75

sys_after_96.branches.rate_a[11] = sys_after_96.branches.rate_a[11]*0.75
sys_after_96.branches.rate_a[12] = sys_after_96.branches.rate_a[12]*0.75
sys_after_96.branches.rate_a[13] = sys_after_96.branches.rate_a[13]*0.75

sys_after_100.storages.buses[1] = 8
sys_after_100.storages.charge_rating[1] = 1.0
sys_after_100.storages.discharge_rating[1] = 1.0
sys_after_100.storages.thermal_rating[1] = 1.0
sys_after_100.storages.energy_rating[1] = 2.0

shortfall_before, util_before = CompositeSystems.assess(sys_after_100, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_after_100, shortfall_before)


#system = sys_after_100
system = sys_before
threads = Base.Threads.nthreads()
sampleseeds = CompositeSystems.Channel{Int}(2*threads)
results = CompositeAdequacy.resultchannel(smc, resultspecs, threads)
Threads.@spawn makeseeds(sampleseeds, smc.nsamples)

pm = OPF.abstract_model(system, settings)
componentstates = OPF.ComponentStates(system)
statetransition = OPF.StateTransition(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
OPF.build_problem!(pm, system, 1)

s=1
CompositeAdequacy.seed!(rng, (smc.seed, s))
CompositeAdequacy.initialize!(rng, componentstates, statetransition, system)

for t in 1:230
    CompositeAdequacy.update!(rng, componentstates, statetransition, pm, system, settings, t)
    CompositeAdequacy.solve!(pm, system, componentstates, settings, t)
end

componenttopology(pm, :stored_energy)[:,15:25]
componentstates.branches[:,15:25]
componentstates.generators[:,15:25]
componentstates.buses[:,15:25]
componentstates.storages[:,15:25]
componentstates.loads[:,15:25]


componenttopology(pm, :stored_energy)[:,210:230]
componentstates.branches[:,210:230]
componentstates.generators[:,210:230]
componentstates.buses[:,210:230]
componentstates.storages[:,210:230]
componentstates.loads[:,210:230]




t=231
CompositeAdequacy.update!(rng, componentstates, statetransition, pm, system, settings, t)
CompositeAdequacy.solve!(pm, system, componentstates, settings, t)

componenttopology(pm, :stored_energy)[:,229:231]


shortfall_after_100, _ = CompositeSystems.assess(sys_after_100, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_after_100, shortfall_after_100)



sys_after_100.storages.buses[1] = 8
sys_after_100.storages.charge_rating[1] = 1.0
sys_after_100.storages.discharge_rating[1] = 1.0
sys_after_100.storages.thermal_rating[1] = 1.0
sys_after_100.storages.energy_rating[1] = 2.0


shortfall_after_100, _ = CompositeSystems.assess(sys_after_100, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_after_100, shortfall_after_100)





################################################################
sys_after_96.storages.buses[1] = 8
sys_after_96.storages.charge_rating[1] = 1.0
sys_after_96.storages.discharge_rating[1] = 1.0
sys_after_96.storages.thermal_rating[1] = 1.0
sys_after_96.storages.energy_rating[1] = 2.0

shortfall_after_96, _ = CompositeSystems.assess(sys_after_96, smc, settings, resultspecs...)
CompositeAdequacy.print_results(sys_after_96, shortfall_after_96)
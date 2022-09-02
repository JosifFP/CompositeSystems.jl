using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
import BenchmarkTools: @btime

RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
optimizer = [
    JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), 
    JuMP.optimizer_with_attributes(Juniper.Optimizer, 
    "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])]

threads = Base.Threads.nthreads()
sampleseeds = Channel{Int}(2)
simspec = PRATS.SequentialMonteCarlo(samples=1, seed=1)
resultspecs = (Flow(), Flow())
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)
systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)

s=1
CompositeAdequacy.seed!(rng, (simspec.seed, s))
CompositeAdequacy.initialize!(rng, systemstate, system)

t=1
#pm = advance!(systemstate, system, optimizer, t)
#data = create_dict_from_system!(system, t)

network_data = PRATSBase.conversion_to_pm_data(system.network)
# network_data["branch"][string(7)]["br_status"] = 0
# network_data["branch"][string(23)]["br_status"] = 0
# network_data["branch"][string(29)]["br_status"] = 0
# PRATSBase.SimplifyNetwork!(network_data)
@time pm = CompositeAdequacy.solve_model(network_data,CompositeAdequacy.DCPPowerModel, optimizer)
@time pm = CompositeAdequacy.solve_model(network_data,CompositeAdequacy.DCMLPowerModel, optimizer)
pm.solution["solution"]["total"]["P_load_curtailed"]*100






















#CompositeAdequacy.update_data_from_system!(network_data, system, t)
#CompositeAdequacy.apply_contingencies!(network_data, systemstate, system, t)
#PRATSBase.SimplifyNetwork!(network_data)

#pm = solve_model(network_data,CompositeAdequacy.DCPPowerModel, optimizer)
#pm.solution["solution"]["branch"]

#RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
#network_data = PowerModels.parse_file(RawFile)
network_data = PRATSBase.conversion_to_pm_data(system.network)
network_data["branch"][string(7)]["br_status"] = 0
network_data["branch"][string(23)]["br_status"] = 0
network_data["branch"][string(29)]["br_status"] = 0
PRATSBase.SimplifyNetwork!(network_data)
pm = CompositeAdequacy.solve_model(network_data, CompositeAdequacy.DCMLPowerModel, optimizer; condition = systemstate.condition[1])
pm.solution["solution"]["total"]["P_load_curtailed"]*100
pm.solution["solution"]["gen"][string(1)]["pg"]
pm.solution["solution"]["branch"][string(1)]["pf"


#direct mode, LC= 309/ T = 0.023169 seconds (26.02 k allocations: 1.284 MiB)
#normal mode, LC= 309/ T = 0.016620 seconds (26.02 k allocations: 1.284 MiB)

# pm.solution["solution"]
# pm.solution["solution"]["branch"]
# pm.solution["solution"]["load curtailment"]
# pm.solution["solution"]["total"]
pm.solution["solution"]["total"]["P_load_curtailed"]*100
JuMP.optimize!(opf_model)
JuMP.termination_status(opf_model)


pm = solve_model(network_data,CompositeAdequacy.DCPPowerModel, optimizer)
pm.solution["solution"]["total"]["P_load_curtailed"]*100

mn_data =  PowerModels.replicate(data, 5)
PowerModels.simplify_network!(mn_data)
@time result = PowerModels.solve_mn_opf(mn_data, DCPPowerModel, nlp_solver)
#147.777309 seconds (368.00 M allocations: 14.032 GiB, 27.82% gc time)
PowerModels.nws(pm)
#---------------------------------------------------------------------------------------------------------

method = PRATS.SequentialMonteCarlo(samples=1, seed=1, threaded=true)
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
#@time flow,flowtotal = PRATS.assess(system, method, resultspecs...)
#304.688904 seconds (858.66 M allocations: 42.810 GiB, 2.92% gc time)


using Profile
using ProfileView
Profile.clear()
@profile (for i=1:10; PRATS.assess(system, method, resultspecs...); end)
Profile.print()
ProfileView.view()

#----------------------------------------------------------------------------------------------------------
[j for j in eachindex(1:1) if any(abs.(system.branches.pf[:,j]).>system.branches.longterm_rating[:,j])]
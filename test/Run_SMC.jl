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
optimizer = [JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0), JuMP.optimizer_with_attributes(Juniper.Optimizer, 
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
model = [JuMP.direct_model(optimizer[i]) for i in eachindex(optimizer)]
network_data = PRATSBase.conversion_to_pm_data(system.network)

#t=1
#CompositeAdequacy.update_data_from_system!(network_data, system, t)
#CompositeAdequacy.apply_contingencies!(network_data, systemstate, system, t)
#PRATSBase.SimplifyNetwork!(network_data)

#pm = solve_model(network_data,CompositeAdequacy.DCPPowerModel, optimizer)
#pm.solution["solution"]["branch"]

#RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
#network_data = PowerModels.parse_file(RawFile)
network_data = PRATSBase.conversion_to_pm_data(system.network)
# network_data["branch"][string(7)]["br_status"] = 0
# network_data["branch"][string(23)]["br_status"] = 0
# network_data["branch"][string(29)]["br_status"] = 0
PRATSBase.SimplifyNetwork!(network_data)
pm = CompositeAdequacy.solve_model(network_data, CompositeAdequacy.DCMLPowerModel, optimizer; condition = systemstate.condition[1])
pm.solution["solution"]["total"]["P_load_curtailed"]*100

@time pm = CompositeAdequacy.solve_model(network_data, CompositeAdequacy.DCMLPowerModel, optimizer; condition = systemstate.condition[1])
#direct mode, LC= 309/ T = 0.023169 seconds (26.02 k allocations: 1.284 MiB)
#normal mode, LC= 309/ T = 0.016620 seconds (26.02 k allocations: 1.284 MiB)

# pm.solution["solution"]
# pm.solution["solution"]["branch"]
# pm.solution["solution"]["load curtailment"]
# pm.solution["solution"]["total"]
pm.solution["solution"]["total"]["P_load_curtailed"]*100


pm =  CompositeAdequacy.InitializeAbstractPowerModel(network_data, CompositeAdequacy.DCPPowerModel, optimizer)
CompositeAdequacy.ref_add!(pm.ref)
CompositeAdequacy.build_model(pm)

opf_model = pm.model

JuMP.optimize!(opf_model)
JuMP.termination_status(opf_model)

CompositeAdequacy.var_buspair_current_magnitude_sqr(pm)
CompositeAdequacy.var_bus_voltage_magnitude_sqr(pm)
CompositeAdequacy.constraint_voltage_magnitude_diff(pm)
JuMP.optimize!(pm.model)
JuMP.termination_status(pm.model)

pm = solve_model(network_data,CompositeAdequacy.DCPPowerModel, optimizer)
pm.solution["solution"]["total"]["P_load_curtailed"]*100

mn_data =  PowerModels.replicate(data, 5)
PowerModels.simplify_network!(mn_data)
@time result = PowerModels.solve_mn_opf(mn_data, DCPPowerModel, nlp_solver)
#147.777309 seconds (368.00 M allocations: 14.032 GiB, 27.82% gc time)
PowerModels.nws(pm)
#---------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------
#@time flow,flowtotal = PRATS.assess(system, method, resultspecs...)
#91.200354 seconds (211.09 M allocations: 10.594 GiB, 1.00% gc time, 0.00% compilation time

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

results["solution"]["total"]["P_load_curtailed"]*100

@show keys(results["solution"]["branch"])

system.branches.keys
CompositeAdequacy.update_systemmodel_branches!(system, results["solution"], 1)

update_data!(network_data, results["solution"])
network_data["branch"]["25"]



systemstate.condition #if it is true, it is a success state

if systemstate.condition == false
    apply_contingencies!(system, systemstate)
end

# using PowerModels
# RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
# network_data = PowerModels.parse_file(RawFile)
# optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
# update_data!(network_data, PowerModels.compute_dc_pf(network_data)["solution"])
# flow = calc_branch_flow_dc(network_data)

#using PowerModels
#RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
#network_data = PowerModels.parse_file(RawFile)
#PowerModels.simplify_network!(network_data)
# [info | PowerModels]: deactivating bus 24 due to dangling bus without generation, load or storage
# [info | PowerModels]: deactivating branch 27:(15,24) due to connecting bus status
# [info | PowerModels]: deactivating connected component Set([3]) due to isolation without generation, load or storage
# [info | PowerModels]: deactivating load 3 due to inactive bus 3
# [info | PowerModels]: network simplification fixpoint reached in 3 rounds

using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
import BenchmarkTools: @btime
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
nlp_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
network_data = PRATSBase.conversion_to_pm_data(system.network)
optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
t=1
CompositeAdequacy.update_data_from_system!(network_data, system, t)
@btime results = PowerModels.solve_dc_pf(network_data, nlp_solver)

update_data!(network_data, results["solution"])
update_data!(network_data, calc_branch_flow_dc(network_data))
container_key = [parse(Int,i) for i in keys(network_data["branch"])]
key_order = sortperm(container_key)
container_data = [i for i in container_key[key_order] if 
        any(abs(network_data["branch"][string(i)]["pf"]) > network_data["branch"][string(i)]["rate_a"])
] 


optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, 
"nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])
data = PowerModels.parse_file(RawFile)
data["branch"][string(1)]["br_status"] = 0
data["branch"][string(4)]["br_status"] = 0
data["branch"][string(10)]["br_status"] = 0
PRATSBase.SimplifyNetwork!(data)
PowerModels.silence()

@btime result = PowerModels.run_dc_pf(data, nlp_solver)
#6.529 ms (19002 allocations: 1015.83 KiB)

@btime native = PowerModels.compute_dc_pf(data)
#139.500 μs (1830 allocations: 138.86 KiB)
@btime result2 = PowerModels.solve_opf_bf(data, DCPPowerModel, optimizer)
@btime result2 = PowerModels.solve_opf_ptdf(data, DCPPowerModel, optimizer)
#18.408 ms (108667 allocations: 5.48 MiB)
@btime result2 = PowerModels.run_opf(data,DCPLLPowerModel, optimizer)
#278.692 ms (418800 allocations: 10.47 MiB)
@btime result = run_opf_bf(data, SOCBFPowerModel, optimizer)
#606.049 ms (1163128 allocations: 27.53 MiB)
@btime result = run_opf_bf(data, BFAPowerModel, optimizer)
# 546.140 ms (863214 allocations: 21.16 MiB)
@btime result = run_opb(data, DCPPowerModel, optimizer)
# 80.193 ms (64006 allocations: 1.83 MiB)


data = PowerModels.parse_file(RawFile)
@btime result = PowerModels.run_dc_pf(data, nlp_solver)
#2.752 ms (16335 allocations: 965.17 KiB)
@btime result2 = PowerModels.run_opf(data,DCPLLPowerModel, optimizer)
#43.249 ms (82845 allocations: 2.96 MiB)
@btime result = run_opf_bf(data, SOCBFPowerModel, optimizer)
#79.951 ms (186286 allocations: 6.31 MiB)
@btime result = run_opf_bf(data, SOCBFConicPowerModel, optimizer)
@btime result = run_opf_bf(data, BFAPowerModel, optimizer)
#49.908 ms (115713 allocations: 4.56 MiB)
@btime result = run_opb(data, DCPPowerModel, optimizer)
#12.205 ms (20779 allocations: 945.88 KiB)




results = PowerModels.run_dc_pf(data, nlp_solver)

#results = PowerModels.compute_dc_pf(data)
update_data!(data, results["solution"])
update_data!(data, calc_branch_flow_dc(data))



container_key = [parse(Int,i) for i in keys(data["branch"])]
key_order = sortperm(container_key)
container_data = [i for i in container_key[key_order] if any(abs(data["branch"][string(i)]["pf"]) > data["branch"][string(i)]["rate_a"])]

@show [Float16.(abs(data["branch"][string(i)]["pf"]) for i in container_key[key_order])]
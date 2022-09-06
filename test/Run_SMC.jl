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
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 8760)

resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMonteCarlo(samples=8, seed=1, verbose=false, threaded=true)
@time flow,shortfall = PRATS.assess(system, method, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)

#10 samples, 8760 hrs: 

#flow.nsamples
#flow.branches
#flow.timestamps
#flow.flow_mean
#flow.flow_branch_std
#flow.flow_branchperiod_std


shortfall.nsamples
shortfall.buses
shortfall.timestamps

shortfall.eventperiod_mean
shortfall.eventperiod_std

shortfall.eventperiod_bus_mean
shortfall.eventperiod_bus_std
shortfall.eventperiod_period_mean
shortfall.eventperiod_period_std
shortfall.eventperiod_busperiod_mean
shortfall.eventperiod_busperiod_std
shortfall.shortfall_mean
shortfall.shortfall_std
shortfall.shortfall_bus_std
shortfall.shortfall_period_std
shortfall.shortfall_busperiod_std

"********************************************************************************************************************************"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 8760)
method = PRATS.SequentialMonteCarlo(samples=1, seed=1, verbose=false, threaded=true)
@time flow,shortfall = PRATS.assess(system, method, resultspecs...)


system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
method = PRATS.SequentialMonteCarlo(samples=2, seed=1, verbose=false, threaded=true)
@time flow,shortfall = PRATS.assess(system, method, resultspecs...)









"********************************************************************************************************************************"

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
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 8760)
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
data =  CompositeAdequacy.create_dict_from_system(system, t)
model_type = CompositeAdequacy.apply_contingencies!(data, systemstate, system, t)
data["branch"][string(1)]["br_status"] = 0
data["branch"][string(4)]["br_status"] = 0
data["branch"][string(10)]["br_status"] = 0
PRATSBase.SimplifyNetwork!(data)
overloaded_lines = CompositeAdequacy.overloadings(data, try CompositeAdequacy.compute_dc_pf(data) catch ; "error" end)

@btime pm = CompositeAdequacy.SolveModel(data, model_type, optimizer, false)

# if overloaded_lines == true
#     pm = CompositeAdequacy.SolveModel(data, model_type, optimizer)
#     #update_systemmodel!(pm, system, t)
#     return pm
# else

data["branch"][string(1)]["br_status"] = 0
data["branch"][string(4)]["br_status"] = 0
data["branch"][string(10)]["br_status"] = 0
PRATSBase.SimplifyNetwork!(data)


try native = CompositeAdequacy.compute_dc_pf(data) catch; "error"end

native = CompositeAdequacy.compute_dc_pf(data)
PRATSBase.update_data!(data, native["solution"])
CompositeAdequacy.overloadings(data, native)

pm = CompositeAdequacy.SolveModel(data, model_type, optimizer, CompositeAdequacy.overloadings(data, native))
pm.solution
pm.solution["solution"]["load_curtailment"]

N = 8760
nbuses = length(system.network.load)
periodsdropped_total = CompositeAdequacy.meanvariance()
periodsdropped_bus = [CompositeAdequacy.meanvariance() for _ in 1:nbuses]
periodsdropped_period = [CompositeAdequacy.meanvariance() for _ in 1:N]
periodsdropped_busperiod = [CompositeAdequacy.meanvariance() for _ in 1:nbuses, _ in 1:N]
periodsdropped_total_currentsim = 0
periodsdropped_bus_currentsim = zeros(Float16, nbuses)
unservedload_total = CompositeAdequacy.meanvariance()
unservedload_bus = [CompositeAdequacy.meanvariance() for _ in 1:nbuses]
unservedload_period = [CompositeAdequacy.meanvariance() for _ in 1:N]
unservedload_busperiod = [CompositeAdequacy.meanvariance() for _ in 1:nbuses, _ in 1:N]
unservedload_total_currentsim = 0
unservedload_bus_currentsim = zeros(Float16, nbuses)


results = PowerModels.solve_dc_opf(data, nlp_solver)
gens=0
for (i, gen) in results["solution"]["gen"]
    gens += gen["pg"]*100
    println(gen["pg"]*100)
end
gens

#network_data = PowerModels.parse_file(RawFile)
# network_data["branch"][string(25)]["br_status"] = 0
# network_data["branch"][string(26)]["br_status"] = 0
# network_data["branch"][string(28)]["br_status"] = 0
# PRATSBase.SimplifyNetwork!(network_data)
#@time pm = CompositeAdequacy.SolveModel(network_data,CompositeAdequacy.DCPPowerModel, optimizer)
pm = CompositeAdequacy.SolveModel(network_data,CompositeAdequacy.DCMLPowerModel, optimizer)
pm.solution["solution"]["total"]["P_load_curtailed"]*100

pm.solution["solution"]["branch"]
pm.solution["solution"]["load_curtailment"]
N = 8760                                                    #timestep_count
L = 1                                                       #timestep_length
T = timeunits["h"]                                          #timestep_unit
P = powerunits["kW"]
E = energyunits["MWh"]
V = voltageunits["kV"]
p2e = conversionfactor(L,T,P,E)







"********************************************************************************************************************************"

import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
import BenchmarkTools: @btime
using PRATS: PRATSBase, CompositeAdequacy
PowerModels.silence()

optimizer = [
    JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0), 
    JuMP.optimizer_with_attributes(Juniper.Optimizer,"nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])]

RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
data = PowerModels.parse_file(RawFile)
#network_data["branch"][string(7)]["br_status"] = 0
#network_data["branch"][string(23)]["br_status"] = 0
#network_data["branch"][string(29)]["br_status"] = 0
#PRATSBase.SimplifyNetwork!(network_data)

native = CompositeAdequacy.compute_dc_pf(data)
PRATSBase.update_data!(data, native["solution"])




# for (i,branch) in data["branch"]
#     mva_fr = abs(branch["pf"])
#     mva_to = abs(branch["pt"])
#     rate_a = ["rate_a"]
#     if !isnan(branch["qf"]) && !isnan(branch["qt"])
#         mva_fr = sqrt(branch["pf"]^2 + branch["qf"]^2)
#         mva_to = sqrt(branch["pt"]^2 + branch["qt"]^2)
#     end

#     if mva_fr > rate_a || mva_to > rate_a    
# end


balance = PowerModels.calc_power_balance(network_data)
balance["bus"]

[j for j in eachindex(network_data["branch"]) if any(abs.(flow["branch"][string(j)]["pf"]).>network_data["branch"][j]["rate_a"])]
[j for j in eachindex(network_data["branch"]) if any(abs.(flow["branch"][string(j)]["pf"]).>network_data["branch"][j]["rate_a"])]


native["solution"]["branch"][string(7)]["pf"]
network_data["branch"][string(7)]["rate_a"]

[j for j in eachindex(network_data["branch"]) if any(abs.(native["solution"]["branch"][string(j)]["pf"]).>network_data["branch"][j]["rate_a"])]

[native["solution"]["branch"][string(j)]["pf"] for j in eachindex(native["solution"]["branch"])]


# if isempty([j for j in eachindex(network_data["branch"]) if any(abs(native["solution"]["branch"][string(j)]["pf"]).>network_data["branch"][j]["rate_a"])])
#     println("great")
# end



@time pm = CompositeAdequacy.SolveModel(network_data, CompositeAdequacy.DCPPowerModel, optimizer)
#0.014951 seconds (20.37 k allocations: 1.062 MiB, 25.04% compilation time)


pm.solution["solution"]["total"]
pm.solution["solution"]["total"]["P_load_curtailed"]*100


#function ContingencyAnalysis(network_data)
    PRATSBase.update_data!(network_data, PowerModels.compute_dc_pf(network_data)["solution"])
    flow = CompositeAdequacy.calc_branch_flow_dc(network_data)
    PRATSBase.update_data!(network_data, flow)
    CompositeAdequacy.update_systemmodel_branches!(system, flow, t)

for i in eachindex(system.branches.keys)
    system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
    system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])
end

[j for j in eachindex(1:1) if any(abs.(system.branches.pf[:,j]).>system.branches.longterm_rating[:,j])]




"********************************************************************************************************************************"
mn_data =  PowerModels.replicate(data, 5)
PowerModels.simplify_network!(mn_data)
result = PowerModels.solve_mn_opf(mn_data, DCPPowerModel, nlp_solver)
PowerModels.nws(pm)
using Profile
using ProfileView
Profile.clear()
@profile (for i=1:10; PRATS.assess(system, method, resultspecs...); end)
Profile.print()
ProfileView.view()
[j for j in eachindex(1:1) if any(abs.(system.branches.pf[:,j]).>system.branches.longterm_rating[:,j])]
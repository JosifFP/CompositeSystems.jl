using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime
"********************************************************************************************************************************"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 2160)

resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMonteCarlo(samples=100, seed=123, verbose=false, threaded=true)
@time shortfall,shortfall2 = PRATS.assess(system, method, resultspecs...)

PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)



nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "time_limit"=>1.5, "log_levels"=>[])

threads = Base.Threads.nthreads()
sampleseeds = CompositeAdequacy.Channel{Int}(2*threads)
systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.seed!(rng, (method.seed, 1))
@btime CompositeAdequacy.initialize!(rng, systemstate, system)
@btime dictionary = Dict{Symbol,Any}()
@btime pm = CompositeAdequacy.InitializeAbstractPowerModel(system.network, dictionary, CompositeAdequacy.AbstractDCPModel, optimizer)

"********************************************************************************************************************************"


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
using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime

RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 8760)

nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0)
#mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, 
    "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])

systemstate = CompositeAdequacy.SystemState(system)
dictionary = Dict{Symbol,Any}()
CompositeAdequacy.fill_dictionary!(system, dictionary)
pm = CompositeAdequacy.InitializeAbstractPowerModel(dictionary, CompositeAdequacy.AbstractDCPModel, optimizer)
CompositeAdequacy.ref_add!(dictionary)

data = deepcopy(dictionary)
#data = ref_initialize!(dictionary)
#data = CompositeAdequacy.create_dict_from_system(system)
data[:branch][7]["br_status"] = 0
data[:branch][23]["br_status"] = 0
data[:branch][29]["br_status"] = 0
data1 = deepcopy(data)
PRATSBase.SimplifyNetwork!(data1)
#ref_add!(data)
#ref_initialize!(data)
# data2 = deepcopy(PRATSBase.data_initialize!(data))
# PowerModels.simplify_network!(data2)
# data2 = PRATSBase.ref_initialize!(data2)
# @assert data2 == data1

CompositeAdequacy.ref_add!(data1)
pm.ref = deepcopy(data1)
CompositeAdequacy.build_model!(pm, CompositeAdequacy.LMOPFMethod)
CompositeAdequacy.optimization!(pm, pm.model, CompositeAdequacy.LMOPFMethod)
CompositeAdequacy.build_result!(pm, CompositeAdequacy.LMOPFMethod)
#JuMP.optimize!(pm.model)
JuMP.termination_status(pm.model)
JuMP.solution_summary(pm.model, verbose=true)
#CompositeAdequacy.build_result!(pm, CompositeAdequacy.LMOPFMethod)


#PowerModels.simplify_network!(data2)
#ref = PRATSBase.ref_initialize!(data2)
#CompositeAdequacy.ref_add!(ref)
#pm.ref = deepcopy(ref)

CompositeAdequacy.build_model!(pm, CompositeAdequacy.LMOPFMethod)
CompositeAdequacy.optimization!(pm, CompositeAdequacy.LMOPFMethod)
CompositeAdequacy.build_result!(pm, CompositeAdequacy.LMOPFMethod)


CompositeAdequacy.build_model!(pm, CompositeAdequacy.LMOPFMethod)
JuMP.optimize!(pm.model)
#JuMP.solution_summary(pm.model, verbose=false)

#using ContingencySolver
#ContingencySolver.build_opf_lc(ref, ContingencySolver.dc_opf_lc, JuMP.Model(optimizer; add_bridges = false))
JuMP.termination_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)



"********************************************************************************************************************************"
function f()
    JuMP.@expression(pm.model, container_1[i=1:length(keys(pm.ref[:bus]))], sum(pm.model[:p][a] for a in pm.ref[:bus_arcs][i]) + 
        sum(pm.model[:p_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i])
    )

    JuMP.@expression(pm.model, container_2[i=1:length(keys(pm.ref[:bus]))], sum(pm.model[:pg][g] for g in pm.ref[:bus_gens][i]) - 
        sum(load["pd"] for load in bus_loads) - sum(shunt["gs"] for shunt in bus_shunts)*1.0^2
    )
    container_2
    for i in 1:length(keys(pm.ref[:bus]))
        if typeof(container_1[i]) == GenericAffExpr
            JuMP.drop_zeros!(container_1[i])
        end
        if typeof(container_2[i]) == GenericAffExpr
            JuMP.drop_zeros!(container_2[i])
        end

        JuMP.@constraint(pm.model, container_1[i] == container_2[i])
    end
end

for i in keys(pm.ref[:bus])

   bus_loads = [pm.ref[:load][l] for l in pm.ref[:bus_loads][i]]
   bus_shunts = [pm.ref[:shunt][s] for s in pm.ref[:bus_shunts][i]]

   #sum of active power flow on lines from bus i + sum of active power flow on HVDC lines from bus i
   JuMP.@expression(pm.model, container_1[i=1:length(keys(pm.ref[:bus]))], sum(pm.model[:p][a] for a in pm.ref[:bus_arcs][i]) + sum(pm.model[:p_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i]))

   # sum of active power generation at bus i - sum of active load consumption at bus i - sum of active shunt element injections at bus i
   container_2 = JuMP.@expression(pm.model, [i=1:length(keys(pm.ref[:bus]))], sum(pm.model[:pg][g] for g in pm.ref[:bus_gens][i]) - sum(load["pd"] for load in bus_loads) - sum(shunt["gs"] for shunt in bus_shunts)*1.0^2)
   
   JuMP.drop_zeros!(container_1)
   JuMP.drop_zeros!(container_2)
   JuMP.@constraint(pm.model, container_1 == container)

end


[j for j in eachindex(data["branch"]) if any(data["branch"]["1"]["br_status"] .!= 1)]
[j for j in eachindex(data["branch"]) if any(abs.(native["branch"][string(j)]["pf"]).>data["branch"][j]["rate_a"])]

nbuses = length(system.network.load)
periodsdropped_total = CompositeAdequacy.meanvariance()
periodsdropped_bus = [CompositeAdequacy.meanvariance() for _ in 1:nbuses]
periodsdropped_period = [CompositeAdequacy.meanvariance() for _ in 1:N]
periodsdropped_busperiod = [CompositeAdequacy.meanvariance() for _ in 1:nbuses, _ in 1:365]
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
#@time pm = CompositeAdequacy.SolveModel(network_data,CompositeAdequacy.OPFMethod, optimizer)
N = 8760                                                    #timestep_count
L = 1                                                       #timestep_length
T = timeunits["h"]                                          #timestep_unit
P = powerunits["kW"]
E = energyunits["MWh"]
V = voltageunits["kV"]
p2e = conversionfactor(L,T,P,E)

"********************************************************************************************************************************"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
data = PowerModels.parse_file(RawFile)
#network_data["branch"][string(7)]["br_status"] = 0
#network_data["branch"][string(23)]["br_status"] = 0
#network_data["branch"][string(29)]["br_status"] = 0
#PRATSBase.SimplifyNetwork!(network_data)

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
[j for j in eachindex(network_data["branch"]) if any(abs.(native["solution"]["branch"][string(j)]["pf"]).>network_data["branch"][j]["rate_a"])]
[native["solution"]["branch"][string(j)]["pf"] for j in eachindex(native["solution"]["branch"])]
"********************************************************************************************************************************"
mn_data =  PowerModels.replicate(data, 5)
PowerModels.simplify_network!(mn_data)
result = PowerModels.solve_mn_opf(mn_data, OPFMethod, nlp_solver)
PowerModels.nws(pm)
using Profile
using ProfileView
Profile.clear()
@profile (for i=1:10; PRATS.assess(system, method, resultspecs...); end)
Profile.print()
ProfileView.view()
[j for j in eachindex(1:1) if any(abs.(system.branches.pf[:,j]).>system.branches.longterm_rating[:,j])]
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
method = PRATS.SequentialMonteCarlo(samples=1, seed=2, verbose=false, threaded=true)
@time shortfall,shortfall2 = PRATS.assess(system, method, resultspecs...)

PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
"********************************************************************************************************************************"

#RESUTLS 365HRS
#with HiGHS, 28.511125 seconds (87.66 M allocations: 4.709 GiB, 5.10% gc time, 73.53% compilation time)
#26.512612 seconds (87.45 M allocations: 4.704 GiB, 4.98% gc time, 74.17% compilation time)
#26.224381 seconds (87.19 M allocations: 4.696 GiB, 5.45% gc time, 75.24% compilation time)
#28.679955 seconds (93.11 M allocations: 5.295 GiB, 5.35% gc time, 76.52% compilation time)
#26.339830 seconds (87.15 M allocations: 4.694 GiB, 5.44% gc time, 75.46% compilation time)
#23.912965 seconds (78.67 M allocations: 4.237 GiB, 5.36% gc time, 73.61% compilation time)
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
using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime

RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 2160)

nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
minlp_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"time_limit"=>1.0, "log_levels"=>[])
#minlp_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "time_limit"=>1.5, "log_levels"=>[])
optimizer = [nl_solver, mip_solver, minlp_solver]

threads = Base.Threads.nthreads()
sampleseeds = Channel{Int}(2)
simspec = CompositeAdequacy.SequentialMonteCarlo(samples=1, seed=2)
resultspecs = (Shortfall(), Shortfall())
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)
systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
recorders = CompositeAdequacy.accumulator.(system, simspec, resultspecs)

dictionary = Dict{Symbol,Any}()
CompositeAdequacy.fill_dictionary!(system, dictionary)
pm = CompositeAdequacy.InitializeAbstractPowerModel(dictionary, CompositeAdequacy.AbstractDCPModel, optimizer)
pm.model = JuMP.Model(optimizer[1])
s=1
CompositeAdequacy.seed!(rng, (simspec.seed, s))
CompositeAdequacy.initialize!(rng, systemstate, system)

t = 1
CompositeAdequacy.update_ref!(systemstate, system, pm.ref, t, systemstate.condition[t])
CompositeAdequacy.update_pm!(pm, CompositeAdequacy.LMOPFMethod, optimizer)
#CompositeAdequacy.build_model!(pm, CompositeAdequacy.LMOPFMethod)
#CompositeAdequacy.optimization!(pm)

CompositeAdequacy.var_bus_voltage(pm)
CompositeAdequacy.var_gen_power(pm)
CompositeAdequacy.var_branch_power(pm)
CompositeAdequacy.var_dcline_power(pm)
CompositeAdequacy.var_load_curtailment(pm)
pm.model
bus_loads = Dict{Int, Any}()
bus_shunts = Dict{Int, Any}()

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

@time f()
"hello"

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



@btime for i in keys(pm.ref[:bus])
    # Build a list of the loads and shunt elements connected to the bus i
    bus_loads = [pm.ref[:load][l] for l in pm.ref[:bus_loads][i]]
    bus_shunts = [pm.ref[:shunt][s] for s in pm.ref[:bus_shunts][i]]
    
    JuMP.@constraint(pm.model,
    sum(pm.model[:p][a] for a in pm.ref[:bus_arcs][i]) +
    sum(pm.model[:p_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
    sum(pm.model[:pg][g] for g in pm.ref[:bus_gens][i]) -                 # sum of active power generation at bus i -
    sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
    sum(shunt["gs"] for shunt in bus_shunts)*1.0^2          # sum of active shunt element injections at bus i
    )
end


list_of_constraint_types(pm.model)
all_constraints(pm.model, AffExpr, MOI.EqualTo{Float64})

JuMP.delete(pm.model, all_constraints(pm.model, AffExpr, MOI.EqualTo{Float64}))
JuMP.delete(pm.model, all_constraints(pm.model, AffExpr, MOI.GreaterThan{Float64}))
JuMP.delete(pm.model, all_constraints(pm.model, AffExpr, MOI.LessThan{Float64}))
pm.model





"hello"
JuMP.solution_summary(pm.model, verbose=false)
CompositeAdequacy.build_result!(pm)    

#CompositeAdequacy.solve!(pm, systemstate, system, optimizer, t, systemstate.condition[t])


sum([system.generators.pg[i,t] for i in eachindex(system.generators.keys)])
sum([system.loads.pd[i,t] for i in eachindex(system.loads.keys)])

pm.termination_status
systemstate.condition[t]




#CompositeAdequacy.foreach(recorder -> CompositeAdequacy.record!(recorder, pm, system, s, t), recorders)


[j for j in eachindex(data["branch"]) if any(data["branch"]["1"]["br_status"] .!= 1)]
[j for j in eachindex(data["branch"]) if any(abs.(native["branch"][string(j)]["pf"]).>data["branch"][j]["rate_a"])]

pm = CompositeAdequacy.InitializeAbstractPowerModel(data, CompositeAdequacy.LMOPFMethod, optimizer)

pm.solution["solution"]["load_curtailment"]


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
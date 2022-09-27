using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 2160)
resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMonteCarlo(samples=8, seed=123, verbose=false, threaded=true)

nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"time_limit"=>1.0, "log_levels"=>[])
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "branch_strategy"=>:PseudoCost ,"time_limit"=>1.5, "log_levels"=>[])
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "log_levels"=>[])
JuMP.num_variables(pm.model)
network_data = PowerModels.parse_file(RawFile)
@time shortfall,shortfall2 = PRATS.assess(system, method, optimizer, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)

using PackageCompiler, Libdl
PackageCompiler.create_sysimage(["JuMP", "Juniper", "Ipopt"], sysimage_path = "customimage." * Libdl.dlext, precompile_execution_file = "CompositeAdequacy.jl",)



"********************************************************************************************************************************"

nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_iter"=>2000, "max_cpu_time"=>1e+1,"constr_viol_tol"=>0.001, "acceptable_tol"=>0.01, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"atol"=>1e-3, "branch_strategy"=>:PseudoCost ,"time_limit"=>1.5, "log_levels"=>[])
systemstate = CompositeAdequacy.SystemState(system)
dictionary = Dict{Symbol,Any}()
pm = CompositeAdequacy.InitializeAbstractPowerModel(system.network, dictionary, CompositeAdequacy.AbstractDCPModel, optimizer)
t=162
CompositeAdequacy.empty_pm!(pm, system.network, dictionary)
pm.type = CompositeAdequacy.LMDCOPF
systemstate.condition[t]
#CompositeAdequacy.update_ref!(systemstate, system, pm.ref, t, systemstate.condition[t])
CompositeAdequacy.update_gen!(system.generators, dictionary, systemstate.gens_available, t, CompositeAdequacy.Failed)
CompositeAdequacy.update_stor!(system.storages, dictionary, systemstate.stors_available, t)
CompositeAdequacy.update_load!(system.loads, dictionary, t)
CompositeAdequacy.update_branches!(system.branches, dictionary, systemstate.branches_available, t)
PRATSBase.SimplifyNetwork!(dictionary)

CompositeAdequacy.build_model!(pm, pm.type)
CompositeAdequacy.optimization!(pm, pm.type)
CompositeAdequacy.build_result!(pm, system.network.load)

JuMP.termination_status(pm.model)
JuMP.solution_summary(pm.model, verbose=true)



refs[:load][1]["status"] = 0
refs[:load][2]["status"] = 0
incident_load2 = PRATSBase.bus_load_lookup(refs[:load], refs[:bus])
incident_load2[1]

incident_active_load = Dict()
for (i, load_list) in incident_load2
    incident_active_load[i] = [load for load in load_list if load["status"] ≠ 0]
end

incident_active_load

"********************************************************************************************************************************"

@time shortfall,shortfall2 = PRATS.assess(system, method, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)



"********************************************************************************************************************************"
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, 
"tol"=>1e-3, "acceptable_tol"=>1e-2, "max_iter"=>2000, "max_cpu_time"=>1e+1,"constr_viol_tol"=>0.001, "acceptable_tol"=>0.01, "print_level"=>0
)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"time_limit"=>1.0, "log_levels"=>[])
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "time_limit"=>2, "log_levels"=>[])
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver,
"atol"=>1e-3, "branch_strategy"=>:PseudoCost ,"time_limit"=>1.5, "log_levels"=>[])
threads = Base.Threads.nthreads()
sampleseeds = CompositeAdequacy.Channel{Int}(2*threads)
systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.seed!(rng, (method.seed, 1))
CompositeAdequacy.initialize!(rng, systemstate, system)
dictionary = Dict{Symbol,Any}()
pm = CompositeAdequacy.InitializeAbstractPowerModel(system.network, dictionary, CompositeAdequacy.AbstractDCPModel, optimizer)
iter = CompositeAdequacy.initialize!(rng, systemstate, system) #creates the up/down sequence for each device.
@time for (_,t) in enumerate(iter)
    #println("t=$(iter[i])")
    CompositeAdequacy.solve!(pm, systemstate, system, t, systemstate.condition[t])
    #CompositeAdequacy.foreach(recorder -> record!(recorder, pm.load_curtailment, system.loads, s, t), recorders)
    CompositeAdequacy.empty_pm!(pm, system.network, dictionary)
end



dictionary = Dict{Symbol,Any}()
pm = CompositeAdequacy.InitializeAbstractPowerModel(system.network, dictionary, CompositeAdequacy.AbstractDCPModel, optimizer)
data = deepcopy(dictionary)
data[:branch][7]["br_status"] = 0
data[:branch][23]["br_status"] = 0
data[:branch][29]["br_status"] = 0
PRATSBase.SimplifyNetwork!(data)
CompositeAdequacy.ref_add!(data)
pm.ref = deepcopy(data)
pm.type = CompositeAdequacy.LMDCOPF
@btime CompositeAdequacy.build_model!(deepcopy(pm), CompositeAdequacy.LMDCOPF)
CompositeAdequacy.build_model!(pm, CompositeAdequacy.LMDCOPF)
@btime CompositeAdequacy.optimization!(deepcopy(pm))
CompositeAdequacy.build_result!(pm, CompositeAdequacy.LMDCOPF)

# @allocated p_expr = JuMP.@expression(pm.model, merge(Dict([((l,i,j), 1.0*pm.model[:p][(l,i,j)]) 
# for (l,i,j) in pm.ref[:arcs_from]]), Dict([((l,j,i), -1.0*pm.model[:p][(l,i,j)]) for (l,i,j) in pm.ref[:arcs_from]]))
# ) #7,939,904
p_expr = JuMP.@expression(pm.model, Dict([((l,i,j), 1.0*pm.model[:p][(l,i,j)]) for (l,i,j) in pm.ref[:arcs_from]]))

#unregister(pm.model, :p)
CompositeAdequacy.var_branch_power(pm)
#delete(pm.model, pm.model[:p].data)
empty!(pm.model)
set_string_names_on_creation(pm.model, false)
pm.model


JuMP.solution_summary(pm.model, verbose=true)
println(pm.model)

CompositeAdequacy.build_model!(pm, CompositeAdequacy.LMDCOPF)
JuMP.optimize!(pm.model)
#JuMP.solution_summary(pm.model, verbose=false)

#using ContingencySolver
#ContingencySolver.build_opf_lc(ref, ContingencySolver.dc_opf_lc, JuMP.Model(optimizer; add_bridges = false))
JuMP.termination_status(pm.model)
JuMP.solution_summary(pm.model, verbose=false)


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
#@time pm = CompositeAdequacy.SolveModel(network_data,CompositeAdequacy.DCOPF, optimizer)
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

balance = PowerModels.calc_power_balance(network_data)
balance["bus"]
[j for j in eachindex(network_data["branch"]) if any(abs.(flow["branch"][string(j)]["pf"]).>network_data["branch"][j]["rate_a"])]
[j for j in eachindex(network_data["branch"]) if any(abs.(native["solution"]["branch"][string(j)]["pf"]).>network_data["branch"][j]["rate_a"])]
[native["solution"]["branch"][string(j)]["pf"] for j in eachindex(native["solution"]["branch"])]
"********************************************************************************************************************************"

function s()
    RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
    data = PowerModels.parse_file(RawFile)
    mn_data =  PowerModels.replicate(data, 8760)
    PowerModels.simplify_network!(mn_data)
    return result = PowerModels.solve_mn_opf(mn_data, DCPPowerModel, optimizer)
end

@btime s()

PowerModels.nws(pm)
using Profile
using ProfileView
Profile.clear()
@profile (for i=1:10; PRATS.assess(system, method, resultspecs...); end)
Profile.print()
ProfileView.view()
[j for j in eachindex(1:1) if any(abs.(system.branches.pf[:,j]).>system.branches.longterm_rating[:,j])]
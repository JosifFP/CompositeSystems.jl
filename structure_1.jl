using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
using Test
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 8760)
resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMonteCarlo(samples=100, seed=123, verbose=false, threaded=true)
@time shortfall,report = PRATS.assess(system, method, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)










"***************************************************************************************************************************"
topology = CompositeAdequacy.Topology(system)
pm = CompositeAdequacy.PowerFlowProblem(CompositeAdequacy.AbstractDCPowerModel, JuMP.direct_model(optimizer), CompositeAdequacy.Topology(system))
systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.initialize!(rng, systemstate, system)

@show systemstate.condition

t=7958
CompositeAdequacy.field(systemstate, :condition)[t]


CompositeAdequacy.update!(pm.topology, systemstate, system, t)
CompositeAdequacy.solve!(pm, systemstate, system, t)
CompositeAdequacy.empty_model!(pm)
CompositeAdequacy.var_bus_voltage(pm, system, t)
CompositeAdequacy.var_gen_power(pm, system, t)
CompositeAdequacy.var_branch_power(pm, system, t)
CompositeAdequacy.var_load_curtailment(pm, system, t)

@btime for i in CompositeAdequacy.assetgrouplist(CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :buses_idxs))
    CompositeAdequacy.constraint_power_balance(pm, system, i, t)
end

#39.500 μs (1034 allocations: 79.88 KiB)
#36.900 μs (937 allocations: 74.78 KiB)

expr = :(
    $(sum(p[a] for a in bus_arcs; init=0)) 
    - $(sum(pg[g] for g in bus_gens; init=0)) 
    - $(sum(plc[m] for m in bus_loads; init=0)) 
    + $(sum(pd for pd in bus_pd; init=0)) 
    + $(sum(gs for gs in bus_gs; init=0)*1.0^2)
)



bus_loads = CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :bus_loads)[i]
bus_shunts = CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :bus_shunts)[i]

i=1
sum_p = :($(sum(p[a] for a in CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :bus_arcs)[i]; init=0)))
@btime sum_pg = :($(sum(pg[g] for g in CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :bus_generators)[i]; init=0)))
@btime sum_plc = :($(sum(plc[m] for m in bus_loads; init=0)))
@btime sum_pd = :($(sum(pd for pd in Float16.([CompositeAdequacy.field(system, Loads, :pd)[k,t] for k in bus_loads]); init=0)))
@btime sum_gs = :($(sum(gs for pd in Float16.([CompositeAdequacy.field(system, Shunts, :gs)[k] for k in bus_shunts]); init=0)))

expr = :(
    $(sum(p[a] for a in CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :bus_arcs)[i]; init=0))
    -$(sum(pg[g] for g in CompositeAdequacy.field(pm, CompositeAdequacy.Topology, :bus_generators)[i]; init=0))
    -$(sum(plc[m] for m in bus_loads; init=0))
    +$(sum(pd for pd in Float16.([CompositeAdequacy.field(system, Loads, :pd)[k,t] for k in bus_loads]); init=0))
    +$(sum(gs for pd in Float16.([CompositeAdequacy.field(system, Shunts, :gs)[k] for k in bus_shunts]); init=0))
)


JuMP.@constraint(pm.model, sum_p + ==0)

ref = PRATSBase.BuildNetwork(RawFile)
for (k,v) in ref[:load]
    CompositeAdequacy.field(system, Loads, :pd)[k,1] = v["pd"]
end

CompositeAdequacy.field(systemstate, :branches)[29,t] = 0
CompositeAdequacy.field(systemstate, :branches)[36,t] = 0
CompositeAdequacy.field(systemstate, :branches)[37,t] = 0

CompositeAdequacy.update!(pm.topology, systemstate, system, t)
type = CompositeAdequacy.DCOPF
#type = CompositeAdequacy.Transportation
CompositeAdequacy.build_method!(pm, system, t, type)
JuMP.optimize!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
JuMP.termination_status(pm.model)
println(JuMP.solution_summary(pm.model, verbose=true))





ref = PRATSBase.BuildNetwork(RawFile)
CompositeAdequacy.ref_add!(ref)



model = JuMP.direct_model(optimizer)
@time shortfall,report = PRATS.assess(system, method, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)


shortfall.nsamples
shortfall.loads
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



ref = PRATSBase.BuildNetwork(RawFile)
for (k,v) in ref[:load]
    CompositeAdequacy.field(system, Loads, :pd)[k,1] = v["pd"]
end
t=2
CompositeAdequacy.field(system, Branches, :status)[25] = 0
CompositeAdequacy.field(system, Branches, :status)[26] = 0
CompositeAdequacy.field(system, Branches, :status)[28] = 0
CompositeAdequacy.update!(system)

@show CompositeAdequacy.field(system, Branches, :status)

CompositeAdequacy.build_method!(pm, system, t, CompositeAdequacy.DCOPF)
JuMP.optimize!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
CompositeAdequacy.RestartAbstractPowerModel!(pm)
CompositeAdequacy.field(system, Branches, :status)[25] = 1
CompositeAdequacy.field(system, Branches, :status)[26] = 1
CompositeAdequacy.field(system, Branches, :status)[28] = 1

#JuMP.solution_summary(pm.model, verbose=true)


"***************************************************************************************************************************"
[filter(t -> t[1] in starts[i] && t[2] in valid[i], my_tuple) for i in eachindex(starts, valid)]
include("solvers.jl")
include("TestSystems.jl")
using PRATS
import PRATS.PRATSBase
import PRATS.CompositeAdequacy: CompositeAdequacy, field, var, topology, makeidxlist, sol,
    assetgrouplist, findfirstunique, build_sol_values
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
PRATSBase.silence()
system = TestSystems.RBTS

resultspecs = (Shortfall(), Shortfall())
settings = PRATS.Settings(
    juniper_optimizer_2, "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS2.m",  
    modelmode = JuMP.AUTOMATIC, powermodel="AbstractDCPModel"
)

method = PRATS.SequentialMCS(samples=20, seed=555, threaded=false)
@time shortfall,report = PRATS.assess(system, method, settings, resultspecs...)
PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)

rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.seed!(rng, (666, 1))
cache = CompositeAdequacy.Cache(system, method, multiperiod=false)
pm = CompositeAdequacy.PowerFlowProblem(system, field(settings, :powermodel), method, cache, settings)
systemstates = CompositeAdequacy.SystemStates(system, method)
@code_warntype CompositeAdequacy.initialize!(rng, systemstates, system, settings)


@show systemstates.buses


t=1
field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
field(systemstates, :branches)[3,t] = 0
field(systemstates, :branches)[4,t] = 0
field(systemstates, :branches)[8,t] = 0
systemstates.system[t] = 0

systemstates.buses[:,t], 
systemstates.branches[:,t], 
systemstates.loads[:,t] = CompositeAdequacy.update_bus_types!(systemstates, system.branches, settings, t)

CompositeAdequacy.update!(pm, systemstates, system, t)
CompositeAdequacy.solve!(pm, system, t)
JuMP.termination_status(pm.model)
pg = sum(values(build_sol_values(var(pm, :pg, 0))))
sum(values(sol(pm, :plc)[:,t]))
pg = sum(values(build_sol_values(var(pm, :plc, 0))))
JuMP.solution_summary(pm.model, verbose=false)
JuMP.objective_value(pm.model)


sol(pm, :plc)




CompositeAdequacy.calc_connected_components(pm, system.branches)
network = Dict{Symbol, Any}(PRATSBase.BuildNetwork(RawFile))
CompositeAdequacy.select_largest_component!(pm, system.branches, system.buses, network)
systemstates.buses
PowerModels.select_largest_component!(pm_data)

RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS.m"
pm_data = PowerModels.parse_file(RawFile)
pm_data["branch"]["3"]["br_status"] = 0
pm_data["branch"]["4"]["br_status"] = 0
pm_data["branch"]["8"]["br_status"] = 0

PowerModels.calc_connected_components(pm_data)
PowerModels.select_largest_component!(pm_data)




goutages = filter(i->field(states, :generators, i, t)==false, field(system, :generators, :keys))
#if goutages > 3

rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.seed!(rng, (666, 1))
cache = CompositeAdequacy.Cache(system, method, multiperiod=false)
pm = CompositeAdequacy.PowerFlowProblem(system, field(settings, :powermodel), method, cache, settings)
systemstates = CompositeAdequacy.SystemStates(system, method)
#CompositeAdequacy.initialize!(rng, systemstates, system)

t=1
field(system, :loads, :pd)[:,t] = [0.20; 0.85; 0.40; 0.20; 0.20]
CompositeAdequacy.update!(pm, systemstates, system, t)

@btime CompositeAdequacy.var_gen_power(pm, system, nw=0)
#3.275 μs (100 allocations: 5.28 KiB)
@btime CompositeAdequacy.var_gen_power(pm, system, nw=0)
#3.175 μs (99 allocations: 5.14 KiB)


CompositeAdequacy.build_opf!(pm, system, t)
pm.model
println(pm.model)
CompositeAdequacy.optimize!(pm.model)
JuMP.termination_status(pm.model)
nw=0
pg = sum(values(build_sol_values(var(pm, :pg, nw))))
JuMP.solution_summary(pm.model, verbose=false)
JuMP.objective_value(pm.model)
CompositeAdequacy.empty_method!(pm, cache)

RawFile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/RBTS.m"
PowerModels.solve_dc_opf(RawFile, ipopt_optimizer_3)
pm_result=PowerModels.solve_dc_opf(RawFile, ipopt_optimizer_3)
pm_sol = pm_result["solution"]
@show pm_sol["gen"]
@show build_sol_values(var(pm, :pg, nw))



data = PowerModels.parse_file(RawFile)
pms = PowerModels.instantiate_model(data, PowerModels.DCPPowerModel, PowerModels.build_opf)
pms.model
println(pms.model)

















for t in 1:8736
    cap = getindex(system.generators.pmax, filter(i->field(systemstates, :generators, i, t)==1, field(system.generators, :keys)))
    load = getindex(system.loads.pd[:,t], filter(i->field(systemstates, :loads, i, t)==1, field(system.loads, :keys)))
    if sum(cap) <= sum(load)
        println(i)
    end
end

t=100
sum(field(systemstates, :generators)[5,:])
cap = getindex(system.generators.pmax, filter(i->field(systemstates, :generators, i, t)==1, field(system.generators, :keys)))
load = getindex(system.loads.pd[:,t], filter(i->field(systemstates, :loads, i, t)==1, field(system.loads, :keys)))

a = hcat(field(systemstates, :generators, :, t), field(system.generators, :pmax))

collect()


a[:,1]
filter(i -> Bool.(a[:,1])[i]==1,a)

Int.(a[:,1])
field(systemstates, :generators)[Int.(a[:,1]),t]

filter(a[i,1] -> field(systemstates, :generators)[Int.(a[i,1]),t]==1, a)

@btime filter(i->getindex(field(systemstates, :generators),i, t), field(system, :generators, :keys))
@btime filter(i->getindex(systemstates.generators,i, t), field(system, :generators, :keys))
@btime filter(i->field(systemstates, :generators)[i,t], field(system, :generators, :keys))
@btime filter(i->field(systemstates, :generators, i, t), field(system, :generators, :keys))

@btime field(systemstates, :generators, :, 1)

view(field(systemstates, :generators),:,1)
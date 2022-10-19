using PRATS
import PRATS.PRATSBase
import PRATS.CompositeAdequacy: CompositeAdequacy, field, var, check_status,
VariableType, assetgrouplist, update_asset_idxs!, S, Status, findfirstunique, SUCCESSFUL, FAILED
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP,HiGHS
using Test
using ProfileView, Profile
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RBTS.m"
PRATSBase.silence()
#InputData = ["Loads", "Generators", "Branches"]
#PRATSBase.FileGenerator(RawFile, InputData)

system = PRATSBase.SystemModel(RawFile; ReliabilityDataDir=ReliabilityDataDir, N=8736)
#topology = Topology(system)
resultspecs = (Shortfall(), Shortfall())
settings = CompositeAdequacy.Settings()
method = PRATS.SequentialMCS(samples=1, seed=321, threaded=false)
@time shortfall,report = PRATS.assess(system, method, resultspecs...)

PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)


systemstates = SystemStates(system, method)

view(pm.topology.bus_loads_idxs)
view(getfield(states, field), :, t)



systemstates = SystemStates(system, method)
topology = CompositeAdequacy.Topology(system)
pm = CompositeAdequacy.PowerFlowProblem(system, method, field(method, :settings), topology)
rng = CompositeAdequacy.Philox4x((0, 0), 10)  #DON'T MOVE THIS LINE
@btime CompositeAdequacy.initialize!(rng, systemstates, system)

sum(systemstates.system)

t=1
field(systemstates, :branches)[5,t] = 0
field(systemstates, :branches)[8,t] = 0
field(systemstates, :system)[t] = 1
@btime CompositeAdequacy.update!(pm.topology, systemstates, system, t)
#7.425 μs (253 allocations: 22.11 KiB)


CompositeAdequacy.build_method!(pm, system, t)
CompositeAdequacy.optimize!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
pm.topology.plc


t=2
field(systemstates, :branches)[5,t] = 0
field(systemstates, :branches)[8,t] = 0
field(systemstates, :system)[t] = 0
CompositeAdequacy.update!(pm.topology, systemstates, system, t)
CompositeAdequacy.build_method!(pm, system, t)
CompositeAdequacy.optimize!(pm.model)
CompositeAdequacy.build_result!(pm, system, t)
pm.topology.plc
pm.var.va







#systemstates = SystemStates(system, method)
#rng = CompositeAdequacy.Philox4x((0, 0), 10)
#CompositeAdequacy.initialize!(rng, systemstates, system)

nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
optimizer = optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])

RawFile = "test/data/RBTS.m"
system = PRATSBase.SystemModel(RawFile)
field(system, CompositeAdequacy.Loads, :cost)[:] = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
method = PRATS.SequentialMCS(samples=1, seed=1, threaded=false)
topology = CompositeAdequacy.Topology(system)
pm = CompositeAdequacy.PowerFlowProblem(method, field(method, :settings), topology, 1)
t=1
systemstates = CompositeAdequacy.SystemStates(system, CompositeAdequacy.Tests)
field(systemstates, :branches)[5,t] = 0
field(systemstates, :branches)[8,t] = 0
field(systemstates, :system)[t] = 0
CompositeAdequacy.update!(pm.topology, systemstates, system, t)
CompositeAdequacy.var_bus_voltage(pm, system, t=1)
CompositeAdequacy.var_gen_power(pm, system, t=1)












Profile.clear()
@profile shortfall,report = PRATS.assess(system, method, resultspecs...)
@pprof shortfall,report = PRATS.assess(system, method, resultspecs...)
Profile.print()
ProfileView.view()


VariableType


PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
PRATS.LOLE.(shortfall)
PRATS.EUE.(shortfall)
shortfall.shortfall_bus_std

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
@show shortfall.shortfall_mean
shortfall.shortfall_std
shortfall.shortfall_bus_std
@show shortfall.shortfall_period_std
@show shortfall.shortfall_busperiod_std



nbuses = length(system.buses)

key_buses = [i for i in CompositeAdequacy.field(system, Buses, :keys) if CompositeAdequacy.field(system, Buses, :bus_type)[i] != 4]
buses_idxs = makeidxlist(key_buses, nbuses)

key_loads = [i for i in field(system, Loads, :keys) if field(system, Loads, :status)[i] == 1]
#bus_loads = [field(system, Loads, :buses)[i] for i in key_loads] #bus_loads_idxs = makeidxlist(bus_loads, nbuses)
loads_idxs = makeidxlist(key_loads, length(system.loads))


using Dictionaries
tmp = Dict((i, Int[1]) for i in key_buses)

@btime tmp2 = Dictionary((i, Int[]) for i in key_buses)



Base.map(x -> [], values(tmp))

for v=values(tmp) v=[] end
tmp
@btime for v=values(tmp) empty!(v) end
tmp = Dict((i, Int[]) for i in key_buses)




all(CompositeAdequacy.field(system, Loads, :status))
import BenchmarkTools: @btime




@btime Status(S{true})
Status(S{false})


CompositeAdequacy.field(system, Loads, :status)
@btime all(CompositeAdequacy.field(system, Loads, :status))
@btime Status(S{all(CompositeAdequacy.field(system, Loads, :status))})

variables::Dict{VariableKey, AbstractArray}


function has_container_key(
    container::OptimizationContainer,
    ::Type{T},
    ::Type{U},
    meta=CONTAINER_KEY_EMPTY_META,
) where {T <: VariableType, U <: Union{PSY.Component, PSY.System}}
    key = VariableKey(T, U, meta)
    return haskey(container.variables, key)
end

struct VariableKey{T <: VariableType, U <: Union{PSY.Component, PSY.System}} <: OptimizationContainerKey
 meta::String
end

function VariableKey(
    ::Type{T},
    meta::String=CONTAINER_KEY_EMPTY_META,
) where {T <: VariableType}
    return VariableKey(T, PSY.Component, meta)
end

function VariableKey(
    ::Type{T},
    ::Type{U},
    meta=CONTAINER_KEY_EMPTY_META,
) where {T <: VariableType, U <: Union{PSY.Component, PSY.System}}
    if isabstracttype(U)
        error("Type $U can't be abstract")
    end
    check_meta_chars(meta)
    return VariableKey{T, U}(meta)
end
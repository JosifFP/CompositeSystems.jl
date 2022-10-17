using PRATS
import PRATS.PRATSBase
import PRATS.CompositeAdequacy
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

systemstates = SystemStates(system, method)

resultspecs = (Shortfall(), Shortfall())
method = PRATS.SequentialMCS(samples=1, seed=1, verbose=false, threaded=false)
@time shortfall,report = PRATS.assess(system, method, resultspecs...)


@time pm = CompositeAdequacy.PowerFlowProblem(
    CompositeAdequacy.AbstractDCOPF, JuMP.Model(method.optimizer; add_bridges = false), CompositeAdequacy.Topology(system)
)

@btime systemstates = CompositeAdequacy.SystemStates(system)
#10.300 μs (15 allocations: 316.48 KiB)


struct S{Bool} end
struct FAILED <: S end
struct SUCCESSFUL <: S end
Status(::Type{S{false}}) = FAILED
Status(::Type{S{true}}) = SUCCESSFUL



tmp = Array{Bool, 2}(undef, 6, 8736)
        
@btime for t in 1:8736
    for r in 1:6
        if anys(CompositeAdequacy.Available(systemstates, t)[r]) 
            tmp[r,t] = true
        else 
            tmp[r,t] = false
        end
    end
end

tmp


function anys(B::Vector{Bool})
    @inbounds begin
        for i in eachindex(B)
            B[i] == 1 || return false
        end
    end
    return true
end

function foo()
    fill!(Matrix{Bool}(undef, 6, 8736), 1)
end

@btime foo()

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

CompositeAdequacy.field(system, Loads, :status)

BitVector()

systemstates.loads
BitArray(undef, 5, 8760)

struct statx
    a::Matrix{Bool}
    function statx(N::Int)
        a = ones(Bool, 2, N)
        return new(a)
    end
end

ones(Bool, length(system.loads))

abstract type VariableType end
abstract type ConstraintType end
abstract type ExpressionType end
abstract type AuxVariableType end
abstract type ParameterType end
abstract type InitialConditionType end

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
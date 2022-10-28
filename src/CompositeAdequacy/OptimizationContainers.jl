"""
Topology Container: a OptimizationContainer for some duplicated data input from SystemModel structure 
but stored in lightweight vectors that can be mutated and filtered out when a topology change is detected.
"""
struct Topology <: OptimizationContainer

    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    branches_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    generatorstorages_idxs::Vector{UnitRange{Int}}
    loads_nodes::Dict{Int, Vector{Int}}
    shunts_nodes::Dict{Int, Vector{Int}}
    generators_nodes::Dict{Int, Vector{Int}}
    storages_nodes::Dict{Int, Vector{Int}}
    generatorstorages_nodes::Dict{Int, Vector{Int}}
    arcs::Arcs


    function Topology(system::SystemModel{N}) where {N}

        key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))
        buses_idxs = makeidxlist(key_buses, length(system.buses))

        #nodes = Dict((i, Int[]) for i in key_buses)
        key_loads = filter(i->field(system, :loads, :status)[i], field(system, :loads, :keys))
        loads_idxs = makeidxlist(key_loads, length(system.loads))
        tmp = Dict((i, Int[]) for i in key_buses)
        loads_nodes = bus_asset!(tmp, key_loads, field(system, :loads, :buses))

        key_shunts = filter(i->field(system, :shunts, :status)[i], field(system, :shunts, :keys))
        shunts_idxs = makeidxlist(key_shunts, length(system.shunts))
        tmp = Dict((i, Int[]) for i in key_buses)
        shunts_nodes = bus_asset!(tmp, key_shunts, field(system, :shunts, :buses))

        key_generators = filter(i->field(system, :generators, :status)[i], field(system, :generators, :keys))
        generators_idxs = makeidxlist(key_generators, length(system.generators))
        tmp = Dict((i, Int[]) for i in key_buses)
        generators_nodes = bus_asset!(tmp, key_generators, field(system, :generators, :buses))

        key_storages = filter(i->field(system, :storages, :status)[i], field(system, :storages, :keys))
        storages_idxs = makeidxlist(key_storages, length(system.storages))
        tmp = Dict((i, Int[]) for i in key_buses)
        storages_nodes = bus_asset!(tmp, key_storages, field(system, :storages, :buses))

        key_generatorstorages = filter(i->field(system, :generatorstorages, :status)[i], field(system, :generatorstorages, :keys))
        generatorstorages_idxs = makeidxlist(key_generatorstorages, length(system.generatorstorages))
        tmp = Dict((i, Int[]) for i in key_buses)
        generatorstorages_nodes = bus_asset!(tmp, key_generatorstorages, field(system, :generatorstorages, :buses))

        key_branches = filter(i->field(system, :branches, :status)[i], field(system, :branches, :keys))
        branches_idxs = makeidxlist(key_branches, length(system.branches))

        arcs = deepcopy(field(system, :arcs))

        return new(
            buses_idxs::Vector{UnitRange{Int}}, loads_idxs::Vector{UnitRange{Int}}, 
            branches_idxs::Vector{UnitRange{Int}}, shunts_idxs::Vector{UnitRange{Int}}, 
            generators_idxs::Vector{UnitRange{Int}}, storages_idxs::Vector{UnitRange{Int}}, 
            generatorstorages_idxs::Vector{UnitRange{Int}}, loads_nodes, shunts_nodes, 
            generators_nodes, storages_nodes, generatorstorages_nodes, arcs)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.generatorstorages_idxs == y.generatorstorages_idxs &&
    x.nodes == y.nodes &&
    x.loads_nodes == y.loads_nodes &&
    x.shunts_nodes == y.shunts_nodes &&
    x.generators_nodes == y.generators_nodes &&
    x.storages_nodes == y.storages_nodes &&
    x.generatorstorages_nodes == y.generatorstorages_nodes &&
    x.arcs == y.arcs &&
    x.plc == y.plc
#

"""
Variables: A mutable OptimizationContainer for AbstractACPowerModel variables that are mutated by JuMP.
An alternate solution could be specifying a contaner within JuMP macros (container=Array, DenseAxisArray, Dict, etc.).
However, the latter generates more allocations and slow down simulations.
Argument "timeseries" allows to store variables for longer periods of time, thus, optimize multiperiod formulations.
"""
mutable struct Variables <: OptimizationContainer
    va::DenseAxisArray{DenseAxisArray}
    vm::DenseAxisArray{DenseAxisArray}
    pg::DenseAxisArray{DenseAxisArray}
    qg::DenseAxisArray{DenseAxisArray}
    plc::DenseAxisArray{DenseAxisArray}
    qlc::DenseAxisArray{DenseAxisArray}
    p::DenseAxisArray{Dict}
    q::DenseAxisArray{Dict}

    function Variables(system::SystemModel{N}; timeseries::Bool=false) where {N}
        va = VarContainerArray(field(system, :buses, :keys), N; timeseries=timeseries)
        vm = VarContainerArray(field(system, :buses, :keys), N; timeseries=timeseries)
        pg = VarContainerArray(field(system, :generators, :keys), N; timeseries=timeseries)
        qg = VarContainerArray(field(system, :generators, :keys), N; timeseries=timeseries)
        plc = VarContainerArray(field(system, :loads, :keys), N; timeseries=timeseries)
        qlc = VarContainerArray(field(system, :loads, :keys), N; timeseries=timeseries)
        p = VarContainerDict(field(system, :arcs), N; timeseries=timeseries)
        q = VarContainerDict(field(system, :arcs), N; timeseries=timeseries)
        return new(va, vm, pg, qg, plc, qlc, p, q)
    end
end

""
function VarContainerArray(vkeys::Vector{Int}, N::Int; timeseries::Bool=false)
    if timeseries
        conts = DenseAxisArray{DenseAxisArray}(undef, [i for i in 1:N]) #Initiate empty 2-D DenseAxisArray container
        s_container = container_spec(VariableRef, vkeys)
        varcont = fill!(conts, s_container)
    else
        s_container = container_spec(VariableRef, vkeys)
        varcont = fill!(DenseAxisArray{DenseAxisArray}(undef, [0]), s_container)
    end
    return varcont
end

""
function VarContainerDict(container::Arcs, N::Int; timeseries::Bool=false)

    if timeseries
        conts = DenseAxisArray{Dict}(undef, [i for i in 1:N]) #Initiate empty 2-D DenseAxisArray container
        s_container = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in container.arcs)
        varcont = fill!(conts, s_container)
    else
        s_container = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in container.arcs)
        varcont = fill!(DenseAxisArray{Dict}(undef, [0]), s_container)
    end
    return varcont
end

"""
Returns the container specification for the selected type of JuMP Model
"""
function container_spec(::Type{T}, axs...) where {T <: Any}
    return DenseAxisArray{T}(undef, axs...)
end


"""
Solution: a OptimizationContainer structure that stores results in mutable containers.
Optionally, it can store data for one (as a vector) or more (matrix) periods.
"""
struct Solution <: OptimizationContainer

    plc::Array{Float16}
    qlc::Array{Float16}

    function Solution(system::SystemModel{N}; timeseries::Bool=true) where {N}

        if timeseries
            plc = zeros(Float16,length(system.loads), N)
            qlc = zeros(Float16,length(system.loads), N)
        else
            plc = zeros(Float16,length(system.loads))
            qlc = zeros(Float16,length(system.loads))
        end

        return new(plc, qlc)
    end
end

"""
The `def` macro is used to build other macros that can insert the same block of
julia code into different parts of a program.
"""
macro def(name, definition)
    return quote
        macro $(esc(name))()
            esc($(Expr(:quote, definition)))
        end
    end
end

"a macro for adding the standard AbstractPowerModel fields to a type definition"
CompositeAdequacy.@def ca_fields begin
    
    model::AbstractModel
    topology::Topology
    var::Variables
    sol::Solution
    var_cache::Variables

end


struct DCPPowerModel <: AbstractDCPModel @ca_fields end
struct DCMPPowerModel <: AbstractDCMPPModel @ca_fields end
struct NFAPowerModel <: AbstractNFAModel @ca_fields end


"Constructor for an AbstractPowerModel modeling object"
function PowerFlowProblem(system::SystemModel{N}, method::SimulationSpec, settings::Settings; kwargs...) where {N}

    PowerModel = field(settings, :powermodel)

    if PowerModel <: AbstractDCMPPModel 
        PowerModel = DCMPPowerModel
    elseif PowerModel <: AbstractNFAModel 
        PowerModel = NFAPowerModel
    end

    var = Variables(system, timeseries=false)
    var_cache = deepcopy(var)

    return PowerModel(
        JumpModel(field(settings, :modelmode), field(settings, :optimizer)),
        Topology(system),
        var,
        Solution(system, timeseries=true),
        var_cache
    )
end

""
function empty_optcontainers!(pm::AbstractPowerModel, t)

    empty!(pm.model)
    reset_variables!(pm, nw=t)

    return
end


""
function reset_variables!(pm::AbstractDCMPPModel; nw::Int=0)
    var(pm, :va)[nw] .= topology(pm, :var_cache, :va, nw)
    var(pm, :vm)[nw] .= topology(pm, :var_cache, :vm, nw)
    var(pm, :pg)[nw] .= topology(pm, :var_cache, :pg, nw)
    var(pm, :qg)[nw] .= topology(pm, :var_cache, :qg, nw)
    var(pm, :plc)[nw] .= topology(pm, :var_cache, :plc, nw)
    var(pm, :p)[nw] .= topology(pm, :var_cache, :p, nw)
end


include("Optimizer/utils.jl")
include("Optimizer/variables.jl")
include("Optimizer/constraints.jl")
include("Optimizer/Optimizer.jl")
include("Optimizer/solution.jl")
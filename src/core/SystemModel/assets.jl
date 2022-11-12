
abstract type AbstractAssets end
abstract type TimeSeriesAssets{N,L,T<:Period} <: AbstractAssets end

Base.length(a::AbstractAssets) = length(a.keys)

# abstract type compts end
# struct Length{T <: compts}
#     value::Int
# end
# function Length(::Type{T}, number::Int) where {T <: compts}
#     return Length{T}(number)
# end

"Buses"
struct Buses <: AbstractAssets

    keys::Vector{Int}
    zone::Vector{Int}
    bus_type::Vector{Int}
    bus_i::Vector{Int}
    vmax::Vector{Float16}
    vmin::Vector{Float16}
    base_kv::Vector{Float16}
    va::Vector{Float32}
    vm::Vector{Float32}

    function Buses(
        keys::Vector{Int}, zone::Vector{Int}, bus_type::Vector{Int},
        bus_i::Vector{Int}, vmax::Vector{Float16}, vmin::Vector{Float16}, 
        base_kv::Vector{Float16}, va::Vector{Float32}, vm::Vector{Float32}
    )

        nbuses = length(keys)
        @assert allunique(keys)
        @assert length(keys) == (nbuses)
        @assert length(zone) == (nbuses)
        @assert length(bus_type) == (nbuses)
        @assert length(bus_i) == (nbuses)
        @assert length(vmax) == (nbuses)
        @assert length(vmin) == (nbuses)
        @assert length(base_kv) == (nbuses)
        @assert length(va) == (nbuses)
        @assert length(vm) == (nbuses)
        @assert all(vm .> 0)
        @assert all(base_kv .> 0)

        new(keys, Int.(zone), Int.(bus_type), Int.(bus_i), Float16.(vmax), Float16.(vmin), Float16.(base_kv), Float32.(va), Float32.(vm))
    end
end

Base.:(==)(x::T, y::T) where {T <: Buses} =
    x.keys == y.keys &&
    x.zone == y.zone &&
    x.bus_type == y.bus_type &&
    x.bus_i == y.bus_i &&
    x.vmax == y.vmax &&
    x.vmin == y.vmin &&
    x.base_kv == y.base_kv &&
    x.va == y.va &&
    x.vm == y.vm


Base.getindex(b::B, idxs::AbstractVector{Int}) where {B <: Buses} =
    B(b.keys[idxs], b.zone[idxs], b.bus_type[idxs],
    b.bus_i[idxs], b.vmax[idxs],
    b.vmin[idxs], b.base_kv[idxs],
    b.va[idxs], b.vm[idxs])


"Generators"
struct Generators{N,L,T<:Period} <: TimeSeriesAssets{N,L,T}

    keys::Vector{Int}
    buses::Vector{Int}
    pg::VecOrMat{Float16} # Active power in per unit
    qg::Vector{Float16}  # Active power in per unit
    vg::Vector{Float16}
    pmax::Vector{Float16}
    pmin::Vector{Float16}
    qmax::Vector{Float16}
    qmin::Vector{Float16}
    mbase::Vector{Int}
    cost::Vector{<:Any}
    λ::Vector{Float64} #Failure rate in failures per year
    μ::Vector{Float64} #Repair rate in hours per year
    status::Vector{Bool}

    function Generators{N,L,T}(
        keys::Vector{Int}, buses::Vector{Int}, pg::VecOrMat{Float16}, qg::Vector{Float16}, 
        vg::Vector{Float16}, pmax::Vector{Float16}, pmin::Vector{Float16}, 
        qmax::Vector{Float16}, qmin::Vector{Float16}, mbase::Vector{Int}, 
        cost::Vector{<:Any}, λ::Vector{Float64}, μ::Vector{Float64}, status::Vector{Bool}
    ) where {N,L,T}

        ngens = length(keys)
        @assert allunique(keys)
        #@assert size(pg, 2) == N
        @assert length(qg) == (ngens)
        @assert all(pg .>= 0)
        @assert length(vg) == (ngens)
        @assert all(vg .>= 0)
        @assert length(pmax) == (ngens)
        @assert length(qmax) == (ngens)
        @assert length(pmin) == (ngens)
        @assert all(pmin .>= 0)
        @assert length(qmin) == (ngens)
        @assert length(mbase) == (ngens)
        @assert length(cost) == (ngens)
        @assert length(λ) == (ngens)
        @assert length(μ) == (ngens)
        @assert length(status) == (ngens)

        new{N,L,T}(
            Int.(keys), Int.(buses), pg, Float16.(qg), Float16.(vg), 
            Float16.(pmax), Float16.(pmin), Float16.(qmax), Float16.(qmin), 
            Int.(mbase), cost, Float64.(λ), Float64.(μ), Bool.(status)
        )
    end

end

Base.:(==)(x::T, y::T) where {T <: Generators} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.pg == y.pg &&
    x.qg == y.qg &&
    x.vg == y.vg &&
    x.pmax == y.pmax &&
    x.pmin == y.pmin &&
    x.qmax == y.qmax &&
    x.qmin == y.qmin &&
    x.mbase == y.mbase &&
    x.cost == y.cost &&
    x.λ == y.λ &&
    x.μ == y.μ &&
    x.status == y.status

Base.getindex(g::G, idxs::AbstractVector{Int}) where {G <: Generators} =
    G(g.keys[idxs], g.buses[idxs],
      g.pg[idxs, :], g.qg[idxs],
      g.vg[idxs],
      g.pmax[idxs], g.pmin[idxs], 
      g.qmax[idxs], g.qmin[idxs],
      g.mbase[idxs], g.cost[idxs],
      g.λ[idxs, :], g.μ[idxs, :],
      g.status[idxs])


function Base.vcat(gs::G...) where {N,L,T,G <: Generators{N,L,T}}

    ngens = sum(length(g) for g in gs)
    keys = Vector{Int}(undef, ngens)
    buses = Vector{Int}(undef, ngens)
    pg = VecOrMat{Float16}(undef, ngens, N)
    qg = Vector{Float16}(undef, ngens)
    vg = Vector{Float32}(undef, ngens)
    pmax = Vector{Float16}(undef, ngens)
    pmin = Vector{Float16}(undef, ngens)
    qmax = Vector{Float16}(undef, ngens)
    qmin = Vector{Float16}(undef, ngens)
    mbase = Vector{Bool}(undef, ngens)
    cost = Vector{Any}(undef, ngens)
    λ = Vector{Float64}(undef, ngens)
    μ = Vector{Float64}(undef, ngens)
    status = Vector{Bool}(undef, ngens)
    last_idx = 0

    for g in gs
        n = length(g)
        rows = last_idx .+ (1:n)
        keys[rows] = g.keys
        buses[rows] = g.buses
        pg[rows, :] = g.pg
        qg[rows] = g.qg
        vg[rows] = g.vg
        pmax[rows] = g.pmax
        pmin[rows] = g.pmin
        qmax[rows] = g.qmax
        qmin[rows] = g.qmin
        mbase[rows] = g.mbase
        cost[rows] = g.cost
        λ[rows] = g.λ
        μ[rows] = g.μ
        status[rows] = g.status
        last_idx += n
    end
    return Generators{N,L,T}(keys, buses, pg, qg, vg, pmax, pmin, qmax, qmin, mbase, cost, λ, μ, status)
    
end

"Loads"
struct Loads{N,L,T<:Period} <: TimeSeriesAssets{N,L,T}

    keys::Vector{Int}
    buses::Vector{Int}
    pd::VecOrMat{Float16} # Active power in per unit
    qd::Vector{Float16} # Reactive power in per unit
    cost::Vector{Float16}
    status::Vector{Bool}

    function Loads{N,L,T}(
        keys::Vector{Int}, buses::Vector{Int}, pd::VecOrMat{Float16}, 
        qd::Vector{Float16}, cost::Vector{Float16}, status::Vector{Bool}
        ) where {N,L,T}

        nloads = length(keys)
        @assert length(buses) == nloads
        @assert allunique(keys)
        @assert size(pd, 2) == N
        @assert length(qd) == (nloads)
        @assert all(pd .>= 0)
        @assert length(cost) == (nloads)
        @assert length(status) == (nloads)

        new{N,L,T}(Int.(keys), Int.(buses), pd, Float16.(qd), Float16.(cost), Bool.(status))
    end

end

Base.:(==)(x::T, y::T) where {T <: Loads} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.pd == y.pd &&
    x.qd == y.qd &&
    x.cost == y.cost &&
    x.status == y.status
#

"Storages"
struct Storages{N,L,T<:Period} <: TimeSeriesAssets{N,L,T}

    keys::Vector{Int}
    buses::Vector{Int}
    ps::Vector{Float16}  # Active power in per unit
    qs::Vector{Float16}
    energy::Vector{Float16}
    energy_rating::Vector{Float16} # energy_capacity
    charge_rating::Vector{Float16}
    discharge_rating::Vector{Float16}
    charge_efficiency::Vector{Float16}
    discharge_efficiency::Vector{Float16}
    #carryover_efficiency::Vector{Float16}
    thermal_rating::Vector{Float16}
    qmax::Vector{Float16}
    qmin::Vector{Float16}
    r::Vector{Float16}
    x::Vector{Float16}
    ploss::Vector{Float16}
    qloss::Vector{Float16}
    λ::Vector{Float64} #Failure rate in failures per year
    μ::Vector{Float64} #Repair rate in hours per year
    status::Vector{Bool}

    function Storages{N,L,T}(
        keys::Vector{Int}, buses::Vector{Int}, ps::Vector{Float16}, qs::Vector{Float16},
        energy::Vector{Float16}, energy_rating::Vector{Float16}, charge_rating::Vector{Float16}, 
        discharge_rating::Vector{Float16}, charge_efficiency::Vector{Float16}, discharge_efficiency::Vector{Float16}, 
        thermal_rating::Vector{Float16}, qmax::Vector{Float16}, qmin::Vector{Float16}, r::Vector{Float16}, 
        x::Vector{Float16}, ploss::Vector{Float16}, qloss::Vector{Float16}, λ::Vector{Float64}, μ::Vector{Float64}, status::Vector{Bool}
    ) where {N,L,T}

        nstors = length(keys)
        @assert allunique(keys)
        @assert length(buses) == (nstors)
        @assert length(ps) == (nstors)
        @assert length(qs) == (nstors)
        @assert length(energy) == (nstors)
        @assert length(energy_rating) == (nstors)
        @assert length(charge_rating) == (nstors)
        @assert length(discharge_rating) == (nstors)
        @assert length(thermal_rating) == (nstors)
        @assert length(qmax) == (nstors)
        @assert length(qmin) == (nstors)
        @assert length(r) == (nstors)
        @assert length(x) == (nstors)
        @assert length(ploss) == (nstors)
        @assert length(qloss) == (nstors)
        @assert length(λ) == (nstors)
        @assert length(μ) == (nstors)
        @assert length(status) == (nstors)
        @assert all(0 .<= energy)
        @assert all(0 .<= energy_rating)
        @assert all(0 .<= charge_rating)
        @assert all(0 .<= discharge_rating)
        @assert all(0 .<= charge_efficiency)
        @assert all(0 .<= discharge_efficiency)

        new{N,L,T}(Int.(keys), Int.(buses), Float16.(ps), Float16.(qs),
        Float16.(energy), Float16.(energy_rating), Float16.(charge_rating), 
        Float16.(discharge_rating), Float16.(charge_efficiency), Float16.(discharge_efficiency), 
        Float16.(thermal_rating), Float16.(qmax), Float16.(qmin), Float16.(r), 
        Float16.(x), Float16.(ploss), Float16.(qloss), Float64.(λ), Float64.(μ), Bool.(status))
    end
end

Base.:(==)(x::T, y::T) where {T <: Storages} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.ps == y.ps &&
    x.qs == y.qs &&
    x.energy == y.energy &&
    x.energy_rating == y.energy_rating &&
    x.charge_rating == y.charge_rating &&
    x.discharge_rating == y.discharge_rating &&
    x.charge_efficiency == y.charge_efficiency &&
    x.discharge_efficiency == y.discharge_efficiency &&
    x.thermal_rating == y.thermal_rating &&
    x.qmax == y.qmax &&
    x.qmin == y.qmin &&
    x.r == y.r &&
    x.x == y.x &&
    x.ploss == y.ploss &&
    x.qloss == y.qloss &&
    x.λ == y.λ &&
    x.μ == y.μ &&
    x.status == y.status
#

"GeneratorStorages"
struct GeneratorStorages{N,L,T<:Period} <: TimeSeriesAssets{N,L,T}

    keys::Vector{Int}
    buses::Vector{Int}
    ps::Vector{Float16}  # Active power in per unit
    qs::Vector{Float16}
    energy::Vector{Float16}
    energy_rating::Vector{Float16} # energy_capacity
    charge_rating::Vector{Float16}
    discharge_rating::Vector{Float16}
    charge_efficiency::Vector{Float16}
    discharge_efficiency::Vector{Float16}

    inflow::Matrix{Float16}
    gridwithdrawal_rating::Matrix{Float16}
    gridinjection_rating::Matrix{Float16}

    λ::Vector{Float64} #Failure rate in failures per year
    μ::Vector{Float64} #Repair rate in hours per year
    status::Vector{Bool}
    #carryover_efficiency::Vector{Float16}
    #thermal_rating::Vector{Float16}
    #qmax::Vector{Float16}
    #qmin::Vector{Float16}
    #r::Vector{Float16}
    #x::Vector{Float16}
    #ploss::Vector{Float16}
    #qloss::Vector{Float16}

    function GeneratorStorages{N,L,T}(
        keys::Vector{Int}, buses::Vector{Int},
        ps::Vector{Float16}, qs::Vector{Float16},
        energy::Vector{Float16}, energy_rating::Vector{Float16},
        charge_rating::Vector{Float16}, discharge_rating::Vector{Float16},
        charge_efficiency::Vector{Float16}, discharge_efficiency::Vector{Float16},
        inflow::Matrix{Float16}, gridwithdrawal_rating::Matrix{Float16}, 
        gridinjection_rating::Matrix{Float16}, λ::Vector{Float64}, 
        μ::Vector{Float64}, status::Vector{Bool}
    ) where {N,L,T}

        nstors = length(keys)
        @assert allunique(keys)
        @assert length(buses) == (nstors)
        @assert length(ps) == (nstors)
        @assert length(qs) == (nstors)
        @assert length(energy) == (nstors)
        @assert length(energy_rating) == (nstors)
        @assert length(charge_rating) == (nstors)
        @assert length(discharge_rating) == (nstors)
        @assert size(inflow) == (nstors, N)
        @assert size(gridwithdrawal_rating) == (nstors, N)
        @assert size(gridinjection_rating) == (nstors, N)
        @assert length(λ) == (nstors)
        @assert length(μ) == (nstors)
        @assert length(status) == (nstors)
        @assert all(0 .<= energy)
        @assert all(0 .<= energy_rating)
        @assert all(0 .<= charge_rating)
        @assert all(0 .<= discharge_rating)
        @assert all(0 .<= charge_efficiency)
        @assert all(0 .<= discharge_efficiency)

        new{N,L,T}(Int.(keys), Int.(buses), Float16.(ps), Float16.(qs),
        Float16.(energy), Float16.(energy_rating), Float16.(charge_rating),
        Float16.(discharge_rating), Float16.(charge_efficiency), Float16.(discharge_efficiency),
        inflow, gridwithdrawal_rating, gridinjection_rating, Float64.(λ), Float64.(μ), Bool.(status))
    end
end

Base.:(==)(x::T, y::T) where {T <: GeneratorStorages} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.ps == y.ps &&
    x.qs == y.qs &&
    x.energy == y.energy &&
    x.energy_rating == y.energy_rating &&
    x.charge_rating == y.charge_rating &&
    x.discharge_rating == y.discharge_rating &&
    x.inflow == y.inflow &&
    x.gridwithdrawal_capacity == y.gridwithdrawal_capacity &&
    x.gridinjection_capacity == y.gridinjection_capacity &&
    x.λ == y.λ &&
    x.μ == y.μ &&
    x.status == y.status
#

"Branches"
struct Branches <: AbstractAssets

    keys::Vector{Int}
    f_bus::Vector{Int} #buses_from
    t_bus::Vector{Int} #buses_to
    rate_a::Vector{Float16} #Long term rating or Rate_A
    rate_b::Vector{Float16} #Short term rating or Rate_B
    r::Vector{Float16} #Resistance values
    x::Vector{Float16} #Reactance values
    b_fr::Vector{Float16} #susceptance/2
    b_to::Vector{Float16} #susceptance/2
    g_fr::Vector{Float16}
    g_to::Vector{Float16}
    shift::Vector{Float16} #angle_shift
    angmin::Vector{Float16}
    angmax::Vector{Float16}
    transformer::Vector{Bool}
    tap::Vector{Float16} #tap_ratio
    λ::Vector{Float64} #Failure rate in failures per year
    μ::Vector{Float64} #Repair rate in hours per year
    status::Vector{Bool}

    function Branches(
        keys::Vector{Int}, f_bus::Vector{Int}, t_bus::Vector{Int}, rate_a::Vector{Float16}, 
        rate_b::Vector{Float16}, r::Vector{Float16}, x::Vector{Float16}, 
        b_fr::Vector{Float16}, b_to::Vector{Float16}, g_fr::Vector{Float16}, g_to::Vector{Float16}, 
        shift::Vector{Float16}, angmin::Vector{Float16}, angmax::Vector{Float16}, transformer::Vector{Bool}, 
        tap::Vector{Float16}, λ::Vector{Float64}, μ::Vector{Float64}, status::Vector{Bool}
    )

        nbranches = length(keys)
        @assert allunique(keys)
        @assert length(f_bus) == (nbranches)
        @assert length(t_bus) == (nbranches)
        @assert length(rate_a) == (nbranches)
        @assert length(rate_b) == (nbranches)
        @assert length(r) == (nbranches)
        @assert length(x) == (nbranches)
        @assert length(b_fr) == (nbranches)
        @assert length(b_to) == (nbranches)
        @assert length(g_fr) == (nbranches)
        @assert length(g_to) == (nbranches)
        @assert length(shift) == (nbranches)
        @assert length(angmin) == (nbranches)
        @assert length(angmax) == (nbranches)
        @assert length(transformer) == (nbranches)
        @assert length(tap) == (nbranches)
        @assert length(λ) == (nbranches)
        @assert length(μ) == (nbranches)
        @assert length(status) == (nbranches)
        @assert all(rate_a .>= 0)
        @assert all(rate_b .>= 0)
        @assert all(r .>= 0)
        @assert all(x .>= 0)

        new(
            Int.(keys), Int.(f_bus), Int.(t_bus), Float16.(rate_a), Float16.(rate_b),
            Float16.(r), Float16.(x), Float16.(b_fr), Float16.(b_to), Float16.(g_fr), 
            Float16.(g_to), Float16.(shift), Float16.(angmin), Float16.(angmax),
            Bool.(transformer), Float16.(tap), Float64.(λ), Float64.(μ), Bool.(status))
    end

end

Base.:(==)(x::T, y::T) where {T <: Branches} =
    x.keys == y.keys &&
    x.f_bus == y.f_bus &&
    x.t_bus == y.t_bus &&
    x.rate_a == y.rate_a &&
    x.rate_b == y.rate_b &&
    x.r == y.r &&
    x.x == y.x &&
    x.b_fr == y.b_fr &&
    x.b_to == y.b_to &&
    x.g_fr == y.g_fr &&
    x.g_to == y.g_to &&
    x.shift == y.shift &&
    x.angmin == y.angmin &&
    x.angmax == y.angmax &&
    x.transformer == y.transformer &&
    x.tap == y.tap &&
    x.λ == y.λ &&
    x.μ == y.μ &&
    x.status == y.status
#

"Shunts"
struct Shunts <: AbstractAssets

    keys::Vector{Int}
    buses::Vector{Int}
    bs::Vector{Float16} #susceptance
    gs::Vector{Float16}
    status::Vector{Bool}

    function Shunts(
        keys::Vector{Int}, buses::Vector{Int}, bs::Vector{Float16}, 
        gs::Vector{Float16}, status::Vector{Bool}
    )

        nshunts = length(keys)
        @assert allunique(keys)
        @assert length(buses) == (nshunts)
        @assert length(bs) == (nshunts)
        @assert length(gs) == (nshunts)
        @assert length(status) == (nshunts)

        new(Int.(keys), Int.(buses), Float16.(bs), Float16.(gs), Bool.(status))
    end

end

Base.:(==)(x::T, y::T) where {T <: Shunts} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.bs == y.bs &&
    x.gs == y.gs &&
    x.status == y.status
#
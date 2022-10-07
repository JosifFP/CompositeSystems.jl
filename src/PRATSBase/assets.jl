abstract type AbstractAssets{N,L,T<:Period,S} end
Base.length(a::AbstractAssets) = length(a.keys)

"Buses"
struct Buses{N,L,T<:Period,S} <: AbstractAssets{N,L,T,S}

    keys::Vector{Int}
    zone::Vector{Int}
    bus_type::Vector{Int}
    area::Vector{Int}
    index::Vector{Int}
    source_id::Vector{String}
    vmax::Vector{Float16}
    vmin::Vector{Float16}
    base_kv::Vector{Float16}
    va::Vector{Float32}
    vm::Vector{Float32}

    function Buses{N,L,T,S}(
        keys::Vector{Int}, zone::Vector{Int}, bus_type::Vector{Int},
        area::Vector{Int}, index::Vector{Int},
        source_id::Vector{String}, vmax::Vector{Float16},
        vmin::Vector{Float16}, base_kv::Vector{Float16},
        va::Vector{Float32}, vm::Vector{Float32}
    ) where {N,L,T,S}

        nbuses = length(keys)
        @assert allunique(keys)
        @assert length(keys) == (nbuses)
        @assert length(zone) == (nbuses)
        @assert length(bus_type) == (nbuses)
        @assert length(area) == (nbuses)
        @assert length(index) == (nbuses)
        @assert length(source_id) == (nbuses)
        @assert length(vmax) == (nbuses)
        @assert length(vmin) == (nbuses)
        @assert length(base_kv) == (nbuses)
        @assert length(va) == (nbuses)
        @assert length(vm) == (nbuses)
        @assert all(vm .> 0)
        @assert all(base_kv .> 0)

        new{N,L,T,S}(
            Int.(keys), Int.(zone), Int.(bus_type), Int.(area), Int.(index),
            string.(source_id), Float16.(vmax), Float16.(vmin), Float16.(base_kv), Float32.(va), Float32.(vm))
    end
end

Base.:(==)(x::T, y::T) where {T <: Buses} =
    x.keys == y.keys &&
    x.zone == y.zone &&
    x.bus_type == y.bus_type &&
    x.area == y.area &&
    x.index == y.index &&
    x.source_id == y.source_id &&
    x.vmax == y.vmax &&
    x.vmin == y.vmin &&
    x.base_kv == y.base_kv &&
    x.va == y.va &&
    x.vm == y.vm


Base.getindex(b::B, idxs::AbstractVector{Int}) where {B <: Buses} =
    B(b.keys[idxs], b.zone[idxs], b.bus_type[idxs],
      b.area[idxs], b.index[idxs],
      b.source_id[idxs], b.vmax[idxs],
      b.vmin[idxs], b.base_kv[idxs],
      b.va[idxs], b.vm[idxs])


"Generators"
struct Generators{N,L,T<:Period,S} <: AbstractAssets{N,L,T,S}

    keys::Vector{Int}
    buses::Vector{Int}
    pg::Matrix{Float16}  # Active power in per unit
    qg::Vector{Float16}  # Active power in per unit
    vg::Vector{Float32}
    pmax::Vector{Float16}
    pmin::Vector{Float16}
    qmax::Vector{Float16}
    qmin::Vector{Float16}
    source_id::Vector{String}
    mbase::Vector{Int}
    status::BitVector
    cost::Vector{<:Any}
    λ::Vector{Float64} #Failure rate in failures per year
    μ::Vector{Float64} #Repair rate in hours per year

    function Generators{N,L,T,S}(
        keys::Vector{Int}, buses::Vector{Int}, 
        pg::Matrix{Float16}, qg::Vector{Float16},
        vg::Vector{Float32},  
        pmax::Vector{Float16}, pmin::Vector{Float16},
        qmax::Vector{Float16}, qmin::Vector{Float16},
        source_id::Vector{String}, mbase::Vector{Int}, 
        status::BitVector, cost::Vector{<:Any},
        λ::Vector{Float64}, μ::Vector{Float64}
    ) where {N,L,T,S}

        ngens = length(keys)
        @assert allunique(keys)
        @assert size(pg) == (ngens, N)
        @assert length(qg) == (ngens)
        @assert all(pg .>= 0)
        @assert length(vg) == (ngens)
        @assert all(vg .> 0)
        @assert length(pmax) == (ngens)
        @assert length(qmax) == (ngens)
        @assert length(pmin) == (ngens)
        @assert all(pmin .>= 0)
        @assert length(qmin) == (ngens)
        @assert length(source_id) == (ngens)
        @assert length(mbase) == (ngens)
        @assert length(status) == (ngens)
        @assert length(cost) == (ngens)
        @assert length(λ) == (ngens)
        @assert length(μ) == (ngens)

        new{N,L,T,S}(
            Int.(keys), Int.(buses), pg, Float16.(qg), Float32.(vg), 
            Float16.(pmax), Float16.(pmin), Float16.(qmax), Float16.(qmin), 
            string.(source_id), Int.(mbase), Bool.(status), cost, Float64.(λ), Float64.(μ)
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
    x.source_id == y.source_id &&
    x.mbase == y.mbase &&
    x.status == y.status &&
    x.cost == y.cost &&
    x.λ == y.λ &&
    x.μ == y.μ

Base.getindex(g::G, idxs::AbstractVector{Int}) where {G <: Generators} =
    G(g.keys[idxs], g.buses[idxs],
      g.pg[idxs, :], g.qg[idxs],
      g.vg[idxs],
      g.pmax[idxs], g.pmin[idxs], 
      g.qmax[idxs], g.qmin[idxs],
      g.source_id[idxs], g.mbase[idxs],
      g.status[idxs], g.cost[idxs],
      g.λ[idxs, :], g.μ[idxs, :])

function Base.vcat(gs::G...) where {N, L, T, S, G <: Generators{N,L,T,S}}

    ngens = sum(length(g) for g in gs)
    keys = Vector{Int}(undef, ngens)
    buses = Vector{Int}(undef, ngens)
    pg = Matrix{Float16}(undef, ngens, N)
    qg = Vector{Float16}(undef, ngens)
    vg = Vector{Float32}(undef, ngens)
    pmax = Vector{Float16}(undef, ngens)
    pmin = Vector{Float16}(undef, ngens)
    qmax = Vector{Float16}(undef, ngens)
    qmin = Vector{Float16}(undef, ngens)
    source_id = Vector{Int}(undef, ngens)
    mbase = Vector{Bool}(undef, ngens)
    status = Vector{Bool}(undef, ngens)
    cost = Vector{Any}(undef, ngens)
    λ = Vector{Float64}(undef, ngens)
    μ = Vector{Float64}(undef, ngens)
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
        source_id[rows] = g.source_id
        mbase[rows] = g.mbase
        status[rows] = g.status
        cost[rows] = g.cost
        λ[rows] = g.λ
        μ[rows] = g.μ
        last_idx += n
    end
    return Generators{N,L,T,S}(keys, buses, pg, qg, vg, pmax, pmin, qmax, qmin, source_id, mbase, status, cost, λ, μ)
    
end

"Loads"
struct Loads{N,L,T<:Period,S} <: AbstractAssets{N,L,T,S}

    keys::Vector{Int}
    buses::Vector{Int}
    pd::Matrix{Float16} # Active power in per unit
    qd::Vector{Float16} # Reactive power in per unit
    source_id::Vector{String}
    status::BitVector
    cost::Vector{Float16}

    function Loads{N,L,T,S}(
        keys::Vector{Int}, buses::Vector{Int}, 
        pd::Matrix{Float16}, qd::Vector{Float16}, 
        source_id::Vector{String}, status::BitVector, cost::Vector{Float16}
        ) where {N,L,T,S}

        nloads = length(keys)
        @assert length(buses) == nloads
        @assert allunique(keys)
        @assert size(pd) == (nloads, N)
        @assert length(qd) == (nloads)
        @assert all(pd .>= 0)
        @assert length(source_id) == (nloads)
        @assert length(status) == (nloads)
        @assert length(cost) == (nloads)

        new{N,L,T,S}(Int.(keys), Int.(buses), pd, Float16.(qd), string.(source_id), Bool.(status), Float16.(cost))
    end

end

Base.:(==)(x::T, y::T) where {T <: Loads} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.pd == y.pd &&
    x.qd == y.qd &&
    x.source_id == y.source_id &&
    x.status == y.status &&
    x.cost == y.cost
#

"Storages"
struct Storages{N,L,T<:Period,S} <: AbstractAssets{N,L,T,S}

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
    status::BitVector
    λ::Vector{Float64} #Failure rate in failures per year
    μ::Vector{Float64} #Repair rate in hours per year

    function Storages{N,L,T,S}(
        keys::Vector{Int}, buses::Vector{Int}, ps::Vector{Float16}, qs::Vector{Float16},
        energy::Vector{Float16}, energy_rating::Vector{Float16}, charge_rating::Vector{Float16}, discharge_rating::Vector{Float16},
        charge_efficiency::Vector{Float16}, discharge_efficiency::Vector{Float16}, thermal_rating::Vector{Float16}, qmax::Vector{Float16}, 
        qmin::Vector{Float16}, r::Vector{Float16}, x::Vector{Float16}, ploss::Vector{Float16}, 
        qloss::Vector{Float16}, status::BitVector, λ::Vector{Float64}, μ::Vector{Float64}
    ) where {N,L,T,S}

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
        @assert length(status) == (nstors)
        @assert length(λ) == (nstors)
        @assert length(μ) == (nstors)
        @assert all(0 .<= energy)
        @assert all(0 .<= energy_rating)
        @assert all(0 .<= charge_rating)
        @assert all(0 .<= discharge_rating)
        @assert all(0 .<= charge_efficiency)
        @assert all(0 .<= discharge_efficiency)

        new{N,L,T,S}(Int.(keys), Int.(buses), Float16.(ps), Float16.(qs),
        Float16.(energy), Float16.(energy_rating), Float16.(charge_rating), Float16.(discharge_rating),
        Float16.(charge_efficiency), Float16.(discharge_efficiency), Float16.(thermal_rating), Float16.(qmax),
        Float16.(qmin), Float16.(r), Float16.(x), Float16.(ploss), 
        Float16.(qloss), Bool.(status), Float64.(λ), Float64.(μ))
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
    x.status == y.status &&
    x.λ == y.λ &&
    x.μ == y.μ
#

"GeneratorStorages"
struct GeneratorStorages{N,L,T<:Period,S} <: AbstractAssets{N,L,T,S}

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
    #thermal_rating::Vector{Float16}
    #qmax::Vector{Float16}
    #qmin::Vector{Float16}
    #r::Vector{Float16}
    #x::Vector{Float16}
    #ploss::Vector{Float16}
    #qloss::Vector{Float16}
    status::BitVector
    inflow::Matrix{Float16}
    gridwithdrawal_rating::Matrix{Float16}
    gridinjection_rating::Matrix{Float16}

    λ::Vector{Float64} #Failure rate in failures per year
    μ::Vector{Float64} #Repair rate in hours per year

    function GeneratorStorages{N,L,T,S}(
        keys::Vector{Int}, buses::Vector{Int},
        ps::Vector{Float16}, qs::Vector{Float16},
        energy::Vector{Float16}, energy_rating::Vector{Float16},
        charge_rating::Vector{Float16}, discharge_rating::Vector{Float16},
        charge_efficiency::Vector{Float16}, discharge_efficiency::Vector{Float16},
        status::BitVector, inflow::Matrix{Float16}, 
        gridwithdrawal_rating::Matrix{Float16}, gridinjection_rating::Matrix{Float16},
        λ::Vector{Float64}, μ::Vector{Float64}
    ) where {N,L,T,S}

        nstors = length(keys)
        @assert allunique(keys)
        @assert length(buses) == (nstors)
        @assert length(ps) == (nstors)
        @assert length(qs) == (nstors)
        @assert length(energy) == (nstors)
        @assert length(energy_rating) == (nstors)
        @assert length(charge_rating) == (nstors)
        @assert length(discharge_rating) == (nstors)
        @assert length(status) == (nstors)
        @assert size(inflow) == (nstors, N)
        @assert size(gridwithdrawal_rating) == (nstors, N)
        @assert size(gridinjection_rating) == (nstors, N)
        @assert length(λ) == (nstors)
        @assert length(μ) == (nstors)
        @assert all(0 .<= energy)
        @assert all(0 .<= energy_rating)
        @assert all(0 .<= charge_rating)
        @assert all(0 .<= discharge_rating)
        @assert all(0 .<= charge_efficiency)
        @assert all(0 .<= discharge_efficiency)

        new{N,L,T,S}(Int.(keys), Int.(buses), Float16.(ps), Float16.(qs),
        Float16.(energy), Float16.(energy_rating), Float16.(charge_rating), Float16.(discharge_rating), 
        Float16.(charge_efficiency), Float16.(discharge_efficiency), Bool.(status), 
        inflow, gridwithdrawal_rating, gridinjection_rating,
        Float64.(λ), Float64.(μ))
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
    x.status == y.status &&
    x.inflow == y.inflow &&
    x.gridwithdrawal_capacity == y.gridwithdrawal_capacity &&
    x.gridinjection_capacity == y.gridinjection_capacity &&
    x.λ == y.λ &&
    x.μ == y.μ
#

"Branches"
struct Branches{N,L,T<:Period,S} <: AbstractAssets{N,L,T,S}

    keys::Vector{Int}
    f_bus::Vector{Int} #buses_from
    t_bus::Vector{Int} #buses_to
    rate_a::Vector{Float16} #Long term rating or Rate_A
    rate_b::Vector{Float16} #Short term rating or Rate_B
    rate_c::Vector{Float16} #emergency rating or Rate_C
    r::Vector{Float16} #Resistance values
    x::Vector{Float16} #Reactance values
    b_fr::Vector{Float16} #susceptance/2
    b_to::Vector{Float16} #susceptance/2
    g_fr::Vector{Float16}
    g_to::Vector{Float16}
    shift::Vector{Float16} #angle_shift
    angmin::Vector{Float16}
    angmax::Vector{Float16}
    transformer::BitVector
    tap::Vector{Float16} #tap_ratio
    source_id::Vector{String}
    status::BitVector
    λ::Vector{Float64} #Failure rate in failures per year
    μ::Vector{Float64} #Repair rate in hours per year

    function Branches{N,L,T,S}(
        keys::Vector{Int}, f_bus::Vector{Int}, t_bus::Vector{Int},
        rate_a::Vector{Float16}, rate_b::Vector{Float16}, rate_c::Vector{Float16},
        r::Vector{Float16}, x::Vector{Float16}, b_fr::Vector{Float16}, b_to::Vector{Float16},
        g_fr::Vector{Float16}, g_to::Vector{Float16}, shift::Vector{Float16},
        angmin::Vector{Float16}, angmax::Vector{Float16}, transformer::BitVector, tap::Vector{Float16},
        source_id::Vector{String}, status::BitVector, λ::Vector{Float64}, μ::Vector{Float64}
    ) where {N,L,T,S}

        nbranches = length(keys)
        @assert allunique(keys)
        @assert length(f_bus) == (nbranches)
        @assert length(t_bus) == (nbranches)
        @assert length(rate_a) == (nbranches)
        @assert length(rate_b) == (nbranches)
        @assert length(rate_c) == (nbranches)
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
        @assert length(source_id) == (nbranches)
        @assert length(status) == (nbranches)
        @assert length(λ) == (nbranches)
        @assert length(μ) == (nbranches)
        @assert all(rate_a .>= 0)
        @assert all(rate_b .>= 0)
        @assert all(rate_c .>= 0)
        @assert all(r .>= 0)
        @assert all(x .>= 0)

        new{N,L,T,S}(
            Int.(keys), Int.(f_bus), Int.(t_bus), Float16.(rate_a), Float16.(rate_b), Float16.(rate_c),
            Float16.(r), Float16.(x), Float16.(b_fr), Float16.(b_to), Float16.(g_fr), Float16.(g_to), Float16.(shift),
            Float16.(angmin), Float16.(angmax), Bool.(transformer), Float16.(tap), String.(source_id), Bool.(status),
            Float64.(λ), Float64.(μ))
    end

end

Base.:(==)(x::T, y::T) where {T <: Branches} =
    x.keys == y.keys &&
    x.f_bus == y.f_bus &&
    x.t_bus == y.t_bus &&
    x.rate_a == y.rate_a &&
    x.rate_b == y.rate_b &&
    x.rate_c == y.rate_c &&
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
    x.source_id == y.source_id &&
    x.status == y.status &&
    x.λ == y.λ &&
    x.μ == y.μ
#

"Shunts"
struct Shunts{N,L,T<:Period,S} <: AbstractAssets{N,L,T,S}

    keys::Vector{Int}
    buses::Vector{Int}
    bs::Vector{Float16} #susceptance
    gs::Vector{Float16}
    source_id::Vector{String}
    status::BitVector

    function Shunts{N,L,T,S}(
        keys::Vector{Int}, buses::Vector{Int},
        bs::Vector{Float16}, gs::Vector{Float16},
        source_id::Vector{String}, status::BitVector
    ) where {N,L,T,S}

        nshunts = length(keys)
        @assert allunique(keys)
        @assert length(buses) == (nshunts)
        @assert length(bs) == (nshunts)
        @assert length(gs) == (nshunts)
        @assert length(source_id) == (nshunts)
        @assert length(status) == (nshunts)

        new{N,L,T,S}(
            Int.(keys), Int.(buses), Float16.(bs), Float16.(gs), String.(source_id), Bool.(status))
    end

end

Base.:(==)(x::T, y::T) where {T <: Shunts} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.bs == y.bs &&
    x.gs == y.gs &&
    x.source_id == y.source_id &&
    x.status == y.status
#

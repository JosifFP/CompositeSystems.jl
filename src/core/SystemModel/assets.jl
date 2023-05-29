abstract type AbstractAssets end
abstract type TimeSeriesAssets{N,L,T<:Period} <: AbstractAssets end

Base.length(a::AbstractAssets) = length(a.keys)

"Buses"
struct Buses <: AbstractAssets

    keys::Vector{Int}
    zone::Vector{Int}
    bus_type::Vector{Int}
    bus_i::Vector{Int}
    vmax::Vector{Float32}
    vmin::Vector{Float32}
    base_kv::Vector{Float32}
    va::Vector{Float32}
    vm::Vector{Float32}

    function Buses(
        keys::Vector{Int}, zone::Vector{Int}, bus_type::Vector{Int},
        bus_i::Vector{Int}, vmax::Vector{Float32}, vmin::Vector{Float32}, 
        base_kv::Vector{Float32}, va::Vector{Float32}, vm::Vector{Float32}
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
        @assert all(base_kv .>= 0)

        new(keys, Int.(zone), Int.(bus_type), Int.(bus_i), Float32.(vmax), 
        Float32.(vmin), Float32.(base_kv), Float32.(va), Float32.(vm))
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
    pg::VecOrMat{Float32} # Active power in per unit
    qg::Vector{Float32}  # Active power in per unit
    vg::Vector{Float32}
    pmax::Vector{Float32}
    pmin::Vector{Float32}
    qmax::Vector{Float32}
    qmin::Vector{Float32}
    mbase::Vector{Float32}
    cost::Vector{<:Any}
    state_model::Vector{Int}
    λ_updn::Vector{Float64}
    μ_updn::Vector{Float64}
    λ_upde::Vector{Float64}
    μ_upde::Vector{Float64}
    pde::Vector{Float32}
    status::Vector{Bool}

    function Generators{N,L,T}(
        keys::Vector{Int}, buses::Vector{Int}, 
        pg::VecOrMat{Float32}, qg::Vector{Float32}, 
        vg::Vector{Float32}, pmax::Vector{Float32}, pmin::Vector{Float32}, 
        qmax::Vector{Float32}, qmin::Vector{Float32},
        mbase::Vector{Float32}, cost::Vector{<:Any},  state_model::Vector{Int},
        λ_updn::Vector{Float64}, μ_updn::Vector{Float64}, 
        λ_upde::Vector{Float64}, μ_upde::Vector{Float64}, 
        pde::Vector{Float32}, status::Vector{Bool}
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
        @assert length(state_model) == (ngens)
        @assert length(λ_updn) == (ngens)
        @assert length(μ_updn) == (ngens)
        @assert length(λ_upde) == (ngens)
        @assert length(μ_upde) == (ngens)
        @assert length(pde) == (ngens)
        @assert length(status) == (ngens)

        new{N,L,T}(
            Int.(keys), Int.(buses), pg, Float32.(qg), Float32.(vg), 
            Float32.(pmax), Float32.(pmin), Float32.(qmax), Float32.(qmin), 
            Float32.(mbase), cost, Int.(state_model), Float64.(λ_updn), Float64.(μ_updn),
            Float64.(λ_upde), Float64.(μ_upde), Float32.(pde), Bool.(status)
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
    x.state_model == y.state_model &&
    x.λ_updn == y.λ_updn &&
    x.μ_updn == y.μ_updn &&
    x.λ_upde == y.λ_upde &&
    x.μ_upde == y.μ_upde &&
    x.pde == y.pde &&
    x.status == y.status

Base.getindex(g::G, idxs::AbstractVector{Int}) where {G <: Generators} =
    G(g.keys[idxs], g.buses[idxs],
      g.pg[idxs, :], g.qg[idxs],
      g.vg[idxs],
      g.pmax[idxs], g.pmin[idxs], 
      g.qmax[idxs], g.qmin[idxs],
      g.mbase[idxs], g.cost[idxs], 
      g.state_model[idxs],
      g.λ_updn[idxs], g.μ_updn[idxs],
      g.λ_upde[idxs], g.μ_upde[idxs],
      g.pde[idxs],   g.status[idxs])


function Base.vcat(gs::G...) where {N,L,T,G <: Generators{N,L,T}}

    ngens = sum(length(g) for g in gs)
    keys = Vector{Int}(undef, ngens)
    buses = Vector{Int}(undef, ngens)
    pg = VecOrMat{Float32}(undef, ngens, N)
    qg = Vector{Float32}(undef, ngens)
    vg = Vector{Float32}(undef, ngens)
    pmax = Vector{Float32}(undef, ngens)
    pmin = Vector{Float32}(undef, ngens)
    qmax = Vector{Float32}(undef, ngens)
    qmin = Vector{Float32}(undef, ngens)
    mbase = Vector{Float32}(undef, ngens)
    cost = Vector{Any}(undef, ngens)
    state_model = Vector{Any}(undef, ngens)
    λ_updn = Vector{Float64}(undef, ngens)
    μ_updn = Vector{Float64}(undef, ngens)
    λ_upde = Vector{Float64}(undef, ngens)
    μ_upde = Vector{Float64}(undef, ngens)
    pde = Vector{Float32}(undef, ngens)
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
        state_model[rows] = g.state_model
        λ_updn[rows] = g.λ_updn
        μ_updn[rows] = g.μ_updn
        λ_upde[rows] = g.λ_upde
        μ_upde[rows] = g.μ_upde
        pde[rows] = g.pde
        status[rows] = g.status
        last_idx += n
    end
    return Generators{N,L,T}(keys, buses, pg, qg, vg, pmax, pmin, qmax, qmin, mbase, 
    cost, state_model, λ_updn, μ_updn, λ_upde, μ_upde, pde, status)
    
end

"Loads"
struct Loads{N,L,T<:Period} <: TimeSeriesAssets{N,L,T}

    keys::Vector{Int}
    buses::Vector{Int}
    pd::VecOrMat{Float32} # Active power in per unit
    qd::Vector{Float32} # Reactive power in per unit
    pf::Vector{Float32} # Power factor
    cost::Vector{Float32}
    status::Vector{Bool}

    function Loads{N,L,T}(
        keys::Vector{Int}, buses::Vector{Int}, pd::VecOrMat{Float32}, qd::Vector{Float32}, 
        pf::Vector{Float32}, cost::Vector{Float32}, status::Vector{Bool}
        ) where {N,L,T}

        nloads = length(keys)
        @assert length(buses) == nloads
        @assert allunique(keys)
        @assert size(pd, 2) == N
        @assert length(qd) == (nloads)
        @assert all(pd .>= 0)
        @assert length(pf) == (nloads)
        @assert length(cost) == (nloads)
        @assert length(status) == (nloads)

        new{N,L,T}(Int.(keys), Int.(buses), pd, Float32.(qd), Float32.(pf), Float32.(cost), Bool.(status))
    end

end

Base.:(==)(x::T, y::T) where {T <: Loads} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.pd == y.pd &&
    x.qd == y.qd &&
    x.pf == y.pf &&
    x.cost == y.cost &&
    x.status == y.status
#

"Storages"
struct Storages{N,L,T<:Period} <: TimeSeriesAssets{N,L,T}

    keys::Vector{Int}
    buses::Vector{Int}
    ps::Vector{Float32}  # Active power in per unit
    qs::Vector{Float32}
    energy::Vector{Float32}
    energy_rating::Vector{Float32} # energy_capacity
    charge_rating::Vector{Float32}
    discharge_rating::Vector{Float32}
    charge_efficiency::Vector{Float32}
    discharge_efficiency::Vector{Float32}
    thermal_rating::Vector{Float32}
    qmax::Vector{Float32}
    qmin::Vector{Float32}
    r::Vector{Float32}
    x::Vector{Float32}
    ploss::Vector{Float32}
    qloss::Vector{Float32}
    λ_updn::Vector{Float64} #Failure rate in failures per year
    μ_updn::Vector{Float64} #Repair rate in hours per year
    status::Vector{Bool}

    function Storages{N,L,T}(
        keys::Vector{Int}, buses::Vector{Int}, ps::Vector{Float32}, qs::Vector{Float32},
        energy::Vector{Float32}, energy_rating::Vector{Float32}, charge_rating::Vector{Float32}, 
        discharge_rating::Vector{Float32}, charge_efficiency::Vector{Float32}, 
        discharge_efficiency::Vector{Float32}, thermal_rating::Vector{Float32}, qmax::Vector{Float32}, 
        qmin::Vector{Float32}, r::Vector{Float32}, x::Vector{Float32}, ploss::Vector{Float32}, 
        qloss::Vector{Float32}, λ_updn::Vector{Float64}, μ_updn::Vector{Float64}, status::Vector{Bool}
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
        @assert length(λ_updn) == (nstors)
        @assert length(μ_updn) == (nstors)
        @assert length(status) == (nstors)
        @assert all(0 .<= energy)
        @assert all(0 .<= energy_rating)
        @assert all(0 .<= charge_rating)
        @assert all(0 .<= discharge_rating)
        @assert all(0 .<= charge_efficiency)
        @assert all(0 .<= discharge_efficiency)

        new{N,L,T}(Int.(keys), Int.(buses), Float32.(ps), Float32.(qs),
        Float32.(energy), Float32.(energy_rating), Float32.(charge_rating), 
        Float32.(discharge_rating), Float32.(charge_efficiency), Float32.(discharge_efficiency), 
        Float32.(thermal_rating), Float32.(qmax), Float32.(qmin), Float32.(r), 
        Float32.(x), Float32.(ploss), Float32.(qloss), Float64.(λ_updn), Float64.(μ_updn), Bool.(status))
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
    x.λ_updn == y.λ_updn &&
    x.μ_updn == y.μ_updn &&
    x.status == y.status
#

"Branches"
struct Branches <: AbstractAssets

    keys::Vector{Int}
    f_bus::Vector{Int} #buses_from
    t_bus::Vector{Int} #buses_to
    common_mode::Vector{Int}
    rate_a::Vector{Float32} #Long term rating or Rate_A
    rate_b::Vector{Float32} #Short term rating or Rate_B
    r::Vector{Float32} #Resistance values
    x::Vector{Float32} #Reactance values
    b_fr::Vector{Float32} #susceptance/2
    b_to::Vector{Float32} #susceptance/2
    g_fr::Vector{Float32}
    g_to::Vector{Float32}
    shift::Vector{Float32} #angle_shift
    angmin::Vector{Float32}
    angmax::Vector{Float32}
    transformer::Vector{Bool}
    tap::Vector{Float32} #tap_ratio
    λ_updn::Vector{Float64} #Failure rate in failures per year
    μ_updn::Vector{Float64} #Repair rate in hours per year
    status::Vector{Bool}

    function Branches(
        keys::Vector{Int}, f_bus::Vector{Int}, t_bus::Vector{Int}, common_mode::Vector{Int}, 
        rate_a::Vector{Float32}, rate_b::Vector{Float32}, r::Vector{Float32}, x::Vector{Float32}, 
        b_fr::Vector{Float32}, b_to::Vector{Float32}, g_fr::Vector{Float32}, g_to::Vector{Float32}, 
        shift::Vector{Float32}, angmin::Vector{Float32}, angmax::Vector{Float32}, transformer::Vector{Bool}, 
        tap::Vector{Float32}, λ_updn::Vector{Float64}, μ_updn::Vector{Float64}, status::Vector{Bool}
    )

        nbranches = length(keys)
        @assert allunique(keys)
        @assert length(f_bus) == (nbranches)
        @assert length(t_bus) == (nbranches)
        @assert length(common_mode) == (nbranches)
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
        @assert length(λ_updn) == (nbranches)
        @assert length(μ_updn) == (nbranches)
        @assert length(status) == (nbranches)
        @assert all(rate_a .>= 0)
        @assert all(rate_b .>= 0)
        @assert all(r .>= 0)
        @assert all(x .>= 0)

        new(
            Int.(keys), Int.(f_bus), Int.(t_bus), Int.(common_mode), Float32.(rate_a), Float32.(rate_b),
            Float32.(r), Float32.(x), Float32.(b_fr), Float32.(b_to), Float32.(g_fr), 
            Float32.(g_to), Float32.(shift), Float32.(angmin), Float32.(angmax),
            Bool.(transformer), Float32.(tap), Float64.(λ_updn), Float64.(μ_updn), Bool.(status))
    end

end

Base.:(==)(x::T, y::T) where {T <: Branches} =
    x.keys == y.keys &&
    x.f_bus == y.f_bus &&
    x.t_bus == y.t_bus &&
    x.common_mode == y.common_mode &&
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
    x.λ_updn == y.λ_updn &&
    x.μ_updn == y.μ_updn &&
    x.status == y.status
#

"Shunts"
struct Shunts <: AbstractAssets

    keys::Vector{Int}
    buses::Vector{Int}
    bs::Vector{Float32} # Active power withdrawn per voltage p.u.
    gs::Vector{Float32} # Reactive power withdrawn per voltage p.u.
    status::Vector{Bool}

    function Shunts(
        keys::Vector{Int}, buses::Vector{Int}, bs::Vector{Float32}, gs::Vector{Float32}, status::Vector{Bool}
    )

        nshunts = length(keys)
        @assert allunique(keys)
        @assert length(buses) == (nshunts)
        @assert length(bs) == (nshunts)
        @assert length(gs) == (nshunts)
        @assert length(status) == (nshunts)

        new(Int.(keys), Int.(buses), Float32.(bs), Float32.(gs), Bool.(status))
    end

end

Base.:(==)(x::T, y::T) where {T <: Shunts} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.bs == y.bs &&
    x.gs == y.gs &&
    x.status == y.status
#

struct CommonBranches <: AbstractAssets #Circuits on a common right-of-way or a common tower.

    keys::Vector{Int}
    f_bus::Vector{Int} #buses_from
    t_bus::Vector{Int} #buses_to
    λ_updn::Vector{Float64} #Failure rate in failures per year
    μ_updn::Vector{Float64} #Repair rate in hours per year

    function CommonBranches(
        keys::Vector{Int}, f_bus::Vector{Int}, t_bus::Vector{Int}, λ_updn::Vector{Float64}, μ_updn::Vector{Float64}
    )

        ncommonbranches = length(keys)
        @assert allunique(keys)
        @assert length(f_bus) == (ncommonbranches)
        @assert length(t_bus) == (ncommonbranches)
        @assert length(λ_updn) == (ncommonbranches)
        @assert length(μ_updn) == (ncommonbranches)
        new(Int.(keys), Int.(f_bus), Int.(t_bus), Float64.(λ_updn), Float64.(μ_updn))
    end

end

Base.:(==)(x::T, y::T) where {T <: CommonBranches} =
    x.keys == y.keys &&
    x.f_bus == y.f_bus &&
    x.t_bus == y.t_bus &&
    x.λ_updn == y.λ_updn &&
    x.μ_updn == y.μ_updn
#



# "GeneratorStorages"
# struct GeneratorStorages{N,L,T<:Period} <: TimeSeriesAssets{N,L,T}

#     keys::Vector{Int}
#     buses::Vector{Int}
#     ps::Vector{Float32}  # Active power in per unit
#     qs::Vector{Float32}
#     energy::Vector{Float32}
#     energy_rating::Vector{Float32} # energy_capacity
#     charge_rating::Vector{Float32}
#     discharge_rating::Vector{Float32}
#     charge_efficiency::Vector{Float32}
#     discharge_efficiency::Vector{Float32}

#     inflow::Matrix{Float32}
#     gridwithdrawal_rating::Matrix{Float32}
#     gridinjection_rating::Matrix{Float32}

#     λ_updn::Vector{Float64} #Failure rate in failures per year
#     μ_updn::Vector{Float64} #Repair rate in hours per year
#     status::Vector{Bool}
#     #carryover_efficiency::Vector{Float32}
#     #thermal_rating::Vector{Float32}
#     #qmax::Vector{Float32}
#     #qmin::Vector{Float32}
#     #r::Vector{Float32}
#     #x::Vector{Float32}
#     #ploss::Vector{Float32}
#     #qloss::Vector{Float32}

#     function GeneratorStorages{N,L,T}(
#         keys::Vector{Int}, buses::Vector{Int},
#         ps::Vector{Float32}, qs::Vector{Float32},
#         energy::Vector{Float32}, energy_rating::Vector{Float32},
#         charge_rating::Vector{Float32}, discharge_rating::Vector{Float32},
#         charge_efficiency::Vector{Float32}, discharge_efficiency::Vector{Float32},
#         inflow::Matrix{Float32}, gridwithdrawal_rating::Matrix{Float32}, 
#         gridinjection_rating::Matrix{Float32}, λ_updn::Vector{Float64}, 
#         μ_updn::Vector{Float64}, status::Vector{Bool}
#     ) where {N,L,T}

#         nstors = length(keys)
#         @assert allunique(keys)
#         @assert length(buses) == (nstors)
#         @assert length(ps) == (nstors)
#         @assert length(qs) == (nstors)
#         @assert length(energy) == (nstors)
#         @assert length(energy_rating) == (nstors)
#         @assert length(charge_rating) == (nstors)
#         @assert length(discharge_rating) == (nstors)
#         @assert size(inflow) == (nstors, N)
#         @assert size(gridwithdrawal_rating) == (nstors, N)
#         @assert size(gridinjection_rating) == (nstors, N)
#         @assert length(λ_updn) == (nstors)
#         @assert length(μ_updn) == (nstors)
#         @assert length(status) == (nstors)
#         @assert all(0 .<= energy)
#         @assert all(0 .<= energy_rating)
#         @assert all(0 .<= charge_rating)
#         @assert all(0 .<= discharge_rating)
#         @assert all(0 .<= charge_efficiency)
#         @assert all(0 .<= discharge_efficiency)

#         new{N,L,T}(Int.(keys), Int.(buses), Float32.(ps), Float32.(qs),
#         Float32.(energy), Float32.(energy_rating), Float32.(charge_rating),
#         Float32.(discharge_rating), Float32.(charge_efficiency), Float32.(discharge_efficiency),
#         inflow, gridwithdrawal_rating, gridinjection_rating, Float64.(λ_updn), Float64.(μ_updn), Bool.(status))
#     end
# end

# Base.:(==)(x::T, y::T) where {T <: GeneratorStorages} =
#     x.keys == y.keys &&
#     x.buses == y.buses &&
#     x.ps == y.ps &&
#     x.qs == y.qs &&
#     x.energy == y.energy &&
#     x.energy_rating == y.energy_rating &&
#     x.charge_rating == y.charge_rating &&
#     x.discharge_rating == y.discharge_rating &&
#     x.inflow == y.inflow &&
#     x.gridwithdrawal_capacity == y.gridwithdrawal_capacity &&
#     x.gridinjection_capacity == y.gridinjection_capacity &&
#     x.λ_updn == y.λ_updn &&
#     x.μ_updn == y.μ_updn &&
#     x.status == y.status
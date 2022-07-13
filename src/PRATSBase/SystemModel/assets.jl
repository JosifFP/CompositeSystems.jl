
abstract type AbstractAssets{N,L,T<:Period,P<:PowerUnit} end
Base.length(a::AbstractAssets) = length(a.keys)

struct Generators{N,L,T<:Period,P<:PowerUnit} <: AbstractAssets{N,L,T,P}

    keys::Vector{Int}
    buses::Vector{Int}
    categories::Vector{String}

    capacity::Matrix{Float16} # power

    λ::Vector{Float64}
    μ::Vector{Float64}

    function Generators{N,L,T,P}(
        keys::Vector{<:Int}, buses::Vector{<:Int}, categories::Vector{<:AbstractString},
        capacity::Matrix{Float16}, λ::Vector{Float64}, μ::Vector{Float64}
    ) where {N,L,T,P}

        n_gens = length(keys)
        @assert length(categories) == n_gens
        @assert allunique(keys)

        @assert size(capacity) == (n_gens, N)
        @assert all(capacity .>= 0)

        @assert length(λ) == (n_gens)
        @assert length(μ) == (n_gens)
        @assert all(0 .<= λ .<= 1)
        @assert all(0 .<= μ .<= 1)

        new{N,L,T,P}(Int.(keys), Int.(buses), string.(categories), capacity, λ, μ)

    end

end

Base.:(==)(x::T, y::T) where {T <: Generators} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.categories == y.categories &&
    x.capacity == y.capacity &&
    x.λ == y.λ &&
    x.μ == y.μ

Base.getindex(g::G, idxs::AbstractVector{Int}) where {G <: Generators} =
    G(g.keys[idxs], g.buses[idxs], g.categories[idxs],
      g.capacity[idxs, :], g.λ[idxs, :], g.μ[idxs, :])

function Base.vcat(gs::G...) where {N, L, T, P, G <: Generators{N,L,T,P}}

    n_gens = sum(length(g) for g in gs)
    keys = Vector{Int}(undef, n_gens)
    buses = Vector{Int}(undef, n_gens)
    categories = Vector{String}(undef, n_gens)
    capacity = Matrix{Int}(undef, n_gens, N)

    λ = Vector{Float64}(undef, n_gens)
    μ = Vector{Float64}(undef, n_gens)

    last_idx = 0

    for g in gs

        n = length(g)
        rows = last_idx .+ (1:n)

        keys[rows] = g.keys
        buses[rows] = g.buses
        categories[rows] = g.categories
        capacity[rows, :] = g.capacity
        λ[rows] = g.λ
        μ[rows] = g.μ

        last_idx += n

    end

    return Generators{N,L,T,P}(keys, buses, categories, capacity, λ, μ)

end

struct Loads{N,L,T<:Period,P<:PowerUnit} <: AbstractAssets{N,L,T,P}

    keys::Vector{Int}
    buses::Vector{Int}

    capacity::Matrix{Float16} # power

    function Loads{N,L,T,P}(
        keys::Vector{<:Int}, buses::Vector{<:Int}, capacity::Matrix{Float16}
    ) where {N,L,T,P}

        n_loads = length(keys)
        @assert length(buses) == n_loads
        @assert allunique(keys)

        @assert size(capacity) == (n_loads, N)
        @assert all(capacity .>= 0)

        new{N,L,T,P}(keys, buses, capacity)

    end

end

Base.:(==)(x::T, y::T) where {T <: Loads} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.capacity == y.capacity


struct Storages{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit} <: AbstractAssets{N,L,T,P}

    keys::Vector{Int}
    buses::Vector{Int}
    categories::Vector{String}

    charge_capacity::Matrix{Float16} # power
    discharge_capacity::Matrix{Float16} # power
    energy_capacity::Matrix{Float16} # energy

    charge_efficiency::Vector{Float64}
    discharge_efficiency::Vector{Float64}
    carryover_efficiency::Vector{Float64}

    λ::Vector{Float64}
    μ::Vector{Float64}

    function Storages{N,L,T,P,E}(
        keys::Vector{<:Int}, buses::Vector{<:Int}, categories::Vector{<:AbstractString},
        chargecapacity::Matrix{Float16}, discharge_capacity::Matrix{Float16},
        energycapacity::Matrix{Float16}, charge_efficiency::Vector{Float64},
        discharge_efficiency::Vector{Float64}, carryover_efficiency::Vector{Float64},
        λ::Vector{Float64}, μ::Vector{Float64}
    ) where {N,L,T,P,E}

        n_stors = length(keys)
        @assert length(categories) == n_stors
        @assert allunique(keys)

        @assert size(charge_capacity) == (n_stors, N)
        @assert size(discharge_capacity) == (n_stors, N)
        @assert size(energy_capacity) == (n_stors, N)
        @assert all(charge_capacity .>= 0)
        @assert all(discharge_capacity .>= 0)
        @assert all(energy_capacity .>= 0)

        @assert size(charge_efficiency) == (n_stors)
        @assert size(discharge_efficiency) == (n_stors)
        @assert size(carryover_efficiency) == (n_stors)
        @assert all(0 .< charge_efficiency .<= 1)
        @assert all(0 .< discharge_efficiency .<= 1)
        @assert all(0 .< carryover_efficiency .<= 1)

        @assert length(λ) == (n_stors)
        @assert length(μ) == (n_stors)
        @assert all(0 .<= λ .<= 1)
        @assert all(0 .<= μ .<= 1)

        new{N,L,T,P,E}(Int.(keys), Int.(buses), string.(categories),
                       charge_capacity, discharge_capacity, energy_capacity,
                       charge_efficiency, discharge_efficiency, carryover_efficiency,
                       λ, μ)

    end

end

Base.:(==)(x::T, y::T) where {T <: Storages} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.categories == y.categories &&
    x.charge_capacity == y.charge_capacity &&
    x.discharge_capacity == y.discharge_capacity &&
    x.energy_capacity == y.energy_capacity &&
    x.charge_efficiency == y.charge_efficiency &&
    x.discharge_efficiency == y.discharge_efficiency &&
    x.carryover_efficiency == y.carryover_efficiency &&
    x.λ == y.λ &&
    x.μ == y.μ


struct GeneratorStorages{N,L,T<:Period,P<:PowerUnit,E<:EnergyUnit} <: AbstractAssets{N,L,T,P}

    keys::Vector{Int}
    buses::Vector{Int}
    categories::Vector{String}

    charge_capacity::Matrix{Float16} # power
    discharge_capacity::Matrix{Float16} # power
    energy_capacity::Matrix{Float16} # energy

    charge_efficiency::Vector{Float64}
    discharge_efficiency::Vector{Float64}
    carryover_efficiency::Vector{Float64}

    inflow::Matrix{Int} # power
    gridwithdrawal_capacity::Matrix{Float16} # power
    gridinjection_capacity::Matrix{Float16} # power

    λ::Vector{Float64}
    μ::Vector{Float64}

    function GeneratorStorages{N,L,T,P,E}(
        keys::Vector{<:Int}, buses::Vector{<:Int}, categories::Vector{<:AbstractString},
        charge_capacity::Matrix{Float16}, discharge_capacity::Matrix{Float16},
        energy_capacity::Matrix{Float16},
        charge_efficiency::Vector{Float64}, discharge_efficiency::Vector{Float64},
        carryover_efficiency::Vector{Float64},
        inflow::Matrix{Int},
        gridwithdrawal_capacity::Matrix{Float16}, gridinjection_capacity::Matrix{Float16},
        λ::Vector{Float64}, μ::Vector{Float64}
    ) where {N,L,T,P,E}

        n_stors = length(keys)
        @assert length(categories) == n_stors
        @assert allunique(keys)

        @assert size(charge_capacity) == (n_stors, N)
        @assert size(discharge_capacity) == (n_stors, N)
        @assert size(energy_capacity) == (n_stors, N)

        @assert all(charge_capacity .>= 0)
        @assert all(discharge_capacity .>= 0)
        @assert all(energy_capacity .>= 0)

        @assert size(charge_efficiency) == (n_stors, N)
        @assert size(discharge_efficiency) == (n_stors, N)
        @assert size(carryover_efficiency) == (n_stors, N)

        @assert all(0 .< charge_efficiency .<= 1)
        @assert all(0 .< discharge_efficiency .<= 1)
        @assert all(0 .< carryover_efficiency .<= 1)

        @assert size(inflow) == (n_stors, N)
        @assert size(gridwithdrawal_capacity) == (n_stors, N)
        @assert size(gridinjection_capacity) == (n_stors, N)

        @assert all(inflow .>= 0)
        @assert all(gridwithdrawal_capacity .>= 0)
        @assert all(gridinjection_capacity .>= 0)

        @assert length(λ) == (n_stors)
        @assert length(μ) == (n_stors)
        @assert all(0 .<= λ .<= 1)
        @assert all(0 .<= μ .<= 1)

        new{N,L,T,P,E}(
            Int.(keys), Int.(buses), string.(categories),
            charge_capacity, discharge_capacity, energy_capacity,
            charge_efficiency, discharge_efficiency, carryover_efficiency,
            inflow, gridwithdrawal_capacity, gridinjection_capacity,
            λ, μ)

    end

end

Base.:(==)(x::T, y::T) where {T <: GeneratorStorages} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.categories == y.categories &&
    x.charge_capacity == y.charge_capacity &&
    x.discharge_capacity == y.discharge_capacity &&
    x.energy_capacity == y.energy_capacity &&
    x.charge_efficiency == y.charge_efficiency &&
    x.discharge_efficiency == y.discharge_efficiency &&
    x.carryover_efficiency == y.carryover_efficiency &&
    x.inflow == y.inflow &&
    x.gridwithdrawal_capacity == y.gridwithdrawal_capacity &&
    x.gridinjection_capacity == y.gridinjection_capacity &&
    x.λ == y.λ &&
    x.μ == y.μ


struct Branches{N,L,T<:Period,P<:PowerUnit} <: AbstractAssets{N,L,T,P}

    keys::Vector{Int}
    buses::Vector{Int}
    categories::Vector{String}

    buses_from::Vector{Int}
    buses_to::Vector{Int}

    forward_capacity::Matrix{Float16} # power
    backward_capacity::Matrix{Float16} # power

    λ::Vector{Float64}
    μ::Vector{Float64}

    function Branches{N,L,T,P}(
        keys::Vector{<:Int}, buses::Vector{<:Int}, categories::Vector{<:AbstractString},
        buses_from::Vector{Int}, buses_to::Vector{Int},
        forward_capacity::Matrix{Float16}, backward_capacity::Matrix{Float16},
        λ::Vector{Float64}, μ::Vector{Float64}
    ) where {N,L,T,P}

        n_branches = length(keys)
        @assert length(categories) == n_branches
        @assert allunique(keys)

        @assert size(forward_capacity) == (n_branches, N)
        @assert size(backward_capacity) == (n_branches, N)
        @assert all(forward_capacity .>= 0)
        @assert all(backward_capacity .>= 0)

        @assert length(λ) == (n_branches)
        @assert length(μ) == (n_branches)
        @assert all(0 .<= λ .<= 1)
        @assert all(0 .<= μ .<= 1)

        new{N,L,T,P}(Int.(keys), Int.(buses), string.(categories), buses_from, buses_to, forward_capacity, backward_capacity, λ, μ)

    end

end

Base.:(==)(x::T, y::T) where {T <: Branches} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.categories == y.categories &&
    x.buses_from == y.buses_from &&
    x.buses_to == y.buses_to &&
    x.forward_capacity == y.forward_capacity &&
    x.backward_capacity == y.backward_capacity &&
    x.λ == y.λ &&
    x.μ == y.μ


#Collection Types

struct Buses{N,P<:PowerUnit}

    names::Vector{String}
    buses_i::Vector{Int}
    load::Matrix{Int}

    function Buses{N,P}(
        names::Vector{<:AbstractString}, load::Matrix{Int}
    ) where {N,P<:PowerUnit}

        n_buses = length(names)

        @assert size(load) == (n_buses, N)
        @assert all(load .>= 0)

        new{N,P}(string.(names), Int.(buses_i), load)

    end

end

Base.:(==)(x::T, y::T) where {T <: Buses} =
    x.names == y.names &&
    x.buses_i == y.buses_i &&
    x.load == y.load

Base.length(r::Buses) = length(r.names)

abstract type AbstractAssets{N,L,T<:Period,U<:PerUnit} end
Base.length(a::AbstractAssets) = length(a.keys)

struct Generators{N,L,T<:Period,U<:PerUnit} <: AbstractAssets{N,L,T,U}

    keys::Vector{Int}
    buses::Vector{Int}
    pg::Matrix{Float16}  # Active power in per unit
    λ::Vector{Float32} #Failure rate in failures per year
    μ::Vector{Float32} #Repair rate in hours per year

    function Generators{N,L,T,U}(
        keys::Vector{<:Int}, buses::Vector{<:Int}, 
        pg::Matrix{Float16}, λ::Vector{Float32}, μ::Vector{Float32}
    ) where {N,L,T,U}

        n_gens = length(keys)
        @assert allunique(keys)
        @assert size(pg) == (n_gens, N)
        @assert all(pg .>= 0)
        @assert length(λ) == (n_gens)
        @assert length(μ) == (n_gens)
        #@assert all(0 .<= λ .<= 1)
        #@assert all(0 .<= μ .<= 1)

        new{N,L,T,U}(Int.(keys), Int.(buses), pg, λ, μ)

    end

end

Base.:(==)(x::T, y::T) where {T <: Generators} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.pg == y.pg &&
    x.λ == y.λ &&
    x.μ == y.μ

function Base.vcat(gs::G...) where {N, L, T, U, G <: Generators{N,L,T,U}}

    n_gens = sum(length(g) for g in gs)
    keys = Vector{Int}(undef, n_gens)
    buses = Vector{Int}(undef, n_gens)
    pg = Matrix{Int}(undef, n_gens, N)
    λ = Vector{Float32}(undef, n_gens)
    μ = Vector{Float32}(undef, n_gens)

    last_idx = 0

    for g in gs

        n = length(g)
        rows = last_idx .+ (1:n)

        keys[rows] = g.keys
        buses[rows] = g.buses
        pg[rows, :] = g.pg
        λ[rows] = g.λ
        μ[rows] = g.μ
        last_idx += n

    end

    return Generators{N,L,T,U}(keys, buses, pg, λ, μ)

end

struct Loads{N,L,T<:Period,U<:PerUnit} <: AbstractAssets{N,L,T,U}

    keys::Vector{Int}
    buses::Vector{Int}
    pd::Matrix{Float16} # Active power in per unit
    #qd::Matrix{Float16} # Reactive power in per unit

    function Loads{N,L,T,U}(
        keys::Vector{<:Int}, buses::Vector{<:Int}, pd::Matrix{Float16}, #qd::Matrix{Float16}
    ) where {N,L,T,U}

        n_loads = length(keys)
        @assert length(buses) == n_loads
        @assert allunique(keys)

        @assert size(pd) == (n_loads, N)
        #@assert size(qd) == (n_loads, N)
        @assert all(pd .>= 0)

        new{N,L,T,U}(keys, buses, pd)

    end

end

Base.:(==)(x::T, y::T) where {T <: Loads} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.pd == y.pd


struct Storages{N,L,T<:Period,U<:PerUnit} <: AbstractAssets{N,L,T,U}

    keys::Vector{Int}
    buses::Vector{Int}
    energy_rating::Matrix{Float16} # energy_capacity
    carryover_efficiency::Vector{Float32}

    λ::Vector{Float32} #Failure rate in failures per year
    μ::Vector{Float32} #Repair rate in hours per year

    function Storages{N,L,T,U}(
        keys::Vector{<:Int}, buses::Vector{<:Int},
        energy_rating::Matrix{Float16}, carryover_efficiency::Vector{Float32},
        λ::Vector{Float32}, μ::Vector{Float32}
    ) where {N,L,T,U}

        n_stors = length(keys)
        @assert allunique(keys)
        @assert size(energy_rating) == (n_stors, N)
        @assert all(energy_rating .>= 0)
        @assert length(carryover_efficiency) == n_stors
        @assert length(λ) == (n_stors)
        @assert length(μ) == (n_stors)
        #@assert all(0 .<= λ .<= 1)
        #@assert all(0 .<= μ .<= 1)

        new{N,L,T,U}(Int.(keys), Int.(buses), energy_rating, carryover_efficiency, λ, μ)

    end

end

Base.:(==)(x::T, y::T) where {T <: Storages} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.energy_rating == y.energy_rating &&
    x.carryover_efficiency == y.carryover_efficiency &&
    x.λ == y.λ &&
    x.μ == y.μ


struct GeneratorStorages{N,L,T<:Period,U<:PerUnit} <: AbstractAssets{N,L,T,U}

    keys::Vector{Int}
    buses::Vector{Int}
    energy_rating::Matrix{Float16} # energy
    carryover_efficiency::Vector{Float32}

    inflow::Matrix{Int} # power
    gridwithdrawal_rating::Matrix{Float16} # power
    gridinjection_rating::Matrix{Float16} # power

    λ::Vector{Float32} #Failure rate in failures per year
    μ::Vector{Float32} #Repair rate in hours per year

    function GeneratorStorages{N,L,T,U}(
        keys::Vector{<:Int}, buses::Vector{<:Int}, energy_rating::Matrix{Float16},
        carryover_efficiency::Vector{Float32}, inflow::Matrix{Int},
        gridwithdrawal_rating::Matrix{Float16}, gridinjection_rating::Matrix{Float16},
        λ::Vector{Float32}, μ::Vector{Float32}
    ) where {N,L,T,U}

        n_stors = length(keys)
        @assert allunique(keys)
        @assert size(energy_rating) == (n_stors, N)
        @assert all(energy_rating .>= 0)
        @assert length(carryover_efficiency) == n_stors
        @assert all(0 .< carryover_efficiency .<= 1)

        @assert size(inflow) == (n_stors, N)
        @assert size(gridwithdrawal_rating) == (n_stors, N)
        @assert size(gridinjection_rating) == (n_stors, N)

        @assert all(inflow .>= 0)
        @assert all(gridwithdrawal_rating .>= 0)
        @assert all(gridinjection_rating .>= 0)

        @assert length(λ) == (n_stors)
        @assert length(μ) == (n_stors)
        #@assert all(0 .<= λ .<= 1)
        #@assert all(0 .<= μ .<= 1)

        new{N,L,T,U}(
            Int.(keys), Int.(buses), energy_rating, carryover_efficiency,
            inflow, gridwithdrawal_rating, gridinjection_rating, λ, μ)

    end

end

Base.:(==)(x::T, y::T) where {T <: GeneratorStorages} =
    x.keys == y.keys &&
    x.buses == y.buses &&
    x.energy_rating == y.energy_rating &&
    x.carryover_efficiency == y.carryover_efficiency &&
    x.inflow == y.inflow &&
    x.gridwithdrawal_rating == y.gridwithdrawal_rating &&
    x.gridinjection_rating == y.gridinjection_rating &&
    x.λ == y.λ &&
    x.μ == y.μ


struct Branches{N,L,T<:Period,U<:PerUnit} <: AbstractAssets{N,L,T,U}

    keys::Vector{Int}

    buses_from::Vector{Int}
    buses_to::Vector{Int}

    longterm_rating::Matrix{Float16} #Long term rating or Rate_A
    shortterm_rating::Matrix{Float16} #Short term rating or Rate_B

    λ::Vector{Float32} #Failure rate in failures per year
    μ::Vector{Float32} #Repair rate in hours per year

    function Branches{N,L,T,U}(
        keys::Vector{<:Int},
        buses_from::Vector{<:Int}, buses_to::Vector{<:Int},
        longterm_rating::Matrix{Float16}, shortterm_rating::Matrix{Float16},
        λ::Vector{Float32}, μ::Vector{Float32}
    ) where {N,L,T,U}

        n_branches = length(keys)
        @assert allunique(keys)

        @assert size(longterm_rating) == (n_branches, N)
        @assert size(shortterm_rating) == (n_branches, N)
        @assert all(longterm_rating .>= 0)
        @assert all(shortterm_rating .>= 0)
        @assert length(λ) == (n_branches)
        @assert length(μ) == (n_branches)

        new{N,L,T,U}(Int.(keys), Int.(buses_from), Int.(buses_to), longterm_rating, shortterm_rating, λ, μ)
    end

end

Base.:(==)(x::T, y::T) where {T <: Branches} =
    x.keys == y.keys &&
    x.buses_from == y.buses_from &&
    x.buses_to == y.buses_to &&
    x.longterm_rating == y.longterm_rating &&
    x.shortterm_rating == y.shortterm_rating &&
    x.λ == y.λ &&
    x.μ == y.μ


#Collection Types

struct Network{N,L,T<:Period,U<:PerUnit}

    areas::Dict{Int,<:Any}
    bus::Dict{Int,<:Any}
    dcline::Dict{Int,<:Any}
    gen::Dict{Int,<:Any}
    branch::Dict{Int,<:Any}
    storage::Dict{Int,<:Any}
    switch::Dict{Int,<:Any}
    shunt::Dict{Int,<:Any}
    load::Dict{Int,<:Any}
    baseMVA::Int
    per_unit::Bool

    function Network{N,L,T,U}(data::Dict{Symbol,<:Any}) where {N,L,T,U}

        areas = data[:areas]
        bus = data[:bus]
        dcline = data[:dcline]
        gen = data[:gen]
        branch = data[:branch]
        storage = data[:storage]
        switch = data[:switch]
        shunt = data[:shunt]
        load = data[:load]
        baseMVA = data[:baseMVA]
        per_unit = data[:per_unit]

        @assert isempty(areas) == false
        @assert isempty(bus) == false
        @assert isempty(gen) == false
        @assert isempty(branch) == false
        @assert isempty(load) == false
        @assert isempty(baseMVA) == false
        @assert isempty(per_unit) == false

        return new(areas, bus, dcline, gen, branch, storage, switch, shunt, load, baseMVA, per_unit)

    end

end

Base.:(==)(x::T, y::T) where {T <: Network} =
    x.areas == y.areas &&
    x.bus == y.bus &&
    x.dcline == y.dcline &&
    x.gen == y.gen &&
    x.branch == y.branch &&
    x.storage == y.storage &&
    x.switch == y.switch &&
    x.shunt == y.shunt &&
    x.load == y.load &&
    x.baseMVA == y.baseMVA &&
    x.per_unit == y.per_unit
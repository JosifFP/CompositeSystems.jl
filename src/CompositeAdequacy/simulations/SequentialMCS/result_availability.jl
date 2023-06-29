
"GeneratorAvailability"
struct SMCSGenAvailabilityAccumulator <: ResultAccumulator{SequentialMCS,GeneratorAvailability}
    available::Array{Bool,3}
end

""
function merge!(x::SMCSGenAvailabilityAccumulator, y::SMCSGenAvailabilityAccumulator)
    x.available .|= y.available
    return
end

accumulatortype(::SequentialMCS, ::GeneratorAvailability) = SMCSGenAvailabilityAccumulator

""
function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::GeneratorAvailability) where {N}
    ngens = length(sys.generators)
    available = zeros(Bool, ngens, N, simspec.nsamples)
    return SMCSGenAvailabilityAccumulator(available)
end

""
function record!(acc::SMCSGenAvailabilityAccumulator, pm::AbstractPowerModel, states::States, system::SystemModel, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= states.generators_available[:]
    return
end

reset!(acc::SMCSGenAvailabilityAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCSGenAvailabilityAccumulator, system::SystemModel{N,L,T}) where {N,L,T}
    return GeneratorAvailabilityResult{N,L,T}(field(system, :generators, :keys), field(system, :timestamps), acc.available)
end

"StorageAvailability"
struct SMCSStorAvailabilityAccumulator <: ResultAccumulator{SequentialMCS,StorageAvailability}
    available::Array{Bool,3}
end

""
function merge!(x::SMCSStorAvailabilityAccumulator, y::SMCSStorAvailabilityAccumulator)
    x.available .|= y.available
    return
end

accumulatortype(::SequentialMCS, ::StorageAvailability) = SMCSStorAvailabilityAccumulator

""
function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::StorageAvailability) where {N}
    nstors = length(sys.storages)
    available = zeros(Bool, nstors, N, simspec.nsamples)
    return SMCSStorAvailabilityAccumulator(available)
end

""
function record!(acc::SMCSStorAvailabilityAccumulator, pm::AbstractPowerModel, states::States, system::SystemModel, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= states.storages_available[:]
    return
end

reset!(acc::SMCSStorAvailabilityAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCSStorAvailabilityAccumulator, system::SystemModel{N,L,T}) where {N,L,T}
    return StorageAvailabilityResult{N,L,T}(field(system, :storages, :keys), field(system, :timestamps), acc.available)
end

"BranchAvailability"
struct SMCSBranchAvailabilityAccumulator <: ResultAccumulator{SequentialMCS,BranchAvailability}
    available::Array{Bool,3}
end

""
function merge!(x::SMCSBranchAvailabilityAccumulator, y::SMCSBranchAvailabilityAccumulator)
    x.available .|= y.available
    return
end

accumulatortype(::SequentialMCS, ::BranchAvailability) = SMCSBranchAvailabilityAccumulator

""
function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::BranchAvailability) where {N}
    nbranches = length(sys.branches)
    available = zeros(Bool, nbranches, N, simspec.nsamples)
    return SMCSBranchAvailabilityAccumulator(available)
end

""
function record!(acc::SMCSBranchAvailabilityAccumulator, pm::AbstractPowerModel, states::States, system::SystemModel, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= states.branches_available[:]
    return
end

reset!(acc::SMCSBranchAvailabilityAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCSBranchAvailabilityAccumulator,system::SystemModel{N,L,T}) where {N,L,T}
    return BranchAvailabilityResult{N,L,T}(field(system, :branches, :keys), field(system, :timestamps), acc.available)
end


"ShuntAvailability"
struct SMCSShuntAvailabilityAccumulator <: ResultAccumulator{SequentialMCS,ShuntAvailability}
    available::Array{Bool,3}
end

""
function merge!(x::SMCSShuntAvailabilityAccumulator, y::SMCSShuntAvailabilityAccumulator)
    x.available .|= y.available
    return
end

accumulatortype(::SequentialMCS, ::ShuntAvailability) = SMCSShuntAvailabilityAccumulator

""
function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::ShuntAvailability) where {N}
    nshunts = length(sys.shunts)
    available = zeros(Bool, nshunts, N, simspec.nsamples)
    return SMCSShuntAvailabilityAccumulator(available)
end

""
function record!(acc::SMCSShuntAvailabilityAccumulator, pm::AbstractPowerModel, states::States, system::SystemModel, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= states.shunts_available[:]
    return
end

reset!(acc::SMCSShuntAvailabilityAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCSShuntAvailabilityAccumulator,system::SystemModel{N,L,T}) where {N,L,T}
    return ShuntAvailabilityResult{N,L,T}(field(system, :shunts, :keys), field(system, :timestamps), acc.available)
end

# "BusAvailability"
# struct SMCSBusAvailabilityAccumulator <: ResultAccumulator{SequentialMCS,BusAvailability}
#     available::Array{Bool,3}
# end

# ""
# function merge!(x::SMCSBusAvailabilityAccumulator, y::SMCSBusAvailabilityAccumulator)
#     x.available .|= y.available
#     return
# end

# accumulatortype(::SequentialMCS, ::BusAvailability) = SMCSBusAvailabilityAccumulator

# ""
# function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::BusAvailability) where {N}
#     nbuses = length(sys.buses)
#     available = zeros(Bool, nbuses, N, simspec.nsamples)
#     return SMCSBusAvailabilityAccumulator(available)
# end

# ""
# function record!(acc::SMCSBusAvailabilityAccumulator, pm::AbstractPowerModel, system::SystemModel, states::States, sampleid::Int, t::Int)
#     acc.available[:, t, sampleid] .= states.buses_available
#     return
# end

# reset!(acc::SMCSBusAvailabilityAccumulator, sampleid::Int) = nothing

# ""
# function finalize(acc::SMCSBusAvailabilityAccumulator,system::SystemModel{N,L,T}) where {N,L,T}
#     return BusAvailabilityResult{N,L,T}(field(system, :buses, :keys), field(system, :timestamps), acc.available)
# end
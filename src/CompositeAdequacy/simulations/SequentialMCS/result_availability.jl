
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
function record!(acc::SMCSGenAvailabilityAccumulator, states::SystemStates, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= view(field(states, :generators), :, t)
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
function record!(acc::SMCSStorAvailabilityAccumulator, states::SystemStates, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= view(field(states, :storages), :, t)
    return
end

reset!(acc::SMCSStorAvailabilityAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCSStorAvailabilityAccumulator, system::SystemModel{N,L,T}) where {N,L,T}
    return StorageAvailabilityResult{N,L,T}(field(system, :storages, :keys), field(system, :timestamps), acc.available)
end

"GeneratorStorageAvailability"
struct SMCSGenStorAvailabilityAccumulator <: ResultAccumulator{SequentialMCS,GeneratorStorageAvailability}
    available::Array{Bool,3}
end

""
function merge!(x::SMCSGenStorAvailabilityAccumulator, y::SMCSGenStorAvailabilityAccumulator)
    x.available .|= y.available
    return
end

accumulatortype(::SequentialMCS, ::GeneratorStorageAvailability) = SMCSGenStorAvailabilityAccumulator

""
function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::GeneratorStorageAvailability) where {N}
    ngenstors = length(sys.generatorstorages)
    available = zeros(Bool, ngenstors, N, simspec.nsamples)
    return SMCSGenStorAvailabilityAccumulator(available)
end

""
function record!(acc::SMCSGenStorAvailabilityAccumulator, states::SystemStates, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= view(field(states, :generatorstorages), :, t)
    return

end

reset!(acc::SMCSGenStorAvailabilityAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCSGenStorAvailabilityAccumulator, system::SystemModel{N,L,T}) where {N,L,T}
    return GeneratorStorageAvailabilityResult{N,L,T}(field(system, :generatorstorages, :keys), field(system, :timestamps), acc.available)
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
function record!(acc::SMCSBranchAvailabilityAccumulator, states::SystemStates, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= view(field(states, :branches), :, t)
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
function record!(acc::SMCSShuntAvailabilityAccumulator, states::SystemStates, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= view(field(states, :shunts), :, t)
    return
end

reset!(acc::SMCSShuntAvailabilityAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCSShuntAvailabilityAccumulator,system::SystemModel{N,L,T}) where {N,L,T}
    return ShuntAvailabilityResult{N,L,T}(field(system, :shunts, :keys), field(system, :timestamps), acc.available)
end

"BusAvailability"
struct SMCSBusAvailabilityAccumulator <: ResultAccumulator{SequentialMCS,BusAvailability}
    available::Array{Bool,3}
end

""
function merge!(x::SMCSBusAvailabilityAccumulator, y::SMCSBusAvailabilityAccumulator)
    x.available .|= y.available
    return
end

accumulatortype(::SequentialMCS, ::BusAvailability) = SMCSBusAvailabilityAccumulator

""
function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::BusAvailability) where {N}
    nbuses = length(sys.buses)
    available = zeros(Bool, nbuses, N, simspec.nsamples)
    return SMCSBusAvailabilityAccumulator(available)
end

""
function record!(acc::SMCSBusAvailabilityAccumulator, states::SystemStates, sampleid::Int, t::Int)
    acc.available[:, t, sampleid] .= view(field(states, :buses), :, t)
    return
end

reset!(acc::SMCSBusAvailabilityAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCSBusAvailabilityAccumulator,system::SystemModel{N,L,T}) where {N,L,T}
    return BusAvailabilityResult{N,L,T}(field(system, :buses, :keys), field(system, :timestamps), acc.available)
end
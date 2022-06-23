using PRATS, Plots
import BenchmarkTools: @btime
include("testsystems/testsystems.jl")
using PRATS.CompositeAdequacy

system =  TestSystems.singlenode_stor
simspec = PRATS.SequentialMonteCarlo(samples=100_000)#, seed=1)
resultspecs = (Shortfall(), ShortfallSamples())
threads = 1
sampleseeds = Channel{Int}(2)
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)  # feed the sampleseeds channel with #N samples.
dispatchproblem = CompositeAdequacy.DispatchProblem(system)
systemstate = CompositeAdequacy.SystemState(system)
recorders = CompositeAdequacy.accumulator.(system, simspec, resultspecs)

# initialize_availability!(rng, sequences.Up_gens, system.generators, N)
# initialize_availability!(rng, sequences.Up_stors, system.storages, N)
# initialize_availability!(rng, sequences.Up_genstors, system.generatorstorages, N)
# initialize_availability!(rng, sequences.Up_lines, system.lines, N)

rng = CompositeAdequacy.Philox4x((0, 0), 10)
N = 10000000
devices = system.generators
ndevices = Base.length(devices)

@inbounds availability = ones(Bool, ndevices, N)::Matrix{Bool}
for i in 1:ndevices
    λ = 0.1
    μ = 0.9
    if λ != 0.0
        availability[i,:] = cycles_1!(rng, λ, μ, N)
    end
end

availability
# plot(1:N,availability[1,:])
# plot!(1:N,availability[2,:])
# plot!(1:N,availability[3,:])

using Statistics
1/((1/0.1)-(1/0.9))

Statistics.mean(availability)
#0.893-0.9


#-----------------------------------------------------------------------------------------------
using PRATS, Plots
import BenchmarkTools: @btime
include("testsystems/testsystems.jl")
using PRATS.CompositeAdequacy
λ = 1/3000
μ = 1/60
threads = 1
sampleseeds = Channel{Int}(2)
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)  # feed the sampleseeds channel with #N samples.
rng = CompositeAdequacy.Philox4x((0, 0), 10)
N = 8760


sequence = Base.ones(true, N)
i=Int(0)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)
(ttf,ttr) = T(rng,λ,μ)

i=Int(0)
sequence = Base.ones(true, N)
(ttf,ttr) = (8750, 111)
if i + ttf > N - ttr && i + ttf < N ttr = N - ttf - i end
(ttf,ttr)

@inbounds while i + ttf + ttr  <= N
    sequence[i+ttf+1 : i+ttf+ttr] = [false for _ in i+ttf+1 : i+ttf+ttr]
    i = i + ttf + ttr
    (ttf,ttr) = T(rng,λ,μ)
    if i + ttf + ttr  >= N && i + ttf < N 
        ttr = N - ttf - i
        println("HERE HERE HERE HERE HERE HERE HERE")
    end
end;

#println(sequence)
plot(1:N,sequence[1,:])


#-----------------------------------------------------------------------------------------------
function cycles_1!(rng, λ::Float64, μ::Float64, N::Int)
    sequence = Base.ones(true, N)
    i=Int(0)
    (ttf,ttr) = T(rng,λ,μ)
    if i + ttf > N - ttr && i + ttf < N ttr = N - ttf - i end

    @inbounds while i + ttf + ttr  <= N
        sequence[i+ttf+1 : i+ttf+ttr] = [false for _ in i+ttf+1 : i+ttf+ttr]
        i = i + ttf + ttr
        (ttf,ttr) = T(rng,λ,μ)
        if i + ttf + ttr  >= N && i + ttf < N ttr = N - ttf - i end
    end
    return sequence
end

function T(rng, λ::Float64, μ::Float64)::Tuple{Int32,Int32}
    
    ttf = (x->trunc(Int32, x)).((-1/λ)log(rand(rng)))
    ttr = (y->trunc(Int32, y)).((-1/μ)log(rand(rng)))

    while ttf == 0.0 || ttr == 0.0
        ttf = (x->trunc(Int32, x)).((-1/λ)log(rand(rng)))
        ttr = (y->trunc(Int32, y)).((-1/μ)log(rand(rng)))
    end

    return ttf,ttr
end



function cycles_2!(rng, λ::Float64, μ::Float64, N::Int)
    sequence = Base.ones(true, N)
    for i in 1:N
        online = rand(rng) < μ / (λ + μ)
        sequence[i] = online
    end
    return sequence
end

@inbounds availability = ones(Bool, ndevices, N)::Matrix{Bool}
for i in 1:ndevices
    λ = 0.1
    μ = 0.9
    if λ != 0.0
        availability[i,:] = cycles_2!(rng, λ, μ, N)
    end
end

availability
plot(1:N,availability[1,:])
plot!(1:N,availability[2,:])
plot!(1:N,availability[3,:])

using Statistics
Statistics.mean(availability)
#0.9
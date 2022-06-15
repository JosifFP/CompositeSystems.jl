using PRATS
using Test
using PRATS.CompositeAdequacy
import BenchmarkTools: @btime
import PRATS.CompositeAdequacy: Philox4x, seed!, ResultSpec, ResultAccumulator, 
Random, randtransitiontime, initialize!, initialize_availability!, advance!, update_availability!
import Random: AbstractRNG, GLOBAL_RNG, MersenneTwister, rand
include("testsystems/testsystems.jl")

system =  TestSystems.singlenode_a
simspec = SequentialMonteCarlo(samples=1, seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())
threads = 1
sampleseeds = Channel{Int}(2)
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)  # feed the sampleseeds channel with #N samples.
#xassess(system, simspec, sampleseeds, results, resultspecs...)
#shortfalls, flows = CompositeAdequacy.finalize(results, system)
#eue = EUE(shortfalls)


function xassess(
    system::SystemModel{N},  simspec::SequentialMonteCarlo,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMonteCarlo}}}},
    resultspecs::ResultSpec...
) where {R<:ResultSpec, N}

    dispatchproblem = CompositeAdequacy.DispatchProblem(system)
    systemstate = CompositeAdequacy.SystemState(system)
    recorders = CompositeAdequacy.accumulator.(system, simspec, resultspecs)

    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        CompositeAdequacy.seed!(rng, (simspec.seed, s))  #using the same seed for entire period.
        CompositeAdequacy.initialize!(rng, systemstate, system)

        for t in 1:N

            CompositeAdequacy.advance!(rng, systemstate, dispatchproblem, system, t)
            CompositeAdequacy.solve!(dispatchproblem, systemstate, system, t)
            CompositeAdequacy.foreach(recorder -> CompositeAdequacy.record!(
                        recorder, system, systemstate, dispatchproblem, s, t
                    ), recorders)

        end

        CompositeAdequacy.foreach(recorder -> CompositeAdequacy.reset!(recorder, s), recorders)

    end
    put!(results, recorders)
end

#----------------------------------------------------------------------------------------------------------------------------------


dispatchproblem = DispatchProblem(system)
systemstate = SystemState(system)
recorders = accumulator.(system, simspec, resultspecs)
initialize!(rng, systemstate, system)
record = Dict{Int, Any}()
get!(record,1, systemstate)


rng = GLOBAL_RNG
N = length(system.timestamps)
t = 1
advance!(rng, systemstate, dispatchproblem, system, t)
get!(record,t+1, systemstate)

t = 2
advance!(rng, systemstate, dispatchproblem, system, t)
get!(record,t+1, systemstate)

t = 3
advance!(rng, systemstate, dispatchproblem, system, t)
get!(record,t+1, systemstate)

t = 4
advance!(rng, systemstate, dispatchproblem, system, t)
get!(record,t+1, systemstate)

record



availability = systemstate.gens_available
#availability = [true,true, true, true]
nexttransition = systemstate.gens_nexttransition
devices = system.generators
t_last = nperiods
t_now = 1

length(devices)

for i in 1:length(devices)
    λ = devices.λ[i, 1]
    μ = devices.μ[i, 1]
    online = rand(rng) < μ / (λ + μ)
    availability[i] = online
    transitionprobs = online ? devices.λ : devices.μ
    nexttransition[i] = randtransitiontime(rng, transitionprobs, i, 1, t_last)
end
availability
nexttransition

i=1
λ = devices.λ[i, 1]
μ = devices.μ[i, 1]
randx = rand(rng)
A = λ / (λ + μ)
online = randx < μ / (λ + μ)
availability[i] = online
transitionprobs = online ? devices.λ : devices.μ
nexttransition[i] = randtransitiontime(rng, transitionprobs, i, 1, t_last)




transitionprobs = (availability[i] ⊻= true) ? devices.λ : devices.μ
nexttransition[i] = randtransitiontime(rng, transitionprobs, i, t_now, t_last)


t_now = 3
for i in 1:length(devices)
    if nexttransition[i] == t_now # Unit switches states
        transitionprobs = (availability[i] ⊻= true) ? devices.λ : devices.μ
        nexttransition[i] = randtransitiontime(
            rng, transitionprobs, i, t_now, t_last)
    end
end
availability
nexttransition
devices.λ

#------------------------------------------------------------------------------------------

N = length(system.timestamps)
ndevices = length(devices)

Random.seed!(simspec.seed)
@inbounds availability = ones(Bool, ndevices, N)::Matrix{Bool}
for k in 1:ndevices
    λ = devices.λ[k, 1]
    μ = devices.μ[k, 1]
    if λ != 0.0
        availability[k,:] = cycles!(λ, μ, availability[k,:])
        println(availability[k,:])
    end
end



function cycles!(
    λ::Float64, μ::Float64, vector::Vector{Bool})

    (ttf,ttr) = T(λ,μ)
    N = length(vector)
    i=Int(2);
    @inbounds while i + ttf + ttr  < N
        @inbounds vector[i+ttf : i+ttf+ttr] = [false for _ in i+ttf : i+ttf+ttr]
        #@inbounds vector[i+ttf : i+ttf+ttr] = zeros(Bool, ttr)
        i = i + ttf + ttr
        (ttf,ttr) = T(λ,μ)
    end

    return vector
    
end
import Distributions: DiscreteNonParametric, probs, support, Exponential

import PRATS.CompositeAdequacy
system =  TestSystems.singlenode_a;
simspec = PRATS.SequentialMonteCarlo(samples=1_000);
resultspecs = (PRATS.Shortfall(),PRATS.GeneratorAvailability());
threads = 1;
sampleseeds = Channel{Int}(2);
simspec.nsamples;
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads);
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples);  # feed the sampleseeds channel with #N samples.
dispatchproblem = DispatchProblem(system);


systemstate = SystemState(system)
recorders = accumulator.(system, simspec, resultspecs);
rng = CompositeAdequacy.Philox4x((0, 0), 10)
sequences = CompositeAdequacy.initialize!(rng, systemstate, system)

systemstate

t = 1
CompositeAdequacy.advance!(sequences[:,t:t+1,:], systemstate, dispatchproblem, system, t)
systemstate

t = 2
CompositeAdequacy.advance!(sequences[:,t:t+1,:], systemstate, dispatchproblem, system, t)
systemstate

t = 3
CompositeAdequacy.advance!(sequences[:,t:t+1,:], systemstate, dispatchproblem, system, t)
systemstate

t = 4
CompositeAdequacy.advance!(sequences[:,t,:], systemstate, dispatchproblem, system, t)
systemstate
using Distributions
using PRATS
using Base.Threads


loadfile = "test/data/rts_Load.xlsx"
system = PRATS.SystemModel(loadfile);
simspec = SequentialMonteCarlo(samples=1,seed=1, threaded=false)
method = simspec
resultspecs = (Shortfall(), Surplus())

#SequentialMonteCarlo.jl
threads = nthreads()
sampleseeds = Channel{Int}(2*threads)
results = PRATS.resultchannel(method, resultspecs, threads)
Threads.@spawn makeseeds(sampleseeds, method.nsamples)

if method.threaded
    for _ in 1:threads
        println(_)
    #    @spawn assess(system, method, sampleseeds, results, resultspecs...)
    end
else
    #assess(system, method, sampleseeds, results, resultspecs...)
end

function makeseeds(sampleseeds::Channel{Int}, nsamples::Int)
    for s in 1:nsamples
        put!(sampleseeds, s)
    end
    close(sampleseeds)
end
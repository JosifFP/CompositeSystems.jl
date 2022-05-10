using Distributions
using PRATS


loadfile = "test/data/rts_Load.xlsx"
system = PRATS.SystemModel(loadfile);
simspec = SequentialMonteCarlo(samples=1,seed=1, threaded=false)
resultspecs = (Shortfall(), Surplus())

#SequentialMonteCarlo.jl
threads = 1
sampleseeds = Channel{Int}(2*threads)
results = resultchannel(method, resultspecs, threads)

resultspecs = (Shortfall(), Surplus())


function makeseeds(sampleseeds::Channel{Int}, nsamples::Int)

    for s in 1:nsamples
        put!(sampleseeds, s)
    end

    close(sampleseeds)

end
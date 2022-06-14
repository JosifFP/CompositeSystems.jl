function producer(c::Channel)
    put!(c, "start")
    for n=1:4
        put!(c, 2n)
    end
    put!(c, "stop")
end;

chnl = Channel(producer);

take!(chnl)



const jobs = Channel{Int}(32);
const results = Channel{Tuple}(32);

function do_work()
    for job_id in jobs
        exec_time = rand()
        sleep(exec_time)                # simulates elapsed time doing actual work
                                        # typically performed externally.
        put!(results, (job_id, exec_time))
    end
end;

function make_jobs(n)
    for i in 1:n
        put!(jobs, i)
    end
end;

n = 12;

import Base.Threads: nthreads, @spawn
import BenchmarkTools: @btime

#errormonitor(@spawn make_jobs(n)); # feed the jobs channel with "n" jobs
errormonitor(@async make_jobs(n)); # feed the jobs channel with "n" jobs

for i in 1:4 # start 4 tasks to process requests in parallel
    errormonitor(@async do_work())
end

@elapsed while n > 0 # print out results
    job_id, exec_time = take!(results)
    println("$job_id finished in $(round(exec_time; digits=2)) seconds")
    global n = n - 1
end
#@spawn 52.333 ns (0 allocations: 0 bytes)
#@async 53.049 ns (0 allocations: 0 bytes)


nsamples=10
sampleseeds = Channel{Int}(nsamples)
function makeseeds(sampleseeds::Channel{Int}, nsamples::Int)
    for s in 1:nsamples
        put!(sampleseeds, s)
    end
    close(sampleseeds)
end

Threads.@async makeseeds(sampleseeds, nsamples)

@elapsed while nsamples > 0 # print out results
    seeds = take!(sampleseeds)
    println("seed #$seeds")
    global nsamples = nsamples - 1
end #0.0046, #0.0026
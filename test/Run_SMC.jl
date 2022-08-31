using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
import BenchmarkTools: @btime

RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
PRATSBase.silence()
resultspecs = (Flow(), Flow())

method = PRATS.SequentialMonteCarlo(samples=1, seed=1, threaded=false)
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
@time flow,flowtotal = PRATS.assess(system, method, resultspecs...)
#91.200354 seconds (211.09 M allocations: 10.594 GiB, 1.00% gc time, 0.00% compilation time

method = PRATS.SequentialMonteCarlo(samples=4, seed=1, threaded=true)
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
@time flow,flowtotal = PRATS.assess(system, method, resultspecs...)
#304.688904 seconds (858.66 M allocations: 42.810 GiB, 2.92% gc time)

length(system.network.bus)
















#----------------------------------------------------------------------------------------------------------
threads = 1
sampleseeds = Channel{Int}(2)
simspec = PRATS.SequentialMonteCarlo(samples=1, seed=1)
resultspecs = (Flow(), Flow())
results =  CompositeAdequacy.resultchannel(simspec, resultspecs, threads)
@async CompositeAdequacy.makeseeds(sampleseeds, simspec.nsamples)
sequences = CompositeAdequacy.UpDownSequence(system)

# sequences.Up_gens
# sequences.Up_stors
# sequences.Up_genstors
# sequences.Up_branches

systemstate = CompositeAdequacy.SystemState(system)
#systemstate.gens_available
#systemstate.gens_available
#systemstate.stors_energy
#systemstate.branches_available

recorders = CompositeAdequacy.accumulator.(system, simspec, resultspecs)
network_data = PRATSBase.conversion_to_pm_data(system.network)
optimizer = [JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0), JuMP.optimizer_with_attributes(Juniper.Optimizer, 
            "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])]


rng = CompositeAdequacy.Philox4x((0, 0), 10)

s=1
CompositeAdequacy.seed!(rng, (simspec.seed, s))
CompositeAdequacy.initialize!(rng, systemstate, system, sequences)
#sum(sequences.Up_gens[10,:])
#x = 1:8760
#using Plots
#plot(x,sequences.Up_gens[33,:])

t=1
CompositeAdequacy.advance!(sequences, systemstate, system, t)
CompositeAdequacy.update_data_from_system!(network_data, system, t)
CompositeAdequacy.solve!(network_data, systemstate, system, optimizer, t)

system.branches.pf
#any(abs.(system.branches.pf[:,1]).>system.branches.longterm_rating[:,1])


#----------------------------------------------------------------------------------------------------------
[j for j in eachindex(1:1) if any(abs.(system.branches.pf[:,j]).>system.branches.longterm_rating[:,j])]



using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
import BenchmarkTools: @btime
PRATS.PRATSBase.silence()
PRATS.CompositeAdequacy.silence()
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)

CompositeAdequacy.add_load_curtailment_info!(system.network)


optimizer_2 = JuMP.optimizer_with_attributes(Juniper.Optimizer, 
"nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])

network_data = PRATSBase.conversion_to_pm_data(system.network)

network_data["branch"][string(25)]["br_status"] = 0
network_data["branch"][string(26)]["br_status"] = 0
network_data["branch"][string(28)]["br_status"] = 0


PRATSBase.SimplifyNetwork!(network_data)

results = PRATSBase.OptimizationProblem(network_data, PRATSBase.dc_opf_lc, optimizer_2)
results["solution"]["total"]["P_load_curtailed"]*100

@show keys(results["solution"]["branch"])

system.branches.keys
CompositeAdequacy.update_systemmodel_branches!(system, results["solution"], 1)

update_data!(network_data, results["solution"])
network_data["branch"]["25"]



systemstate.condition #if it is true, it is a success state

if systemstate.condition == false
    apply_contingencies!(system, systemstate)
end

# using PowerModels
# RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
# network_data = PowerModels.parse_file(RawFile)
# optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
# update_data!(network_data, PowerModels.compute_dc_pf(network_data)["solution"])
# flow = calc_branch_flow_dc(network_data)

#using PowerModels
#RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
#network_data = PowerModels.parse_file(RawFile)
#PowerModels.simplify_network!(network_data)
# [info | PowerModels]: deactivating bus 24 due to dangling bus without generation, load or storage
# [info | PowerModels]: deactivating branch 27:(15,24) due to connecting bus status
# [info | PowerModels]: deactivating connected component Set([3]) due to isolation without generation, load or storage
# [info | PowerModels]: deactivating load 3 due to inactive bus 3
# [info | PowerModels]: network simplification fixpoint reached in 3 rounds
using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test
import BenchmarkTools: @btime

RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)

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
optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)

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
#system = TimeSeriesPowerFlow!(network_data, system, optimizer, t)
#function ContingencyAnalysis(network_data::Dict{String,Any}, system::SystemModel{N}, optimizer, t::Int) where {N}

"Add load curtailment information to data"
function add_load_curtailment_info!(network::Network)
    for i in eachindex(network.load)
        push!(network.load[string(i)], "cost" => float(1000))
    end
end


add_load_curtailment_info!(system.network)
network_data = PRATSBase.conversion_to_pm_data(system.network)
#network_data["branch"][string(2)]["br_status"] = 0
#network_data["branch"][string(6)]["br_status"] = 0
#network_data["branch"][string(7)]["br_status"] = 0

PRATSBase.SimplifyNetwork!(network_data)
CompositeAdequacy.update_data_from_system!(network_data, system, t)
update_data!(network_data, PowerModels.solve_dc_opf(network_data, optimizer)["solution"])
flow = calc_branch_flow_dc(network_data)
flow["branch"]

result = PRATSBase.min_load(network_data, optimizer)
result["solution"]["branch"]

result["solution"]["load curtailment"]




systemstate.condition #if it is true, it is a success state

if systemstate.condition == false
    apply_contingencies!(system, systemstate)
end


#using PowerModels
#RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
#network_data = PowerModels.parse_file(RawFile)
#PowerModels.simplify_network!(network_data)
# [info | PowerModels]: deactivating bus 24 due to dangling bus without generation, load or storage
# [info | PowerModels]: deactivating branch 27:(15,24) due to connecting bus status
# [info | PowerModels]: deactivating connected component Set([3]) due to isolation without generation, load or storage
# [info | PowerModels]: deactivating load 3 due to inactive bus 3
# [info | PowerModels]: network simplification fixpoint reached in 3 rounds




""
function apply_contingencies!(network_data::Dict{String,Any}, state::SystemState) where {N}

    for i in eachindex(system.branches.keys)
        if state.branches_available[i] == false
            #system.network.branch[string(i)]["br_status"] = state.branches_available[i]
            network_data["branch"][string(i)]["br_status"] = state.branches_available[i]
        end
    end

    for i in eachindex(system.generators.keys)
        if state.gens_available[i] == false
            #system.network.gen[string(i)]["gen_status"] = state.gens_available[i]
            network_data["gen"][string(i)]["gen_status"] = state.gens_available[i]
        end
    end

    for i in eachindex(system.storages.keys)
        if state.stors_available[i] == false
            #system.network.storage[string(i)]["status"] = state.stors_available[i]
            network_data["storage"][string(i)]["status"] = state.stors_available[i]
        end
    end

end


function TimeSeriesPowerFlow!(network_data::Dict{String,Any}, system::SystemModel{N}, optimizer, t::Int) where {N}

    update_data_from_system!(network_data, system, t)

    update_data!(network_data, PowerModels.compute_dc_pf(network_data)["solution"])
    flow = calc_branch_flow_dc(network_data)
    update_systemmodel_branches!(system, flow, t)

    if any(abs.(system.branches.pf[:,t]).> system.branches.longterm_rating[:,t])
        update_data!(network_data, PowerModels.solve_dc_opf(network_data, optimizer)["solution"])
        flow = calc_branch_flow_dc(network_data)
        update_systemmodel_branches!(system, flow, t)
    end

    update_data!(network_data, flow)
    update_systemmodel_generators!(network_data, system, t)
    return system

end


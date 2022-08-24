using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
using Test

RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)

method = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
resultspecs = (Shortfall(),Flow())
#shortfalls, availability = PRATS.assess(system, method, resultspecs...)

#threads = Base.Threads.nthreads()
threads = 1
sampleseeds = Channel{Int}(2*threads)

results = PRATS.CompositeAdequacy.resultchannel(method, resultspecs, threads)
@async PRATS.CompositeAdequacy.makeseeds(sampleseeds, method.nsamples)

#assess(system, method, sampleseeds, results, resultspecs...)

sequences = UpDownSequence(system)
systemstate = SystemState(system)

#recorders = accumulator.(system, method, resultspecs)
rng = PRATS.CompositeAdequacy.Philox4x((0, 0), 10)
PRATS.CompositeAdequacy.seed!(rng, (method.seed, 1))  #using the same seed for entire period.
N = 8760
t = 1

# system.loads.keys
# system.loads.buses[system.loads.keys]
# system.loads.capacity[system.loads.keys]
# system.loads.capacity
# system.loads.capacity[1,:]
# system.loads.capacity[system.loads.keys,2]
# system.loads

network_data =  PowerModels.parse_file(RawFile)
pf_result = PowerModels.compute_dc_pf(network_data)
PowerModels.update_data!(network_data, pf_result["solution"])
flow = PowerModels.calc_branch_flow_dc(network_data)

for i in eachindex(network_data["branch"])
    @test abs(flow["branch"][i]["pf"]) <= network_data["branch"][i]["rate_a"]
end

network_data_mn = PowerModels.replicate(network_data, N)

for j in eachindex(1:N)
    for i in eachindex(system.loads.keys)
        pf = network_data_mn["nw"][string(j)]["load"][string(i)]["qd"]/network_data_mn["nw"][string(j)]["load"][string(i)]["pd"]
        network_data_mn["nw"][string(j)]["load"][string(i)]["pd"] = system.loads.capacity[i,j]/system.network.baseMVA
        network_data_mn["nw"][string(j)]["load"][string(i)]["qd"] = network_data_mn["nw"][string(j)]["load"][string(i)]["pd"]*pf
    end
end

optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
pf_result = PowerModels.solve_mn_opf(network_data_mn, DCPPowerModel, optimizer)                 #DCPPowerModel, #ACPPowerModel
#@test pf_result["termination_status"] == LOCALLY_SOLVED

pf_result["solution"]["nw"]


 for j in eachindex(1:N)
     for (i, branch) in pf_result["solution"]["nw"][string(j)]["branch"]
         @test abs(branch["pf"]) <= network_data["branch"][i]["rate_a"]
     end
 end

PowerModels.update_data!(network_data_mn, pf_result["solution"])
container = Dict{Int64, Any}()

for j in eachindex(1:N)

    setindex!(network_data_mn["nw"][string(j)], true, "per_unit")

    for (i, branch) in pf_result["solution"]["nw"][string(j)]["branch"]

        if branch["pf"] > network_data["branch"][string(i)]["rate_a"]
            
            Memento.info(_LOGGER, "Branch (f_bus,t_bus)=($(network_data["branch"][string(i)]["f_bus"]),$(network_data["branch"][string(i)]["t_bus"])) is overloaded by %$(
                Float16(branch["pf"]*100/network_data["branch"][string(i)]["rate_a"])), MW=$(
                Float16(branch["pf"])), rate_a = $(network_data["branch"][string(i)]["rate_a"]), key=$(
                i), index=$(network_data["branch"][string(i)]["index"]), Hour=$(j).")
            opf = PowerModels.solve_opf(network_data_mn["nw"][string(j)], DCPPowerModel, optimizer)
            @test opf["termination_status"] == LOCALLY_SOLVED

            pf_result["solution"]["nw"][string(j)]["branch"] = opf["solution"]["branch"]
            @test branch["pf"]["pf"] <= network_data["branch"][string(i)]["rate_a"]

            pf_result["solution"]["nw"][string(j)]["gen"] = opf["solution"]["gen"]
            pf_result["solution"]["nw"][string(j)]["bus"] = opf["solution"]["bus"]
        
        end

        flow = PowerModels.calc_branch_flow_dc(network_data_mn["nw"][string(j)])
        setindex!(container, [abs.(Float16.(flow["branch"][string(k)]["pf"])) for k in eachindex(system.branches.keys)], j)
    end
end


#PowerModels.run_mn_pf()
#PowerModels.run_mn_opf_strg()
#PowerModels.run_mn_opf()
#TESTLOG = Memento.getlogger(PowerModels)
#@test_throws(TESTLOG, ErrorException, PowerModels.correct_voltage_angle_differences!(network_data))
#@test_throws(TESTLOG, ErrorException, PowerModels.calc_connected_components(network_data))


container_data = [container[i] for i in keys(container)]
@show container_data[1]
@show container_data[2]


#system.network
#data = PRATSBase.conversion_to_pm_data(system.network)
#pf_result = PowerModels.compute_dc_pf(data)
#PowerModels.update_data!(data, pf_result["solution"])
#flow = PowerModels.calc_branch_flow_dc(data)
#update_problem!(dispatchproblem, state, system, t)
#PowerModels.update_data!(data, flow)
#network = Network{1,1,Hour,MW,MWh,kV}(data)
#



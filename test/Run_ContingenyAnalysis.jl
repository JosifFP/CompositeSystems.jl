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

network_data = PRATSBase.conversion_to_pm_data(system.network)
pf = Float32.([network_data["load"][string(i)]["qd"] / network_data["load"][string(i)]["pd"] for i in eachindex(system.loads.keys)])

for j in eachindex(1:N)

     for i in eachindex(system.generators.keys)
         network_data["gen"][string(i)]["pg"] = system.generators.pg[i,j]
         @test network_data["gen"][string(1)]["pg"] <= network_data["gen"][string(1)]["pmax"]
     end

    for i in eachindex(system.loads.keys)
        network_data["load"][string(i)]["pd"] = system.loads.pd[i,j]
        network_data["load"][string(i)]["qd"] = system.loads.pd[i,j]*pf[i]
    end

    pf_result = PowerModels.compute_dc_pf(network_data)
    PowerModels.update_data!(network_data, pf_result["solution"])
    flow = PowerModels.calc_branch_flow_dc(network_data)

    for i in eachindex(system.branches.keys)
        system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
        system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])

        #if abs.(system.branches.pf[i,j]) > system.branches.longterm_rating[i,j]
    end
end

overloadings = [j for j in eachindex(1:N) if any(system.branches.pf[:,j].>system.branches.longterm_rating[:,j])]
optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)

for j in eachindex(overloadings)
    
    for i in eachindex(system.generators.keys)
        network_data["gen"][string(i)]["pg"] = system.generators.pg[i,j]
        @test network_data["gen"][string(1)]["pg"] <= network_data["gen"][string(1)]["pmax"]
    end

   for i in eachindex(system.loads.keys)
       network_data["load"][string(i)]["pd"] = system.loads.pd[i,j]
       network_data["load"][string(i)]["qd"] = system.loads.pd[i,j]*pf[i]
   end

    pf_result = PowerModels.solve_dc_opf(network_data, optimizer)
    PowerModels.update_data!(network_data, pf_result["solution"])
    flow = PowerModels.calc_branch_flow_dc(network_data)
            
    for i in eachindex(system.branches.keys)
        if abs(flow["branch"][string(i)]["pf"]) > network_data["branch"][string(i)]["rate_a"]
            Memento.info(_LOGGER, "Branch (f_bus,t_bus)=($(network_data["branch"][string(i)]["f_bus"]),$(network_data["branch"][string(i)]["t_bus"])) is overloaded by %$(
                Float16(abs(flow["branch"][string(i)]["pf"])*100/network_data["branch"][string(i)]["rate_a"])), MW=$(
                Float16(flow["branch"][string(i)]["pf"])), rate_a = $(network_data["branch"][string(i)]["rate_a"]), key=$(
                i), index=$(network_data["branch"][string(i)]["index"]), Hour=$(j).")
        end
        system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
        system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])
    end

    PowerModels.update_data!(network_data, flow)
end

system.branches.pf

    # Memento.info(_LOGGER, "Branch (f_bus,t_bus)=($(network_data["branch"][string(i)]["f_bus"]),$(network_data["branch"][string(i)]["t_bus"])) is overloaded by %$(
    #     Float16(abs(flow["branch"][string(i)]["pf"])*100/network_data["branch"][string(i)]["rate_a"])), MW=$(
    #     Float16(flow["branch"][string(i)]["pf"])), rate_a = $(network_data["branch"][string(i)]["rate_a"]), key=$(
    #     i), index=$(network_data["branch"][string(i)]["index"]), Hour=$(j).")

# opf = PowerModels.solve_opf(network_data, DCPPowerModel, optimizer)
# PowerModels.update_data!(network_data, opf["solution"])
# flow = PowerModels.calc_branch_flow_dc(network_data)
# for i in eachindex(system.loads.keys)
#     @test abs(flow["branch"][string(i)]["pf"]) <= network_data["branch"][string(i)]["rate_a"]
# end

for j in eachindex(map(x -> x[1], overloadings))

    for i in eachindex(system.generators.keys)
        network_data["gen"][string(i)]["pg"] = system.generators.pg[i,j]
        @test network_data["gen"][string(1)]["pg"] <= network_data["gen"][string(1)]["pmax"]
    end

   for i in eachindex(system.loads.keys)
       network_data["load"][string(i)]["pd"] = system.loads.pd[i,j]
       network_data["load"][string(i)]["qd"] = system.loads.pd[i,j]*pf[i]
   end

   pf_result = PowerModels.solve_dc_opf(network_data, optimizer)
   PowerModels.update_data!(network_data, pf_result["solution"])
   flow = PowerModels.calc_branch_flow_dc(network_data)

   for i in eachindex(system.branches.keys)
       if abs(flow["branch"][string(i)]["pf"]) > network_data["branch"][string(i)]["rate_a"]

           push!(overloadings, [j,i])
           Memento.info(_LOGGER, "Branch (f_bus,t_bus)=($(network_data["branch"][string(i)]["f_bus"]),$(network_data["branch"][string(i)]["t_bus"])) is overloaded by %$(
               Float16(abs(flow["branch"][string(i)]["pf"])*100/network_data["branch"][string(i)]["rate_a"])), MW=$(
               Float16(flow["branch"][string(i)]["pf"])), rate_a = $(network_data["branch"][string(i)]["rate_a"]), key=$(
               i), index=$(network_data["branch"][string(i)]["index"]), Hour=$(j).")
       end

       system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
       system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])
   end
end


#network_data = PowerModels.parse_file(RawFile)
PowerModels.update_data!(network_data, pf_result["solution"])
flow = PowerModels.calc_branch_flow_dc(network_data)

for i in eachindex(system.branches.keys)
    @test abs(flow["branch"][string(i)]["pf"]) <= network_data["branch"][string(i)]["rate_a"]
end
optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
opf = PowerModels.solve_opf(network_data, DCPPowerModel, optimizer)
PowerModels.update_data!(network_data, opf["solution"])
flow = PowerModels.calc_branch_flow_dc(network_data)
for i in eachindex(system.loads.keys)
    @test abs(flow["branch"][string(i)]["pf"]) <= network_data["branch"][string(i)]["rate_a"]
end


#PowerModels.calc_admittance_matrix(network_data)
#display(network_data) # raw dictionary
#PowerModels.print_summary(network_data) # quick table-like summary
# system.loads.keys # system.loads.buses[system.loads.keys] # system.loads.capacity[system.loads.keys]
# system.loads.capacity # system.loads.capacity[1,:] # system.loads.capacity[system.loads.keys,2] # system.loads

# "Makes a string bold in the terminal"
# function _bold(s::String)
#     return "\033[1m$(s)\033[0m"
# end

# "converts any value to a string"
# function value2string(v::Any, float_precision::Int)
#     return "$(v)"
# end

# "Attempts to determine if the given data is a component dictionary"
# function _iscomponentdict(data::Dict)
#     return all( typeof(comp) <: Dict for (i, comp) in data )
# end

# float_precision = 3
# component_types_order = Dict()
# component_parameter_order = Dict()
# max_parameter_value = 999.0
# component_status_parameters = Set(["status"])
# component_types = []
# other_types = []

# println(_bold("Metadata"))
# for (k,v) in sort(collect(network_data); by=x->x[1])
#     if typeof(v) <: Dict && _iscomponentdict(v)
#         push!(component_types, k)
#         continue
#     end

#     println("  $(k): $(value2string(v, float_precision))")
# end

# println("")
# println(_bold("Table Counts"))
# for k in sort(component_types, by=x->get(component_types_order, x, max_parameter_value))
#     println("  $(k): $(length(network_data[k]))")
# end

# optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
# pf_result = PowerModels.solve_mn_opf(network_data_mn, DCPPowerModel, optimizer)                 #DCPPowerModel, #ACPPowerModel
# @test pf_result["termination_status"] == LOCALLY_SOLVED
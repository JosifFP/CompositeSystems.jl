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

resultspecs = (Flow(), FlowTotal())
method = PRATS.NoContingencies(opf=false, verbose=false, threaded=false)
flow,flowtotal = PRATS.assess(system, method, resultspecs...)
[j for j in eachindex(1:8760) if any(abs.(flowtotal.total[:,j,1]).>system.branches.longterm_rating[:,j])]

system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
method = PRATS.NoContingencies(opf=false, verbose=false, threaded=false)
@time flow,flowtotal = PRATS.assess(system, method, resultspecs...)
#2.936242 seconds (37.07 M allocations: 1.912 GiB, 5.20% gc time)


system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
method = PRATS.NoContingencies(opf=true, verbose=false, threaded=false)
@time flow,flowtotal = PRATS.assess(system, method, resultspecs...)
# 3.352092 seconds (37.11 M allocations: 1.915 GiB, 6.66% gc time)
flow,flowtotal = PRATS.assess(system, method, resultspecs...)
[j for j in eachindex(1:8760) if any(abs.(flowtotal.total[:,j,1]).>system.branches.longterm_rating[:,j])]

system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
method = PRATS.NoContingencies(opf=false, verbose=false, threaded=true)
@time flow,flowtotal = PRATS.assess(system, method, resultspecs...)
#3.115535 seconds (37.07 M allocations: 1.912 GiB, 4.99% gc time)

system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)
method = PRATS.NoContingencies(opf=true, verbose=false, threaded=true)
@time flow,flowtotal = PRATS.assess(system, method, resultspecs...)
#5.239695 seconds (41.99 M allocations: 2.115 GiB, 3.38% gc time)




[j for j in eachindex(1:8760) if any(abs.(flow.pf[:,j]).>system.branches.longterm_rating[:,j])]

#threads = Base.Threads.nthreads()
periods = Channel{Int}(2*threads)
#results = CompositeAdequacy.resultchannel(method, resultspecs, threads)
system.branches.pf
[j for j in eachindex(1:8760) if any(abs.(system.branches.pf[:,j]).>=system.branches.longterm_rating[:,j])]

# nloads = length(system.loads)
# ngens = length(system.generators)
# nstors = length(system.storages)
# ngenstors = length(system.generatorstorages)
# nbranches = length(system.branches)
#assess(system, method, sampleseeds, results, resultspecs...)
#systemstate = SystemState(system)
#recorders = accumulator.(system, method, resultspecs)
# L = 1
# T = timeunits["h"]
# U = perunit["pu"]
#@btime PowerModels.compute_basic_dc_pf(network_data)
#network_data = parse_file(RawFile)
#check_violations(network_data, flow)
#a = map(x -> collect(x) ,values(network_data["gen"]))
#overloadings = [j for j in eachindex(1:8760) if any(system.branches.pf[:,j].>=system.branches.longterm_rating[:,j])]
#[@assert container_pf[key_order][i] <= container_rate_a[key_order_rate_a][i] "Tests didn't pass" for i in eachindex(container_rate_a)]
#[j for j in eachindex(1:N) if any(system.branches.pf[:,j].>=system.branches.longterm_rating[:,j])]
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
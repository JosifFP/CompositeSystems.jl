include("solvers.jl")
import PowerModels, JuMP
using Test
import PRATS: PRATS, BaseModule
PowerModels.silence()

# gurobi_optimizer_1
# juniper_optimizer_2
# ipopt_optimizer_3
RawFile = "test/data/RBTS/RBTS.m"
RawFile_strg = "test/data/RBTS/RBTS_strg.m"
ReliabilityFile = "test/data/RBTS/R_RBTS_strg.m"
#data = PowerModels.parse_file(RawFile)
data_strg = PowerModels.parse_file(RawFile_strg)
#@show data_strg["storage"]["1"]

network = BaseModule.BuildNetwork(RawFile_strg)
reliability_data = BaseModule.parse_reliability_data(ReliabilityFile)
SParametrics = BaseModule.StaticParameters{1,1,PRATS.Hour}()
get!(network, :timeseries_load, "")
BaseModule._merge_prats_data!(network, reliability_data, SParametrics)
network
network[:storage][1]
network[:gen][1]

data = BaseModule.container(network[:storage], BaseModule.storage_fields)
println(data)









PowerModels.standardize_cost_terms!(data, order=1)
PowerModels.standardize_cost_terms!(data_strg, order=1)

result = PowerModels.solve_dc_opf(data, ipopt_optimizer_3)

result["solution"]
result["solution"]["bus"]
@show result["solution"]["branch"]


result_strg = PowerModels._solve_opf_strg(data_strg, PowerModels.DCPPowerModel, ipopt_optimizer_3)
result_strg["solution"]
result_strg["solution"]["bus"]
result_strg["solution"]["gen"]
result_strg["solution"]["storage"]["1"]

@show result_strg["solution"]["branch"]




@test result["termination_status"] == JuMP.LOCALLY_SOLVED
@test isapprox(result["objective"], 16840.7; atol = 1e0)
@test isapprox(result["solution"]["storage"]["1"]["se"],  0.0; atol = 1e0)
@test isapprox(result["solution"]["storage"]["1"]["ps"], -0.176871; atol = 1e-2)
@test isapprox(result["solution"]["storage"]["2"]["se"],  0.0; atol = 1e0)
@test isapprox(result["solution"]["storage"]["2"]["ps"], -0.2345009; atol = 1e-2)



JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)
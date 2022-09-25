import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"


nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "log_levels"=>[])

data = PowerModels.parse_file(RawFile)
mn_data =  PowerModels.replicate(data, 2160)
# mn_data["nw"]["1"]["branch"][string(7)]["br_status"] = 0
# mn_data["nw"]["1"]["branch"][string(23)]["br_status"] = 0
# mn_data["nw"]["1"]["branch"][string(3)]["br_status"] = 0
PowerModels.simplify_network!(mn_data)

# nw = nsamples
#solve_mn_opf


#@btime opf_result = PowerModels.solve_mn_opf(mn_data, PowerModels.DCPPowerModel, optimizer)
pm = PowerModels.instantiate_model(mn_data, PowerModels.DCPPowerModel, PowerModels.build_mn_opf)
pms = PowerModels.instantiate_model(data, PowerModels.DCPPowerModel, PowerModels.build_mn_opf)
pm.ref[:it][:pm][:nw][1]
pms.ref
pm.var

refs = Dict{Symbol, Any}(:it => Dict{Symbol, Any}())
mn_data["nw"]["1"]

PowerModels.nws(pm)
#nws(pm::AbstractPowerModel) = _IM.nws(pm, pm_it_sym)



"********************************************************************************************************************************"

using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 2160)
nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "log_levels"=>[])


systemstate = CompositeAdequacy.SystemState(system)
ref = CompositeAdequacy.initialize_ref(system.network; multinetwork=true)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
iter = CompositeAdequacy.initialize!(rng, systemstate, system)
pm = CompositeAdequacy.InitializeAbstractPowerModel(CompositeAdequacy.AbstractDCPModel, system.network, ref, optimizer; multinetwork=true)

CompositeAdequacy.ref(pm, 1, :bus, 1)


CompositeAdequacy.ext(pm, 1)[:type] = CompositeAdequacy.OPFMethod

CompositeAdequacy.ext(pm, 1, :type)


ext(pm,nw)[:type] == OPFMethod

pm.ext[:type]
pm.var[:it][:pm][:nw][1][:p]
pm.var[:it][:pm][:nw][2][:p]
#results = PowerModels.build_mn_opf(pm)
result = PowerModels.optimize_model!(pm, relax_integrality=false, optimizer=optimizer, solution_processors=[])
result["solution"]


pm.var[:it][:pm][:nw][1][:va]
pm.var[:it][:pm][:nw][2][:va]

pm.var[:it][:pm][:nw][0][:va]
pm.ref[:it][:pm][:nw][1]
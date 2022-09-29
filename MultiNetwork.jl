using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP, HiGHS
using Test
import BenchmarkTools: @btime
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
RawFile = "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.m"

nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])
PRATSBase.silence()
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir, 8760)
resultspecs = (Shortfall(), Report())
method = PRATS.SequentialMonteCarlo(samples=100, seed=1, verbose=false, threaded=true)
@time shortfall,report = PRATS.assess(system, method, optimizer, resultspecs...)

PRATS.LOLE.(shortfall, system.loads.keys)
PRATS.EUE.(shortfall, system.loads.keys)
sum(report.status)


"********************************************************************************************************************************"
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

nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0)
optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, 
    "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])

systemstate = CompositeAdequacy.SystemState(system)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
model = JuMP.direct_model(optimizer)
pms = CompositeAdequacy.BuildAbstractPowerModel!(CompositeAdequacy.DCPowerModel, JuMP.direct_model(optimizer), CompositeAdequacy.MutableNetwork(system.network))
pm = deepcopy(pms)
pm.ref.branch[25]["br_status"] = 0
pm.ref.branch[26]["br_status"] = 0
pm.ref.branch[28]["br_status"] = 0
CompositeAdequacy.ref_add!(pm.ref)
CompositeAdequacy.sol(pm)[:type] = type = CompositeAdequacy.DCOPF
CompositeAdequacy.build_method!(pm, type)
JuMP.optimize!(pm.model)
JuMP.solution_summary(pm.model, verbose=true)
CompositeAdequacy.build_result!(pm, system.loads, 1)
#p_lc = CompositeAdequacy.build_sol_values(CompositeAdequacy.sol(pm, :load_curtailment))

JuMP.Containers.DenseAxisArray{}()
a = JuMP.Containers.DenseAxisArray([], 0:6)
@btime Float64[]
empty(a)
using PRATS
using PRATS.CompositeAdequacy
using PRATS.TransmissionSystem
import BenchmarkTools: @btime
using PowerModels
using Test

file = "test/data/RTS.raw"
PRATS.silence()

network = PRATS.TransmissionSystem.BuildNetwork(file)
data = PowerModels.parse_file(file)
data["bus"]["1"]
network.bus["1"]





#  4.410 ms (48266 allocations: 2.22 MiB)

# ref = PRATS.TransmissionSystem.get_ref(data, PRATS.Network.dc_opf_lc)
# ref[:bus]

using PowerModels, InfrastructureModels
dc_flows = PowerModels.calc_branch_flow_dc(data)
dc_flows["branch"]






















loadfile = "test/data/rts_Load.xlsx"
sys = PRATS.SystemModel(loadfile)

sys.buses

sys.generators
sys.bus_gen_idxs

sys.storages
sys.bus_stor_idxs

sys.generatorstorages
sys.bus_genstor_idxs

sys.timestamps

#sys.load
sys.branches
sys.interfaces
sys.interface_branch_idxs



include("test/temporal/testsystems/testsystems.jl")
sys = TestSystems.singlenode_stor

sys.buses

sys.generators
sys.bus_gen_idxs

sys.storages
sys.bus_stor_idxs

sys.generatorstorages
sys.bus_genstor_idxs

sys.timestamps

#sys.load
sys.branches
sys.interfaces
sys.interface_branch_idxs
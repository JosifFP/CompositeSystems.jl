using PRATS
using PRATS.CompositeAdequacy
using PRATS.Network
import BenchmarkTools: @btime

file = "test/data/RTS.raw"
data = PRATS.Network.build_data(file)
ref = PRATS.Network.get_ref(data, PRATS.Network.dc_opf_lc)

data["bus"]["1"]
data["gen"]["1"]
data["branch"]["1"]

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
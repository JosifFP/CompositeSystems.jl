using PRATS
using PRATS.CompositeAdequacy
using PRATS.PRATSBase
import BenchmarkTools: @btime
using PowerModels
using Test

file = "test/data/RTS.raw"

network = PRATSBase.BuildNetwork(file)
ref = PRATSBase.get_ref(network)
#data = PowerModels.parse_file(file)

ref = PRATSBase.get_ref(network)
ref[:bus_loads]
ref[:branch][1]

refs = Dict{Symbol, Any}()
for (key,item) in data
    if isa(item, Dict{String, Any})
        refs[Symbol(key)] = Dict{Int, Any}([(parse(Int, k), v) for (k, v) in item])
    else
        refs[Symbol(key)] = item
    end        
end


# ref = PRATS.PRATS.PRATSBase.get_ref(data, PRATS.Network.dc_opf_lc)
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
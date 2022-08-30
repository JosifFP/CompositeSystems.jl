using PRAS
include("test/temporal/testsystems/testsystems_pras.jl")

@show regions = PRAS.Regions{4, PRAS.MW}(["Region A", "Region B", "Region C"],
                  [19 20 21 20; 20 21 21 22; 22 21 23 22])

regions.load[3,:]

sys = TestSystems_pras.singlenode_stor

sys.buses

sys.generators
sys.bus_gen_idxs

sys.storages
sys.storages.energy_capacity
sys.generatorstorages.energy_capacity
getfield(sys.storages, :energy_capacity)

sys.bus_stor_idxs

sys.generatorstorages
sys.bus_genstor_idxs

sys.timestamps

#sys.load
sys.branches
sys.interfaces
sys.interface_branch_idxs



#--------------------------------------------------------------------------------

using PRATS
using PRATS.PRATSBase
using XLSX
import Dates
import Dates: DateTime, Date, Time
import BenchmarkTools: @btime


inputfile = "C:/Users/jfiguero/.julia/dev/PRATS/test/data/rts_load.xlsx"
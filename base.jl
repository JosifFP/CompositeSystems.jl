using PRATS
using PRATS.CompositeAdequacy
using PRATS.Network
import BenchmarkTools: @btime

file = "test/data/RTS.raw"
data = PRATS.Network.build_data(file)

data["bus"]["1"]


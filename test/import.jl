#using Pkg
#Pkg.develop(PackageSpec(path="C:/Users/jfiguero/.julia/dev/ContingencySolver"))
using PRATS, HDF5, Dates, TimeZones, Test, CSV, DataFrames, XLSX, PRAS, ContingencySolver
import PRATS: Base, units, utils, SystemModel, assets, powerunits
import HDF5: File

file = "test/data/RTS.raw"
data = ContingencySolver.build_data(file)
data["bus"]

regions = Regions{1, MW}(
    ["Region A", "Region B"], reshape([8, 9], 2, 1))
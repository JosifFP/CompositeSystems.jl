
using  HDF5, Dates, TimeZones, Test, CSV, DataFrames, XLSX, PRATS
import HDF5: File


inputfile = "test/data/rts.pras"
system = HDF5.h5open(inputfile, "r")

#inputfile = "test/data/rts.hdf5"
#xlsxfile = "test/data/rts/rts.xlsx"
#sys = PRAS.SystemModel("test/data/rts.pras")
#shortfalls, flows = PRAS.assess(sys, SequentialMonteCarlo(samples=1000), Shortfall(), Flow())
#lole =  PRAS.EUE(shortfalls, "1")





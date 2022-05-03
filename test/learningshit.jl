
using  HDF5, Dates, TimeZones, Test, CSV, DataFrames, XLSX, PRATS
import HDF5: File


inputfile = "test/data/rts.pras"
system = HDF5.h5open(inputfile, "r")

#inputfile = "test/data/rts.hdf5"
#xlsxfile = "test/data/rts/rts.xlsx"
#sys = PRAS.SystemModel("test/data/rts.pras")
#shortfalls, flows = PRAS.assess(sys, SequentialMonteCarlo(samples=1000), Shortfall(), Flow())
#lole =  PRAS.EUE(shortfalls, "1")


#########################################################################################
@testset "Units and Conversions" begin

    @test powertoenergy(10, MW, 2, Hour, MWh) == 20
    @test powertoenergy(10, MW, 30, Minute, MWh) == 5

    @test energytopower(100, MWh, 10, Hour, MW) == 10
    @test energytopower(100, MWh, 30, Minute, MW) == 200

    @test unitsymbol(MW) == "MW"
    @test unitsymbol(GW) == "GW"

    @test unitsymbol(MWh) == "MWh"
    @test unitsymbol(GWh) == "GWh"
    @test unitsymbol(TWh) == "TWh"

    @test unitsymbol(Minute) == "min"
    @test unitsymbol(Hour) == "h"
    @test unitsymbol(Day) == "d"
    @test unitsymbol(Year) == "y"

end




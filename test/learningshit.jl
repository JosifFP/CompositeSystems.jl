
using PRATS, HDF5, Dates, TimeZones, Test, CSV, DataFrames, XLSX
import PRATS: Base, units, utils, SystemModel, assets, powerunits
import HDF5: File


inputfile = "test/data/rts.pras"
#inputfile = "test/data/rts.hdf5"
#xlsxfile = "test/data/rts/rts.xlsx"
sys = PRATS.SystemModel("test/data/rts.pras")


shortfalls, flows = PRAS.assess(sys, SequentialMonteCarlo(samples=100), Shortfall(), Flow())













#########################################################################################

#f = XLSX.readxlsx(xlsxfile)
#f["main"]
#DataFrame(f)

#const tz = tz"UTC"
#year = 2022
#start_timestamp = ZonedDateTime(year,1,1,0,tz)
#start_timestamp = ZonedDateTime(string(f[(f.Main .== "start_timestamp"), :Main_value][]), dateformat"yyyy-mm-ddTHH:MM:SSz")
#N = 365*24
#L = 1
#T = timeunits[f[(f.Main .== "timestep_unit"), :Main_value][]]
#P = powerunits[f[(f.Main .== "power_unit"), :Main_value][]]
#E = energyunits[f[(f.Main .== "energy_unit"), :Main_value][]]


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




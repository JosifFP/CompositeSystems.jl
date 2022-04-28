
using PRATS, HDF5, Dates, TimeZones, Test, CSV, DataFrames, XLSX, PRAS
import PRATS: Base, units, utils, SystemModel, assets, powerunits
import HDF5: File


inputfile = "test/data/rts.pras"
system = h5open(inputfile, "r")

#inputfile = "test/data/rts.hdf5"
#xlsxfile = "test/data/rts/rts.xlsx"
sys = PRAS.SystemModel("test/data/rts.pras")
shortfalls, flows = PRAS.assess(sys, SequentialMonteCarlo(samples=1000), Shortfall(), Flow())
lole =  PRAS.EUE(shortfalls, "1")



f = h5open(inputfile, "r")
metadata = attributes(f)

    start_timestamp = ZonedDateTime(read(metadata["start_timestamp"]),
                                    dateformat"yyyy-mm-ddTHH:MM:SSz")

    N = read(metadata["timestep_count"])
    L = read(metadata["timestep_length"])
    T = timeunits[read(metadata["timestep_unit"])]
    P = powerunits[read(metadata["power_unit"])]
    E = energyunits[read(metadata["energy_unit"])]

    timestamps = range(start_timestamp, length=N, step=T(L))

    has_regions = haskey(f, "regions")
    has_generators = haskey(f, "generators")
    has_storages = haskey(f, "storages")
    has_generatorstorages = haskey(f, "generatorstorages")
    has_interfaces = haskey(f, "interfaces")
    has_lines = haskey(f, "lines")

    has_regions ||
        error("Region data must be provided")

    has_generators || has_generatorstorages ||
        error("Generator or generator storage data (or both) must be provided")

    xor(has_interfaces, has_lines) &&
        error("Both (or neither) interface and line data must be provided")

    regionnames = readvector(f["regions/_core"], :name)
    regions = Regions{N,P}(
        regionnames,
        Int.(read(f["regions/load"]))
    )
    regionlookup = Dict(n=>i for (i, n) in enumerate(regionnames))
    n_regions = length(regions)

    #if has_generators

        gen_core = read(f["generators/_core"])
        gen_names, gen_categories, gen_regionnames = readvector.(
            Ref(gen_core), [:name, :category, :region])

        gen_regions = getindex.(Ref(regionlookup), gen_regionnames)
        region_order = sortperm(gen_regions)

        generators = Generators{N,L,T,P}(
            gen_names[region_order], gen_categories[region_order],
            Int.(read(f["generators/capacity"]))[region_order, :],
            read(f["generators/failureprobability"])[region_order, :],
            read(f["generators/repairprobability"])[region_order, :]
        )

        region_gen_idxs = makeidxlist(gen_regions[region_order], n_regions)

    #else

        generators = Generators{N,L,T,P}(
            String[], String[], zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N))

        region_gen_idxs = fill(1:0, n_regions)

    end







    """
    Attempts to extract a vector of elements from an HDF5 compound datatype,
    corresponding to `field`.
    """
    readvector(d::HDF5.Dataset, field::Union{Symbol,Int}) = readvector(read(d), field)
    readvector(d::Vector{<:NamedTuple}, field::Union{Symbol,Int}) = getindex.(d, field)
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





#"Creates folder and files for adequacy studies"

function FileGenerator(RawFile::String, InputData::Vector{String})

    if ispath(RawFile) == false
        error("$RawFile must be path")
    end

    CurrentDir = dirname(RawFile)

    cd(CurrentDir)
    mkdir("Reliability Data")
    cd("Reliability Data")
    ReliabilityDataDir = pwd()

    # Import Transmission Network file (.raw)
    network = PRATSBase.BuildNetwork(RawFile)
    ref = Dict{Symbol, Any}()
    ref[:load] = Dict(i => network.load[string(i)] for i in 1:length(keys(network.load)))
    ref[:gen] = Dict(i => network.gen[string(i)] for i in 1:length(keys(network.gen)))
    ref[:storage] = Dict(i => network.storage[string(i)] for i in 1:length(keys(network.storage)))
    ref[:branch] = Dict(i => network.branch[string(i)] for i in 1:length(keys(network.branch)))

    #create files to be imported
    cd(ReliabilityDataDir)

    if in(InputData).("loads") == true
        XLSX.openxlsx("loads.xlsx", mode="w") do xf

            sheet = xf[1]
            XLSX.rename!(sheet, "core")
            sheet["A1"] = [ "key" "bus" "MW" "MVAR" "power factor"]
            tmp = sort([[i, load["load_bus"], 
                        load["pd"]*network.baseMVA,
                        load["qd"]*network.baseMVA,
                        load["qd"]./load["pd"]] for (i,load) in ref[:load]], by = x->x[1])
            sheet["A2"] = reduce(vcat, tmp')

            XLSX.addsheet!(xf,"load curtailment data")
            sheet = xf[2]
            sheet["A1"] = [ "key" "bus" "contribution [%]" "cost [US/MWh]"]
            tmp = sort([[i, load["load_bus"]] for (i,load) in ref[:load]], by = x->x[1])
            sheet["A2"] = reduce(vcat, tmp')

            XLSX.addsheet!(xf,"hourly peak load")
            sheet = xf[3]
            sheet["A1"] = "hourly peak load as a percentage of daily peak"
            sheet["B2"] = "winter weeks"
            sheet["B3"] = "1-8 & 44-52"
            sheet["D2"] = "summer weeks"
            sheet["D3"] = "18-30"
            sheet["F2"] = "spring/fall weeks"
            sheet["F3"] = "9-17 & 31-43"
            sheet["A4"] = "hour"
            sheet["A5:A28"] = [(i) for i in 0:23][:,:]
            sheet["B4:G4"] = ["Wkdy" "Wknd"	"Wkdy" "Wknd" "Wkdy" "Wknd"]

            XLSX.addsheet!(xf,"daily peak load")
            sheet = xf[4]
            sheet["A1"] = "daily peak load as a % of weekly peak"
            sheet["A2"] = "day"
            sheet["B2"] = "peak load [%]"
            sheet["A3"] = ["Monday"; "Tuesday"; "Wednesday"; "Thursday"; "Friday"; "Saturday"; "Sunday"][:,:]

            XLSX.addsheet!(xf,"weekly peak load")
            sheet = xf[5]
            sheet["A1"] = "weekly peak load as a % of annual peak"
            sheet["A2"] = "week"
            sheet["B2"] = "peak load [%]"
            sheet["A3"] = [(i) for i in 1:52][:,:]

            XLSX.addsheet!(xf,"time series capacity")
            sheet = xf[6]
            sheet["A1"] = "Keep worksheet blank if no time series data is available"
        end
    end

    if in(InputData).("generators") == true 
        XLSX.openxlsx("generators.xlsx", mode="w") do xf

            sheet = xf[1]
            XLSX.rename!(sheet, "core")
            sheet["A1"] = ["key" "bus" "pmax [MW]" "qmax [MVAR]" "failurerate [f/year]" "repairrate [r/year]" "category [optional]" "timeseries [true/false?]"]
            tmp = sort([[i, gen["gen_bus"], 
                        gen["pmax"]*network.baseMVA,
                        gen["qmax"]*network.baseMVA] for (i,gen) in ref[:gen]], by = x->x[1])
            sheet["A2"] = reduce(vcat, tmp')

            XLSX.addsheet!(xf,"time series capacity")
            sheet = xf[2]
            sheet["A1"] = "Keep worksheet blank if no timeseries data is available"
        end
    end

    if in(InputData).("storages") == true     
        if isempty(ref[:storage]) == false

            XLSX.openxlsx("storages.xlsx", mode="w") do xf

                sheet = xf[1]
                XLSX.rename!(sheet, "core")
                sheet["A1"] = ["key" "bus" "chargecapacity" "dischargecapacity" "energycapacity" "chargeefficiency" "dischargeefficiency" "carryoverefficiency" "category [optional]" "failurerate [f/year]" "repairrate [r/year]" "timeseries [true/false?]"]
                tmp = sort([[i, stor["storage_bus"],
                            stor["charge_rating"]*network.baseMVA, 
                            stor["discharge_rating"]*network.baseMVA,
                            stor["energy_rating"]*network.baseMVA, 
                            stor["charge_efficiency"],
                            stor["discharge_efficiency"]] for (i,stor) in ref[:storage]], by = x->x[1])
                sheet["A2"] = reduce(vcat, tmp')

                XLSX.addsheet!(xf,"time series capacity")
                sheet = xf[2]
                sheet["A1"] = "Keep worksheet blank if no time series data is available"
            end

        end
    end

    if in(InputData).("branches") == true    
        XLSX.openxlsx("branches.xlsx", mode="w") do xf

            sheet = xf[1]
            XLSX.rename!(sheet, "core")
            sheet["A1"] = ["key" "fbus" "tbus" "rate_a [MW]" "rate_b [MW]" "category [optional]" "failurerate [f/year]" "repairrate [r/year]" "timeseries [true/false?]"]
            tmp = sort([[i,
                        branch["f_bus"], 
                        branch["t_bus"],
                        branch["rate_a"]*network.baseMVA,
                        branch["rate_b"]*network.baseMVA] for (i,branch) in ref[:branch]], by = x->x[1])
            sheet["A2"] = reduce(vcat, tmp')

            XLSX.addsheet!(xf,"time series capacity")
            sheet = xf[2]
            sheet["A1"] = "Keep worksheet blank if no time series data is available"

        end
    end
    
    cd(CurrentDir)
    return network, ref, ReliabilityDataDir

end


#vector = collect(timestamps)
#for  step in vector
#    if Dates.week(step)>=1 && Dates.week(step)<=8 || Dates.week(step)>=44 && Dates.week(step)<=53


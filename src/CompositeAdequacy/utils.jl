
BaseModule.field(method::SimulationSpec, field::Symbol) = getfield(method, field)

function Base.map!(f, dict::Dict)

    vals = dict.vals
    # is here so that it gets propagated to isslotfilled
    for i = dict.idxfloor:lastindex(vals)
        if Base.isslotfilled(dict, i)
            vals[i] = f(vals[i])
        end
    end
    return
end

""
function findfirstunique_directional(a::AbstractVector{<:Pair}, i::Pair)
    i_idx = findfirst(isequal(i), a)
    if isnothing(i_idx)
        i_idx = findfirstunique(a, last(i) => first(i))
        reverse = true
    else
        reverse = false
    end
    return i_idx, reverse
end

""
function findfirstunique(a::AbstractVector{T}, i::T) where T
    i_idx = findfirst(isequal(i), a)
    i_idx === nothing && throw(BoundsError(a))
    return i_idx
end

""
function colsum(x::Matrix{T}, col::Integer) where {T}
    result = zero(T)
    for i in 1:size(x, 1)
        result += x[i, col]
    end
    return result
end

""
function check_status(a::SubArray{Bool, 1, Matrix{Bool}, Tuple{Base.Slice{Base.OneTo{Int}}, Int}, true})
    i_idx = findfirst(isequal(0), a)
    if i_idx === nothing i_idx=true else i_idx=false end
    return i_idx
end

""
function check_status(a::Vector{Bool})
    i_idx = findfirst(isequal(0), a)
    if i_idx === nothing i_idx=true else i_idx=false end
    return i_idx
end

""
function _sol(sol::Dict, args...)
    for arg in args
        if haskey(sol, arg)
            sol = sol[arg]
        else
            sol = sol[arg] = Dict()
        end
    end

    return sol
end

"""
    print_results(system::SystemModel, shortfall::ShortfallResult)

Export the results of the `shortfall` analysis into a uniquely named Excel file. 

The filename is generated based on the current time, ensuring each file has a distinct name to avoid overwriting 
previous results. This function systematically captures and records a variety of key metrics related to the `shortfall` 
analysis of the given system model, such as:

1. Parameters and ratings of any storages in the system, if present.
2. Metrics like Expected Energy Not Supplied (EENS), Expected Duration of Load Curtailment (EDLC), and System Index (SI), 
    both for individual buses and the system as a whole.
3. Statistical parameters such as standard errors for the above metrics.
4. Period-based analyses like the mean and standard deviation of the event period, both at the bus and system level.
5. Shortfall metrics, including the standard deviations at the bus, period, and overall system levels.

Each of these metrics is systematically written into separate columns of the primary summary sheet. 
The function also adds supplementary sheets detailing further metrics like the mean and standard deviation of 
event periods and shortfalls.

The output Excel file offers a structured and detailed snapshot of the `shortfall` analysis, aiding in a 
comprehensive understanding and subsequent reviews.

# Arguments
- `system::SystemModel`: The system model being analyzed.
- `shortfall::ShortfallResult`: The resultant data from the shortfall analysis.

# Output
The function writes an Excel file named "Shortfall_<current_time>.xlsx" to the disk and doesn't return 
any values in the Julia environment.
"""

function print_results(system::SystemModel, shortfall::ShortfallResult)
    # Get current time for unique filename
    hour = Dates.format(Dates.now(), "HH_MM_SS")
    
    openxlsx("Shortfall_" * hour * ".xlsx", mode="w") do xf
        # Define the primary summary sheet
        sheet = xf[1]
        rename!(sheet, "summary")

        # If there are storages in the system, record their data
        if length(system.storages) > 0
            storage_info = ["energy_rating", "buses", "charge_rating", "discharge_rating", "thermal_rating"]
            storage_values = [
                system.storages.energy_rating[1], 
                system.storages.buses[1],
                system.storages.charge_rating[1],
                system.storages.discharge_rating[1],
                system.storages.thermal_rating[1]
            ]

            for (index, info) in enumerate(storage_info)
                sheet["A$(index)"] = info
                sheet["B$(index)"] = storage_values[index]
            end
        end

        # Capture shortfall-related parameters and metrics

        # For [mean bus EENS, mean system EENS]
        sheet["C1"] = "[mean bus EENS, mean system EENS]"
        means = vcat(collect(val.(EENS.(shortfall, system.buses.keys))), [val.(EENS.(shortfall))])
        for (i, mean_value) in enumerate(means)
            sheet["C$(i+1)"] = mean_value
        end

        # For [mean bus EDLC, mean system EDLC]
        sheet["D1"] = "[mean bus EDLC, mean system EDLC]"
        means = vcat(collect(val.(EDLC.(shortfall, system.buses.keys))), [val.(EDLC.(shortfall))])
        for (i, mean_value) in enumerate(means)
            sheet["D$(i+1)"] = mean_value
        end

        # For [mean bus SI, mean system SI]
        sheet["E1"] = "[mean bus SI, mean system SI]"
        means = vcat(collect(val.(SI.(shortfall, system.buses.keys))), [val.(SI.(shortfall))])
        for (i, mean_value) in enumerate(means)
            sheet["E$(i+1)"] = mean_value
        end

        # For [stderror bus EENS, stderror system EENS]
        sheet["F1"] = "[stderror bus EENS, stderror system EENS]"
        stderrors = vcat(collect(stderror.(EENS.(shortfall, system.buses.keys))), [stderror.(EENS.(shortfall))])
        for (i, stderror_value) in enumerate(stderrors)
            sheet["F$(i+1)"] = stderror_value
        end

        # For [stderror bus EENS, stderror system EENS]
        sheet["G1"] = "[stderror bus EDLC, stderror system EDLC]"
        stderrors = vcat(collect(stderror.(EDLC.(shortfall, system.buses.keys))), [stderror.(EDLC.(shortfall))])
        for (i, stderror_value) in enumerate(stderrors)
            sheet["G$(i+1)"] = stderror_value
        end

        # For [stderror bus EENS, stderror system EENS]
        sheet["H1"] = "[stderror bus SI, stderror system SI]"
        stderrors = vcat(collect(stderror.(SI.(shortfall, system.buses.keys))), [stderror.(SI.(shortfall))])
        for (i, stderror_value) in enumerate(stderrors)
            sheet["H$(i+1)"] = stderror_value
        end

        xf[1]["I1"] = "eventperiod_mean"
        xf[1]["I2"] = shortfall.eventperiod_mean
        xf[1]["J1"] = "eventperiod_std"
        xf[1]["J2"] = shortfall.eventperiod_std
        xf[1]["K1"] = "eventperiod_bus_mean"
        xf[1]["K2", dim=1] = collect(shortfall.eventperiod_bus_mean)
        xf[1]["L1"] = "eventperiod_bus_std"
        xf[1]["L2", dim=1] = collect(shortfall.eventperiod_bus_std)
        xf[1]["M1"] = "eventperiod_period_mean"
        xf[1]["M2", dim=1] = collect(shortfall.eventperiod_period_mean)
        xf[1]["N1"] = "eventperiod_period_std"
        xf[1]["N2", dim=1] = collect(shortfall.eventperiod_period_std)
        xf[1]["O1"] = "shortfall_std"
        xf[1]["O2"] = shortfall.shortfall_std
        xf[1]["P1"] = "shortfall_bus_std"
        xf[1]["P2", dim=1] = collect(shortfall.shortfall_bus_std)
        xf[1]["Q1"] = "shortfall_period_std"
        xf[1]["Q2", dim=1] = collect(shortfall.shortfall_period_std)

        # Additional sheets can be added using:
        addsheet!(xf, "eventperiod_busperiod_mean")
        xf[2]["A1"] = collect(shortfall.eventperiod_busperiod_mean')
        addsheet!(xf, "eventperiod_busperiod_std")
        xf[3]["A1"] = collect(shortfall.eventperiod_busperiod_std')
        addsheet!(xf, "shortfall_mean")
        xf[4]["A1"] = collect(shortfall.shortfall_mean')
        addsheet!(xf, "shortfall_busperiod_std")
        xf[5]["A1"] = collect(shortfall.shortfall_busperiod_std')
    end

    return
end

"""
    print_results(system::SystemModel, utilization::UtilizationResult)

Save the results of the `utilization` analysis to an Excel file. The filename is timestamped to ensure 
uniqueness of the output. The function captures the system storage information and metrics related to the 
utilization analysis, such as utilization means, standard deviations, and probabilities of thermal violations. 
These results are structured into separate sheets and rows within the Excel file for easy interpretation.
"""
function print_results(system::SystemModel, utilization::UtilizationResult)

    # Get current time for unique filename
    hour = Dates.format(Dates.now(), "HH_MM_SS")

    openxlsx("Utilization_"*hour*".xlsx", mode="w") do xf
        # Define the primary summary sheet
        sheet = xf[1]
        rename!(sheet, "summary")

        # If there are storages in the system, record their data
        if length(system.storages) > 0
            storage_info = ["energy_rating", "buses", "charge_rating", "discharge_rating", "thermal_rating"]
            storage_values = [
                system.storages.energy_rating[1], 
                system.storages.buses[1],
                system.storages.charge_rating[1],
                system.storages.discharge_rating[1],
                system.storages.thermal_rating[1]
            ]

            for (index, info) in enumerate(storage_info)
                sheet["A$(index)"] = info
                sheet["B$(index)"] = storage_values[index]
            end
        end

        xf[1]["C1"] = "Utilization (Mean) per branch per year"
        xf[1]["C2", dim=1] = collect([x[1] for x in getindex(utilization, :)])
        xf[1]["D1"] = "Utilization (Std) per branch per year"
        xf[1]["D2", dim=1] = collect([x[2] for x in getindex(utilization, :)])
        xf[1]["E1"] = "Prob of thermal violation (Mean) per branch per year"
        xf[1]["E2", dim=1] = collect([x[1] for x in CompositeAdequacy.PTV(utilization, :)])
        xf[1]["F1"] = "Prob of thermal violation (Std) per branch per year"
        xf[1]["F2", dim=1] = collect([x[2] for x in CompositeAdequacy.PTV(utilization, :)])

        addsheet!(xf, "utilization_mean")
        xf[2]["A1"] = collect(utilization.utilization_mean')
        addsheet!(xf, "utilization_branch_std")
        xf[3]["A1"] = collect(utilization.utilization_branch_std)
        addsheet!(xf, "utilization_branchperiod_std")
        xf[4]["A1"] = collect(utilization.utilization_branchperiod_std')
        addsheet!(xf, "ptv_mean")
        xf[5]["A1"] = collect(utilization.ptv_mean')
        addsheet!(xf, "ptv_branch_std")
        xf[6]["A1"] = collect(utilization.ptv_branch_std)
        addsheet!(xf, "ptv_branchperiod_std")
        xf[7]["A1"] = collect(utilization.ptv_branchperiod_std')
    end
    return
end

"""
    print_results(system::SystemModel, capvalue::CapacityValueResult)

Export the results of the `capvalue` (Capacity Value) analysis into an Excel file. 
The filename is generated based on the current timestamp to ensure its uniqueness.

Within the Excel file:
1. A primary 'summary' sheet captures essential data.
2. If storages are present in the `system`, their specifications, such as energy rating, buses, charge rating, discharge rating, and thermal rating, are logged.
3. Metrics related to the Capacity Value are saved, including:
    - Value and standard error of target metric
    - Value and standard error of SI (System Index) metric
    - Value and standard error of EENS (Expected Energy Not Supplied) metric
    - Value and standard error of EDLC (Expected Duration of Load Curtailed) metric
    - Overall capacity value and its tolerance error
4. Metrics are organized in a structured manner for comprehensive data presentation. 
This includes the bound capacities and their corresponding SI, EENS, and EDLC metrics, both in terms of values and standard errors.

The function is designed to provide a quick and systematic snapshot of the Capacity Value analysis for further review and decision-making processes.
"""
function print_results(system::SystemModel, capvalue::CapacityValueResult)

    hour = Dates.format(Dates.now(),"HH_MM_SS")
    
    openxlsx("ELCC_"*hour*".xlsx", mode="w") do xf
        # Define the primary summary sheet
        sheet = xf[1]
        rename!(sheet, "summary")

        # If there are storages in the system, record their data
        if length(system.storages) > 0
            storage_info = ["energy_rating", "buses", "charge_rating", "discharge_rating", "thermal_rating"]
            storage_values = [
                system.storages.energy_rating[1], 
                system.storages.buses[1],
                system.storages.charge_rating[1],
                system.storages.discharge_rating[1],
                system.storages.thermal_rating[1]
            ]

            for (index, info) in enumerate(storage_info)
                sheet["A$(index)"] = info
                sheet["B$(index)"] = storage_values[index]
            end
        end

        xf[1]["C1"] = "val (target_metric)"
        xf[1]["D1"] = val(capvalue.target_metric)
        xf[1]["C2"] = "stderror (target_metric)"
        xf[1]["D2"] = stderror(capvalue.target_metric)

        xf[1]["C3"] = "val (SI_metric)"
        xf[1]["D3"] = val(capvalue.si_metric)
        xf[1]["C4"] = "stderror (SI_metric)"
        xf[1]["D4"] = stderror(capvalue.si_metric)

        xf[1]["C5"] = "val (EENS_metric)"
        xf[1]["D5"] = val(capvalue.eens_metric)
        xf[1]["C6"] = "stderror (EENS_metric)"
        xf[1]["D6"] = stderror(capvalue.eens_metric)

        xf[1]["C7"] = "val (EDLC_metric)"
        xf[1]["D7"] = val(capvalue.edlc_metric)
        xf[1]["C8"] = "stderror (EDLC_metric)"
        xf[1]["D8"] = stderror(capvalue.edlc_metric)

        xf[1]["C9"] = "capacity_value"
        xf[1]["D9"] = capvalue.capacity_value
        xf[1]["C10"] = "tolerance_error"
        xf[1]["D10"] = capvalue.tolerance_error

        xf[1]["F1"] = "bound_capacities"
        xf[1]["F2", dim=1] = collect(capvalue.bound_capacities)
        xf[1]["G1"] = "SI_metrics - val"
        xf[1]["G2", dim=1] = collect(val.(capvalue.si_metrics))
        xf[1]["H1"] = "SI_metrics - stderror"
        xf[1]["H2", dim=1] = collect(stderror.(capvalue.si_metrics))
        xf[1]["I1"] = "EENS_metrics - val"
        xf[1]["I2", dim=1] = collect(val.(capvalue.eens_metrics))
        xf[1]["J1"] = "EENS_metrics - stderror"
        xf[1]["J2", dim=1] = collect(stderror.(capvalue.eens_metrics))

        xf[1]["K1"] = "EDLC_metrics - val"
        xf[1]["K2", dim=1] = collect(val.(capvalue.edlc_metrics))
        xf[1]["L1"] = "EDLC_metrics - stderror"
        xf[1]["L2", dim=1] = collect(stderror.(capvalue.edlc_metrics))
    end
    return
end
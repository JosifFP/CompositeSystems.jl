
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

""
function print_results(system::SystemModel, shortfall::ShortfallResult)

    hour = Dates.format(Dates.now(),"HH_MM_SS")
    
    openxlsx("Shortfall_"*hour*".xlsx", mode="w") do xf
        rename!(xf[1], "summary")

        if length(system.storages) > 0
            xf[1]["A1"] =  "energy_rating"
            xf[1]["B1"] = system.storages.energy_rating[1]
            xf[1]["A2"] =  "buses"
            xf[1]["B2"] = system.storages.buses[1]
            xf[1]["A3"] =  "charge_rating"
            xf[1]["B3"] = system.storages.charge_rating[1]
            xf[1]["A4"] =  "discharge_rating"
            xf[1]["B4"] = system.storages.discharge_rating[1]
            xf[1]["A5"] =  "thermal_rating"
            xf[1]["B5"] = system.storages.thermal_rating[1]
        end

        xf[1]["C1"] = "mean system EENS"
        xf[1]["C2"] = val.(EENS.(shortfall))
        xf[1]["D1"] = "stderror EENS"
        xf[1]["D2"] = stderror.(EENS.(shortfall))
        xf[1]["E1"] = "EENS-MEAN"
        xf[1]["E2", dim=1] = collect(val.(EENS.(shortfall, system.buses.keys)))
        xf[1]["F1"] = "EENS-STDERROR"
        xf[1]["F2", dim=1] = collect(stderror.(EENS.(shortfall, system.buses.keys)))

        xf[1]["G1"] = "mean system EDLC"
        xf[1]["G2"] = val.(EDLC.(shortfall))
        xf[1]["H1"] = "stderror EDLC"
        xf[1]["H2"] = stderror.(EDLC.(shortfall))
        xf[1]["I1"] = "EDLC-MEAN"
        xf[1]["I2", dim=1] = collect(val.(EDLC.(shortfall, system.buses.keys)))
        xf[1]["J1"] = "EDLC-STDERROR"
        xf[1]["J2", dim=1] = collect(stderror.(EDLC.(shortfall, system.buses.keys)))

        xf[1]["K1"] = "mean system SI"
        xf[1]["K2"] = val.(SI.(shortfall))
        xf[1]["L1"] = "stderror SI"
        xf[1]["L2"] = stderror.(SI.(shortfall))
        xf[1]["M1"] = "SI-MEAN"
        xf[1]["M2", dim=1] = collect(val.(SI.(shortfall, system.buses.keys)))
        xf[1]["N1"] = "SI-STDERROR"
        xf[1]["N2", dim=1] = collect(stderror.(SI.(shortfall, system.buses.keys)))

        xf[1]["O1"] = "eventperiod_mean"
        xf[1]["O2"] = shortfall.eventperiod_mean
        xf[1]["P1"] = "eventperiod_std"
        xf[1]["P2"] = shortfall.eventperiod_std
        xf[1]["Q1"] = "eventperiod_bus_mean"
        xf[1]["Q2", dim=1] = collect(shortfall.eventperiod_bus_mean)
        xf[1]["R1"] = "eventperiod_bus_std"
        xf[1]["R2", dim=1] = collect(shortfall.eventperiod_bus_std)
        xf[1]["S1"] = "eventperiod_period_mean"
        xf[1]["S2", dim=1] = collect(shortfall.eventperiod_period_mean)
        xf[1]["T1"] = "eventperiod_period_std"
        xf[1]["T2", dim=1] = collect(shortfall.eventperiod_period_std)
        xf[1]["U1"] = "shortfall_std"
        xf[1]["U2"] = shortfall.shortfall_std
        xf[1]["V1"] = "shortfall_bus_std"
        xf[1]["V2", dim=1] = collect(shortfall.shortfall_bus_std)
        xf[1]["W1"] = "shortfall_period_std"
        xf[1]["W2", dim=1] = collect(shortfall.shortfall_period_std)

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

""
function print_results(system::SystemModel, utilization::UtilizationResult)

    hour = Dates.format(Dates.now(),"HH_MM_SS")

    openxlsx("Utilization_"*hour*".xlsx", mode="w") do xf
        rename!(xf[1], "summary")

        if length(system.storages) > 0
            xf[1]["A1"] =  "energy_rating"
            xf[1]["B1"] = system.storages.energy_rating[1]
            xf[1]["A2"] =  "buses"
            xf[1]["B2"] = system.storages.buses[1]
            xf[1]["A3"] =  "charge_rating"
            xf[1]["B3"] = system.storages.charge_rating[1]
            xf[1]["A4"] =  "discharge_rating"
            xf[1]["B4"] = system.storages.discharge_rating[1]
            xf[1]["A5"] =  "thermal_rating"
            xf[1]["B5"] = system.storages.thermal_rating[1]
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

""
function print_results(system::SystemModel, capcredit::CapacityCreditResult)

    hour = Dates.format(Dates.now(),"HH_MM_SS")
    
    openxlsx("ELCC_"*hour*".xlsx", mode="w") do xf
        rename!(xf[1], "summary")

        if length(system.storages) > 0
            xf[1]["A1"] =  "energy_rating"
            xf[1]["B1"] = system.storages.energy_rating[1]
            xf[1]["A2"] =  "buses"
            xf[1]["B2"] = system.storages.buses[1]
            xf[1]["A3"] =  "charge_rating"
            xf[1]["B3"] = system.storages.charge_rating[1]
            xf[1]["A4"] =  "discharge_rating"
            xf[1]["B4"] = system.storages.discharge_rating[1]
            xf[1]["A5"] =  "thermal_rating"
            xf[1]["B5"] = system.storages.thermal_rating[1]
        end

        xf[1]["C1"] = "target_metric"
        xf[1]["D1"] = string(capcredit.target_metric)
        xf[1]["C2"] = "val (ELCC)"
        xf[1]["D2"] = val(capcredit.target_metric)
        xf[1]["C3"] = "stderror (ELCC)"
        xf[1]["D3"] = stderror(capcredit.target_metric)
        xf[1]["C4"] = "lowerbound"
        xf[1]["D4"] = capcredit.lowerbound
        xf[1]["C5"] = "upperbound"
        xf[1]["D5"] = capcredit.upperbound
        xf[1]["C6"] = "minimum"
        xf[1]["D6"] = minimum(capcredit)
        xf[1]["C7"] = "maximum"
        xf[1]["D7"] = maximum(capcredit)
        xf[1]["C8"] = "extrema"
        xf[1]["D8"] = string(extrema(capcredit))

        xf[1]["E1"] = "bound_capacities"
        xf[1]["E2", dim=1] = collect(capcredit.bound_capacities)
        xf[1]["F1"] = "bound_metrics - val"
        xf[1]["F2", dim=1] = collect(val.(capcredit.bound_metrics))
        xf[1]["G1"] = "bound_metrics - stderror"
        xf[1]["G2", dim=1] = collect(stderror.(capcredit.bound_metrics))
        xf[1]["H1"] = "bound_metrics"
        xf[1]["H2"] = collect(string.(capcredit.bound_metrics))
    end
    return
end
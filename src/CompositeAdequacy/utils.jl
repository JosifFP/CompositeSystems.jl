
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
    openxlsx("results_shortfall"*Dates.format(Dates.now(),"HHMMSS")*".xlsx", mode="w") do xf

        rename!(xf[1], "summary")

        xf[1]["A1"] = "mean system EDLC"
        xf[1]["A2"] = val.(EDLC.(shortfall))
        xf[1]["B1"] = "stderror EDLC"
        xf[1]["B2"] = stderror.(EDLC.(shortfall))
        xf[1]["C1"] = "EDLC-MEAN"
        xf[1]["C2", dim=1] = collect(val.(EDLC.(shortfall, system.buses.keys)))
        xf[1]["D1"] = "EDLC-STDERROR"
        xf[1]["D2", dim=1] = collect(stderror.(EDLC.(shortfall, system.buses.keys)))

        xf[1]["E1"] = "mean system EENS"
        xf[1]["E2"] = val.(EENS.(shortfall))
        xf[1]["F1"] = "stderror EENS"
        xf[1]["F2"] = stderror.(EENS.(shortfall))
        xf[1]["G1"] = "EENS-MEAN"
        xf[1]["G2", dim=1] = collect(val.(EENS.(shortfall, system.buses.keys)))
        xf[1]["H1"] = "EENS-STDERROR"
        xf[1]["H2", dim=1] = collect(stderror.(EENS.(shortfall, system.buses.keys)))

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

        if length(system.storages) > 0
            xf[1]["R1"] =  "energy_rating"
            xf[1]["R1"] = system.storages.energy_rating[1]
            xf[1]["R2"] =  "buses"
            xf[1]["S2"] = system.storages.buses[1]
            xf[1]["R3"] =  "charge_rating"
            xf[1]["S3"] = system.storages.charge_rating[1]
            xf[1]["R4"] =  "discharge_rating"
            xf[1]["S4"] = system.storages.discharge_rating[1]
            xf[1]["R5"] =  "thermal_rating"
            xf[1]["S5"] = system.storages.thermal_rating[1]
        end

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
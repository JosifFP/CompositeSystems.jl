const ANNUAL_HOURS = 8760

bus_fields = [
    ("index", Int),
    ("zone", Int),
    ("bus_type", Int),
    ("bus_i", Int),
    ("vmax", Float32),
    ("vmin", Float32),
    ("base_kv", Float32),
    ("va", Float32),
    ("vm", Float32)
]

const gen_fields = [
    ("index", Int),
    ("gen_bus", Int),
    ("pg", Float32), 
    ("qg", Float32),
    ("vg", Float32),
    ("pmax", Float32), 
    ("pmin", Float32),
    ("qmax", Float32), 
    ("qmin", Float32),
    ("mbase", Float32),
    ("cost", Vector{Any}),
    ("state_model", Int),
    ("λ_updn", Float64),
    ("μ_updn", Float64),
    ("λ_upde", Float64),
    ("μ_upde", Float64),
    ("pde", Float32),
    ("gen_status", Bool)
]

const branch_fields = [
    ("index", Int),
    ("f_bus", Int),
    ("t_bus", Int),
    ("common_mode", Int),
    ("rate_a", Float32),
    ("rate_b", Float32),
    ("br_r", Float32), 
    ("br_x", Float32),
    ("b_fr", Float32), 
    ("b_to", Float32),
    ("g_fr", Float32), 
    ("g_to", Float32),
    ("shift", Float32),
    ("angmin", Float32), 
    ("angmax", Float32),
    ("transformer", Bool),
    ("tap", Float32),
    ("λ_updn", Float64),
    ("μ_updn", Float64),
    ("br_status", Bool)
]

const shunt_fields = [
    ("index", Int),
    ("shunt_bus", Int),
    ("bs", Float32),
    ("gs", Float32),
    ("status", Bool)
]

const interface_fields = [
    ("index", Int),
    ("f_bus", Int),
    ("t_bus", Int),
    ("λ_updn", Float64),
    ("μ_updn", Float64),
]

const load_fields = [
    ("index", Int),
    ("load_bus", Int),
    ("pd", Float32),
    ("qd", Float32),
    ("pf", Float32),
    ("cost", Float32),
    ("status", Bool)
]

const storage_fields = [
    ("index", Int),
    ("storage_bus", Int),
    ("ps", Float32),
    ("qs", Float32),
    ("energy", Float32),
    ("energy_rating", Float32),
    ("charge_rating", Float32),
    ("discharge_rating", Float32),
    ("charge_efficiency", Float32),
    ("discharge_efficiency", Float32),    
    ("thermal_rating", Float32),
    ("qmax", Float32),
    ("qmin", Float32),
    ("r", Float32),
    ("x", Float32),
    ("p_loss", Float32),
    ("q_loss", Float32),
    ("λ_updn", Float64),
    ("μ_updn", Float64),
    ("status", Bool)
]

const compositesystems_fields = [
    ("state_model", Int),
    ("λ_updn", Float64),
    ("μ_updn", Float64),
    ("common_mode", Int),
    ("λ_common", Float64),
    ("μ_common", Float64),
    ("λ_upde", Float64),
    ("μ_upde", Float64),
    ("pde", Float32),
    ("cost", Float32)
]

const r_gen = [
    ("bus", Int),
    ("pmax", Float32),
    ("state_model", Int),
    ("λ_updn", Float64),
    ("μ_updn", Float64),
    ("λ_upde", Float64),
    ("μ_upde", Float64),
    ("pde", Float32),
    ("index", Int)
]

const r_storage = [
    ("bus", Int),
    ("energy_rating", Float32),
    ("λ_updn", Float64),
    ("μ_updn", Float64),
    ("index", Int)
]

const r_branch = [
    ("f_bus", Int),
    ("t_bus", Int),
    ("λ_updn", Float64),
    ("μ_updn", Float64),
    ("common_mode", Int),
    ("λ_common", Float64),
    ("μ_common", Float64),
    ("index", Int)
]

const r_load = [
    ("bus_i", Int),
    ("cost", Float32),
    ("index", Int)
]


"""
    static_parameters{N, L, T}

A structure for managing system timestamps.

- `N`: Number of timestamps.
- `L`: Length of the period.
- `T`: Type of the period (e.g., `Dates.Hour`).

Handles timestamp generation for a given system, starting from an optional `start_timestamp`. 
Timestamps are adjusted according to a provided timezone (defaults to UTC if none or an invalid one is provided).

# Examples
```jldoctest
julia> sp = static_parameters{10, 1, Dates.Hour}()
julia> first(sp.timestamps)
2023-05-15T00:00:00+00:00

julia> sp = static_parameters{10, 1, Dates.Hour}(DateTime(2022,1,1), "America/New_York")
julia> first(sp.timestamps)
2022-01-01T00:00:00-05:00

Note: Static parameters must match with time-series data.
"""
struct static_parameters{N, L, T}
    timestamps::StepRange{ZonedDateTime, T}

    function static_parameters{N, L, T}(
        start_timestamp::Union{DateTime, Nothing} = nothing, timezone::Union{String, Nothing} = "UTC") where {N, L, T <: Period}
        
        if isnothing(start_timestamp)
            @warn "No start timestamp provided - defaulting to current date and time."
            start_timestamp = DateTime(now())
        end
        
        if isnothing(timezone) || !valid_timezone(timezone)
            @warn "Invalid or no time zone data provided - defaulting to UTC."
            timezone = "UTC"
        end

        timestamps = range(start_timestamp, length=N, step=T(L))
        tz = TimeZone(timezone)
        time_start = ZonedDateTime(first(timestamps), tz)
        time_end = ZonedDateTime(last(timestamps), tz)
        timestamps_tz = time_start:step(timestamps):time_end

        return new{N, L, T}(timestamps_tz)
    end
end

""
function valid_timezone(timezone::String)::Bool
    try
        TimeZone(timezone)
        return true
    catch
        return false
    end
end


"""
    container(dict::Dict{Int, <:Any}, type::Vector{Tuple{String, DataType}}) -> Dict{String, Vector{<:Any}}

Reformat a nested dictionary based on a desired key-type structure.

This function performs the following tasks:
- Ensures that every inner dictionary of `dict` conforms to the key-type pairs defined in `type`.
- If a key is missing and is recognized by `compositesystems_fields`, it gets a default value of 0.
- Specific keys, like "rate_a" and "rate_b", when missing, are set to `Inf32`.
- Aggregates values of the same key across different inner dictionaries into vectors.
- Reorders these vectors based on the "index" key's ordering.

# Arguments
- `dict`: Input dictionary to process.
- `type`: A vector of tuples detailing desired keys and their types.

# Returns
- A transformed dictionary with values aggregated into vectors.
"""
function container(dict::Dict{Int, <:Any}, type::Vector{Tuple{String, DataType}})

    # Check if compositesystems_fields is defined in the current scope
    if !@isdefined(compositesystems_fields)
        throw(ArgumentError("compositesystems_fields must be defined in the current scope"))
    end

    for (_, v) in dict
        for (key, dtype) in type
            if haskey(v, key)
                v[key] = dtype(v[key])
            elseif (key, dtype) in compositesystems_fields
                get!(v, key, dtype(0))
            elseif key in ["rate_a", "rate_b"]
                get!(v, key, Inf32)
            end
        end
    end

    tmp = Dict{String, Vector{<:Any}}(key => [d[key] for d in values(dict) if haskey(d, key)] for (key, _) in type)

    if haskey(tmp, "index")
        key_order::Vector{Int} = sortperm(tmp["index"])
        for (k, v) in tmp
            tmp[k] = v[key_order]
        end
    end

    return tmp
end


"""
    extract_reliability_data(file::String) -> Dict{String, Any}

Extracts reliability data from a MATLAB file.

This function reads and parses the MATLAB-formatted reliability data from the specified file, and then returns it as a dictionary.

# Arguments
- `file::String`: Path to the MATLAB file.

# Returns
- A dictionary containing the parsed reliability data.

# Example
```jldoctest
julia> reliability = extract_reliability_data("path_to_file.mat");
julia> typeof(reliability)
Dict{String, Any}
"""
function extract_reliability_data(file::String)::Dict{String, Any}
    return open(file) do io
        matlab_data = _IM.parse_matlab_string(read(io, String))
        return Dict{String, Any}(_extract_reliability_data(matlab_data))
    end
end


"""
    _extract_reliability_data(matlab_data::Dict{String, Any})::Dict{String, Any}

Extract reliability data from the provided MATLAB data.

The function processes the given MATLAB data dictionary, which is expected to contain 
key-value pairs corresponding to various elements such as generators (`"mpc.gen"`), 
storage units (`"mpc.storage"`), branches (`"mpc.branch"`), and loads (`"mpc.load"`). 
Each element's data is transformed from an array format into a dictionary format for 
easier access.

# Arguments
- `matlab_data`: A dictionary containing MATLAB data. Expected keys include `"mpc.gen"`, 
  `"mpc.storage"`, `"mpc.branch"`, and `"mpc.load"`.

# Returns
- A dictionary containing the processed reliability data for each key.

# Raises
- Errors if expected keys (e.g., `"mpc.gen"`, `"mpc.branch"`) are missing from the input `matlab_data`.

# Example
```julia
reliability_info = _extract_reliability_data(my_matlab_data)
"""
function _extract_reliability_data(matlab_data::Dict{String, Any})
    
    component_mappings = [
        ("mpc.gen", "gen", r_gen),
        ("mpc.storage", "storage", r_storage),
        ("mpc.branch", "branch", r_branch),
        ("mpc.load", "load", r_load)
    ]

    case = Dict{String,Any}()

    for (key, name, r_type) in component_mappings
        if haskey(matlab_data, key)
            component_list = []
            for (i, row) in enumerate(matlab_data[key])
                component_data = _IM.row_to_typed_dict(row, r_type)
                component_data["index"] = i
                push!(component_list, component_data)
            end
            case[name] = component_list
        elseif name in ["gen", "branch"]
            @error(string("no $name data found in matpower file. The file seems to be missing \"$key = [...];\""))
        end
    end

    # Convert list of dicts to dict of dicts
    for (k, v) in case
        case[k] = Dict(string(item["index"]) => item for item in v)
    end

    return case
end

"Returns network data container with reliability_data and timeseries_data merged"
function merge_compositesystems_data!(network::Dict{Symbol, Any}, reliability_data::Dict{String, Any}, timeseries_data::Dict{Int, Vector{Float32}})
    get!(network, :timeseries_load, timeseries_data)
    return _merge_compositesystems_data!(network, reliability_data)
end

"Returns network data container with reliability_data"
function merge_compositesystems_data!(network::Dict{Symbol, Any}, reliability_data::Dict{String, Any})
    get!(network, :timeseries_load, "")
    return _merge_compositesystems_data!(network, reliability_data)
end


"""
    _merge_compositesystems_data!(network, reliability_data)

Merges the given reliability data into the network data structure in place.

# Arguments
- `network::Dict{Symbol, Any}`: Main network data container.
- `reliability_data::Dict{String, Any}`: Reliability data to be merged.

# Returns
- `Dict{Symbol, Any}`: The merged network data.

# Notes
The function modifies the `network` dictionary in place by adding or updating fields with data from the `reliability_data` dictionary.
"""
function _merge_compositesystems_data!(network::Dict{Symbol, Any}, reliability_data::Dict{String, Any})

    for (k,v) in network[:gen]
        i = string(k)
        if haskey(reliability_data["gen"], i) 
            if v["gen_bus"] == reliability_data["gen"][i]["bus"] && v["pmax"]*v["mbase"] == reliability_data["gen"][i]["pmax"]
                get!(v, "state_model", reliability_data["gen"][i]["state_model"])
                get!(v, "λ_updn", reliability_data["gen"][i]["λ_updn"]./ANNUAL_HOURS)
                get!(v, "μ_updn", reliability_data["gen"][i]["μ_updn"]./ANNUAL_HOURS)
                get!(v, "λ_upde", reliability_data["gen"][i]["λ_upde"]./ANNUAL_HOURS)
                get!(v, "μ_upde", reliability_data["gen"][i]["μ_upde"]./ANNUAL_HOURS)
                get!(v, "pde", reliability_data["gen"][i]["pde"])
            else
                @error("Generation reliability data does differ from network data")
            end
        else
            @error("Insufficient generation reliability data provided")
        end
    end

    for (k,v) in network[:storage]
        i = string(k)
        if haskey(reliability_data["storage"], i)
            if v["storage_bus"] == reliability_data["storage"][i]["bus"] && 
            v["energy_rating"]*network[:baseMVA] == reliability_data["storage"][i]["energy_rating"]
                get!(v, "λ_updn", reliability_data["storage"][i]["λ_updn"]./ANNUAL_HOURS)
                get!(v, "μ_updn", reliability_data["storage"][i]["μ_updn"]./ANNUAL_HOURS)
            else
                @error("Storage reliability data does differ from network data")
            end
        else
            @error("Insufficient storage reliability data provided")
        end
    end
    
    for (k,v) in network[:branch]
        i = string(k)
        if haskey(reliability_data["branch"], i)
            get!(v, "common_mode", reliability_data["branch"][i]["common_mode"])
            get!(v, "λ_updn", reliability_data["branch"][i]["λ_updn"]./ANNUAL_HOURS)
            get!(v, "μ_updn", reliability_data["branch"][i]["μ_updn"]./ANNUAL_HOURS)
        else
            @error("Insufficient transmission reliability data provided")
        end
    end
    
    for (k,v) in network[:load]
        i = string(k)
        if haskey(reliability_data["load"], i) && v["load_bus"] == reliability_data["load"][i]["bus_i"]
            get!(v, "cost", reliability_data["load"][i]["cost"])
        end
    end

    for (k,v) in reliability_data["branch"]
        if v["common_mode"] ≠ 0
            if !haskey(network[:interface], v["common_mode"])

                get!(network[:interface], v["common_mode"], 
                    Dict(
                        "index"=>v["common_mode"], 
                        "f_bus"=> v["f_bus"],
                        "t_bus"=> v["t_bus"], 
                        "λ_updn"=> v["λ_common"]./ANNUAL_HOURS,
                        "μ_updn"=> v["μ_common"]./ANNUAL_HOURS, 
                        "br_1"=>parse(Int, k))
                )
            
            elseif haskey(network[:interface], v["common_mode"]) && !haskey(v, "br_2")
                get!(network[:interface][v["common_mode"]], "br_2", parse(Int, k))
            else
                @error("Interfaces only supports two transmission lines between common buses")
            end
        end
    end
    
    return network
end


"""
    extract_timeseriesload(file::String)

Extracts time-series load data from the provided excel file `file`.

# Arguments:
- `file::String`: Path to the excel file.

# Returns:
- `Dict{Int, Vector{Float32}}`: A dictionary of timeseries data.
- `static_parameters`: An instance with relevant parameters extracted from the core sheet.

# Notes:
- The excel file should have at least two sheets named "core" and "load".
"""
function extract_timeseriesload(file::String)
    df = CSV.read(file, DataFrames.DataFrame)
    return Dict{Int, Vector{Float32}}(parse(Int, String(propertynames(df)[i])) => Float32.(df[!,propertynames(df)[i]]) for i in 2:length(propertynames(df)))
end

""
function convert_array(index_keys::Vector{Int}, timeseries_load::Dict{Int, Vector{Float32}}, baseMVA::Float64)

    if length(index_keys) ≠ length(collect(keys(timeseries_load)))
        @error("Time-series Load data file does not match length of load in network data file")
    end

    key_order_series = sortperm(collect(keys(timeseries_load)))

    container_timeseries = [Float32.(timeseries_load[i]/baseMVA) for i in keys(timeseries_load)]
    array::Array{Float32} = reduce(vcat,transpose.(container_timeseries[key_order_series]))

    return array

end

"""
    check_consistency(ref, buses, loads, branches, shunts, generators, storages)

Checks for inconsistencies between AbstractAsset and Power Model Network.
"""
function check_consistency(ref::Dict{Symbol, Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

    for k in buses.keys
        @assert haskey(ref[:bus],k) === true
        @assert Int.(ref[:bus][k]["bus_i"]) == buses.bus_i[k]
        @assert Int.(ref[:bus][k]["bus_type"]) == buses.bus_type[k]
        @assert Float32.(ref[:bus][k]["vmax"]) == buses.vmax[k]
        @assert Float32.(ref[:bus][k]["vmin"]) == buses.vmin[k]
        @assert Float32.(ref[:bus][k]["base_kv"]) == buses.base_kv[k]
        @assert Float32.(ref[:bus][k]["va"]) == buses.va[k]
        @assert Float32.(ref[:bus][k]["vm"]) == buses.vm[k]
    end
    
    for k in generators.keys
        @assert haskey(ref[:gen],k) == true
        @assert Int.(ref[:gen][k]["index"]) == generators.keys[k]
        @assert Int.(ref[:gen][k]["gen_bus"]) == generators.buses[k]
        @assert Float32.(ref[:gen][k]["qg"]) == generators.qg[k]
        @assert Float32.(ref[:gen][k]["vg"]) == generators.vg[k]
        @assert Float32.(ref[:gen][k]["pmax"]) == generators.pmax[k]
        @assert Float32.(ref[:gen][k]["pmin"]) == generators.pmin[k]
        @assert Float32.(ref[:gen][k]["qmax"]) == generators.qmax[k]
        @assert Float32.(ref[:gen][k]["qmin"]) == generators.qmin[k]
        @assert Float32.(ref[:gen][k]["mbase"]) == generators.mbase[k]
        @assert Bool.(ref[:gen][k]["gen_status"]) == generators.status[k]
    end
    
    for k in loads.keys
        @assert haskey(ref[:load],k) == true
        @assert Int.(ref[:load][k]["index"]) == loads.keys[k]
        @assert Int.(ref[:load][k]["load_bus"]) == loads.buses[k]
        @assert Float32.(ref[:load][k]["qd"]) == loads.qd[k]
        @assert Bool.(ref[:load][k]["status"]) == loads.status[k]
    end
    
    for k in branches.keys
        @assert haskey(ref[:branch],k) == true
        @assert Int.(ref[:branch][k]["index"]) == branches.keys[k]
        @assert Int.(ref[:branch][k]["f_bus"]) == branches.f_bus[k]
        @assert Int.(ref[:branch][k]["t_bus"]) == branches.t_bus[k]
        @assert Float32.(ref[:branch][k]["rate_a"]) == branches.rate_a[k]
        #@assert Float32.(ref[:branch][k]["rate_b"]) == branches.rate_b[k]
        @assert Float32.(ref[:branch][k]["br_r"]) == branches.r[k]
        @assert Float32.(ref[:branch][k]["br_x"]) == branches.x[k]
        @assert Float32.(ref[:branch][k]["b_fr"]) == branches.b_fr[k]
        @assert Float32.(ref[:branch][k]["b_to"]) == branches.b_to[k]
        @assert Float32.(ref[:branch][k]["g_fr"]) == branches.g_fr[k]
        @assert Float32.(ref[:branch][k]["g_to"]) == branches.g_to[k]
        @assert Float32.(ref[:branch][k]["shift"]) == branches.shift[k]
        @assert Float32.(ref[:branch][k]["angmin"]) == branches.angmin[k]
        @assert Float32.(ref[:branch][k]["angmax"]) == branches.angmax[k]
        @assert Bool.(ref[:branch][k]["transformer"]) == branches.transformer[k]
        @assert Float32.(ref[:branch][k]["tap"]) == branches.tap[k]
        @assert Bool.(ref[:branch][k]["br_status"]) == branches.status[k]
    end
    
    for k in shunts.keys
        @assert haskey(ref[:shunt],k) == true
        @assert Int.(ref[:shunt][k]["index"]) == shunts.keys[k]
        @assert Int.(ref[:shunt][k]["shunt_bus"]) == shunts.buses[k]
        @assert Float32.(ref[:shunt][k]["bs"]) == shunts.bs[k]
        @assert Float32.(ref[:shunt][k]["gs"]) == shunts.gs[k]
        @assert Bool.(ref[:shunt][k]["status"]) == shunts.status[k]
    end

    branches.keys === generators.keys && error("data race identified")
    branches.keys === loads.keys && error("data race identified")
    generators.keys === loads.keys && error("data race identified")
    generators === storages && error("data race identified")
    shunts === loads && error("data race identified")
    generators === loads && error("data race identified")
    generators === buses && error("data race identified")
    buses === loads && error("data race identified")

end

"Checks connectivity issues and status"
function check_connectivity(ref::Dict{Symbol, Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

    @assert(length(buses.keys) == length(ref[:bus])) # if this is not true something very bad is going on
    active_bus_ids = Set(bus["index"] for (i,bus) in ref[:bus] if bus["bus_type"] ≠ 4)

    for (i, gen) in ref[:gen]
        if !(gen["gen_bus"] in buses.keys) || !(generators.buses[i] in buses.keys)
            @error( "bus $(gen["gen_bus"]) in shunt $(i) is not defined")
        end
        if gen["gen_status"] ≠ 0 && !(gen["gen_bus"] in active_bus_ids)
            @warn( "active generator $(i) is connected to inactive bus $(gen["gen_bus"])")
        end
    end

    for (i, load) in ref[:load]
        if !(load["load_bus"] in buses.keys) || !(loads.buses[i] in buses.keys)
            @error( "bus $(load["load_bus"]) in load $(i) is not defined")
        end

        if load["status"] ≠ 0 && !(load["load_bus"] in active_bus_ids)
            @warn( "active load $(i) is connected to inactive bus $(load["load_bus"])")
        end       
    end

    for (i, shunt) in ref[:shunt]
        if !(shunt["shunt_bus"] in buses.keys) || !(shunts.buses[i] in buses.keys)
            @error( "bus $(shunt["shunt_bus"]) in shunt $(i) is not defined")
        end
        if shunt["status"] ≠ 0 && !(shunt["shunt_bus"] in active_bus_ids)
            @warn( "active shunt $(i) is connected to inactive bus $(shunt["shunt_bus"])")
        end
    end

    for (i, strg) in ref[:storage]
        if !(strg["storage_bus"] in buses.keys) || !(storages.buses[i] in buses.keys)
            @error( "bus $(strg["storage_bus"]) in shunt $(i) is not defined")
        end
        if strg["status"] ≠ 0 && !(strg["storage_bus"] in active_bus_ids)
            @warn( "active storage unit $(i) is connected to inactive bus $(strg["storage_bus"])")
        end
    end
    
    for (i, branch) in ref[:branch]
        if !(branch["f_bus"] in buses.keys) || !(branches.f_bus[i] in buses.keys)
            @error( "bus $(branch["f_bus"]) in shunt $(i) is not defined")
        end
        if !(branch["t_bus"] in buses.keys) || !(branches.t_bus[i] in buses.keys)
            @error( "bus $(branch["t_bus"]) in shunt $(i) is not defined")
        end
        if branch["br_status"] ≠ 0 && !(branch["f_bus"] in active_bus_ids)
            @warn( "active branch $(i) is connected to inactive bus $(branch["f_bus"])")
        end

        if branch["br_status"] ≠ 0 && !(branch["t_bus"] in active_bus_ids)
            @warn( "active branch $(i) is connected to inactive bus $(branch["t_bus"])")
        end

        # if dcline["br_status"] ≠ 0 && !(dcline["f_bus"] in active_bus_ids)
        #     @warn( "active dcline $(i) is connected to inactive bus $(dcline["f_bus"])")
        # end

        # if dcline["br_status"] ≠ 0 && !(dcline["t_bus"] in active_bus_ids)
        #     @warn( "active dcline $(i) is connected to inactive bus $(dcline["t_bus"])")
        # end
    end

end
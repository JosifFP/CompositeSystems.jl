"""
This structure ensures that the type instability of parametrics N and L are out of SystemModel structure and functions.
To be improved/enhanced.
"""
struct static_parameters{N,L,T}
    timestamps::StepRange{ZonedDateTime,T}
    function static_parameters{N,L,T}(start_timestamp::Union{Nothing, DateTime}, timezone::Union{Nothing, String}) where {N,L,T<:Period}

        if isnothing(start_timestamp) && isnothing(timezone)
            @warn "No time zone data provided - defaulting to UTC. To specify a " *
            "time zone for the system timestamps, provide a range of " *
            "`ZonedDateTime` instead of `DateTime`."
            start_timestamp = DateTime(Date(2022,1,1), Time(0,0,0))
            timezone = "UTC"
        end

        timestamps = range(start_timestamp, length=N, step=T(L))
        tz = TimeZone(timezone)
        time_start = ZonedDateTime(first(timestamps), tz)
        time_end = ZonedDateTime(last(timestamps), tz)
        timestamps_tz = time_start:step(timestamps):time_end

        return new{N,L,T}(timestamps_tz)
    end
end

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

const commonbranch_fields = [
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

""
function container(dict::Dict{Int, <:Any}, type::Vector{Tuple{String, DataType}})

    for (_,v) in dict
        for i in eachindex(type)
            if haskey(v, type[i][1]) == true
                v[type[i][1]] = type[i][2](v[type[i][1]])
            elseif type[i] in compositesystems_fields
                get!(v, type[i][1], type[i][2](0))
            else
                if type[i][1] == "rate_a" || type[i][1] == "rate_b"
                    get!(v, type[i][1], Inf32)
                end
            end
        end
    end

    tmp = Dict{String, Vector{<:Any}}(type[k][1] => [dict[i][type[k][1]] for i in eachindex(dict)] for k in 1:length(type))
    key_order::Vector{Int} = sortperm(tmp["index"])

    for (k,v) in tmp
        tmp[k] = v[key_order]
    end

    return tmp
    #return NamedTuple{Tuple(Symbol.(keys(tmp)))}(values(tmp))

end

""
function extract_reliability_data(file::String)

    reliability_data = open(file) do io
        matlab_data = InfrastructureModels.parse_matlab_string(read(io, String))
        reliability_data = _extract_reliability_data(matlab_data)
    end

    return Dict{String, Any}(reliability_data)
    
end

""
function _extract_reliability_data(matlab_data::Dict{String, Any})

    case = Dict{String,Any}()

    if haskey(matlab_data, "mpc.gen")
        gens = []
        for (i, gen_row) in enumerate(matlab_data["mpc.gen"])
            gen_data = InfrastructureModels.row_to_typed_dict(gen_row, r_gen)
            gen_data["index"] = i
            push!(gens, gen_data)
        end
        case["gen"] = gens
    else
        @error(string("no gen data found in matpower file.  The file seems to be missing \"mpc.gen = [...];\""))
    end

    if haskey(matlab_data, "mpc.storage")
        stors = []
        for (i, storage_row) in enumerate(matlab_data["mpc.storage"])
            storage_data = InfrastructureModels.row_to_typed_dict(storage_row, r_storage)
            storage_data["index"] = i
            push!(stors, storage_data)
        end
        case["storage"] = stors
    end

    if haskey(matlab_data, "mpc.branch")
        branches = []
        for (i, branch_row) in enumerate(matlab_data["mpc.branch"])
            branch_data = InfrastructureModels.row_to_typed_dict(branch_row, r_branch)
            branch_data["index"] = i
            push!(branches, branch_data)
        end
        case["branch"] = branches
    else
        @error(string("no branch table found in matpower file.  The file seems to be missing \"mpc.branch = [...];\""))
    end

    
    if haskey(matlab_data, "mpc.load")
        loads = []
        for (i, loads_row) in enumerate(matlab_data["mpc.load"])
            loadcost_data = InfrastructureModels.row_to_typed_dict(loads_row, r_load)
            loadcost_data["index"] = i
            push!(loads, loadcost_data)
        end
        case["load"] = loads

    end

    for (k,v) in case
        if isa(v, Array) && length(v) > 0 && isa(v[1], Dict)
            dict = Dict{String,Any}()
            for (i,item) in enumerate(v)
                if haskey(item, "index")
                    key = string(item["index"])
                end
                if !(haskey(dict, key))
                    dict[key] = item
                end
            end
            case[k] = dict
        end
    end

    return Dict{String, Any}(case)

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

"Returns network data container with reliability_data and timeseries_data merged"
function _merge_compositesystems_data!(network::Dict{Symbol, Any}, reliability_data::Dict{String, Any})

    for (k,v) in network[:gen]
        i = string(k)
        if haskey(reliability_data["gen"], i) 
            if v["gen_bus"] == reliability_data["gen"][i]["bus"] && v["pmax"]*v["mbase"] == reliability_data["gen"][i]["pmax"]
                get!(v, "state_model", reliability_data["gen"][i]["state_model"])
                get!(v, "λ_updn", reliability_data["gen"][i]["λ_updn"])
                get!(v, "μ_updn", reliability_data["gen"][i]["μ_updn"])
                get!(v, "λ_upde", reliability_data["gen"][i]["λ_upde"])
                get!(v, "μ_upde", reliability_data["gen"][i]["μ_upde"])
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
                get!(v, "λ_updn", reliability_data["storage"][i]["λ_updn"])
                get!(v, "μ_updn", reliability_data["storage"][i]["μ_updn"])
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
            get!(v, "λ_updn", reliability_data["branch"][i]["λ_updn"])
            get!(v, "μ_updn", reliability_data["branch"][i]["μ_updn"])
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
            if !haskey(network[:commonbranch], v["common_mode"])

                get!(network[:commonbranch], v["common_mode"], 
                    Dict("index"=>v["common_mode"], "f_bus"=> v["f_bus"], 
                    "t_bus"=> v["t_bus"], "λ_updn"=> v["λ_common"], 
                    "μ_updn"=> v["μ_common"], "br_1"=>parse(Int, k))
                )
            
            elseif haskey(network[:commonbranch], v["common_mode"]) && !haskey(v, "br_2")
                get!(network[:commonbranch][v["common_mode"]], "br_2", parse(Int, k))
            else
                @error("CommonBranches only supports two transmission lines between common buses")
            end
        end
    end
    return network

end

"Extracts time-series load data from excel file"
function extract_timeseriesload(file::String)

    dict_timeseries = Dict{Int, Vector{Float32}}()
    dict_core = Dict{Symbol, Any}()
    
    XLSX.openxlsx(file, enable_cache=false) do io
        for i in 1:XLSX.sheetcount(io)
            if XLSX.sheetnames(io)[i] == "core"
    
                dtable =  XLSX.readtable(file, XLSX.sheetnames(io)[i])
                for i in eachindex(dtable.column_labels)
                    get!(dict_core, dtable.column_labels[i], dtable.data[i])
                end
    
            elseif XLSX.sheetnames(io)[i] == "load" 
    
                dtable =  XLSX.readtable(file, XLSX.sheetnames(io)[i])
                for i in eachindex(dtable.column_labels)
                    if i > 1
                        get!(dict_timeseries, parse(Int, String(dtable.column_labels[i])), Float32.(dtable.data[i]))
                    end
                end
            end
        end
    end

    T::Type{<:Period} = timeunits[dict_core[:timestep_unit][1]]
    N::Int = dict_core[:timestep_count][1]
    L::Int = dict_core[:timestep_length][1]
    start_timestamp::DateTime = dict_core[:start_timestamp][1]
    timezone::String = dict_core[:timezone][1]
    SP = static_parameters{N,L,T}(start_timestamp, timezone)

    return dict_timeseries, SP

end

""
function convert_array(index_keys::Vector{Int}, timeseries_load::Dict{Int, Vector{Float32}}, baseMVA::Float32)

    if length(index_keys) ≠ length(collect(keys(timeseries_load)))
        @error("Time-series Load data file does not match length of load in network data file")
    end

    key_order_series = sortperm(collect(keys(timeseries_load)))

    container_timeseries = [Float32.(timeseries_load[i]/baseMVA) for i in keys(timeseries_load)]
    array::Array{Float32} = reduce(vcat,transpose.(container_timeseries[key_order_series]))

    return array

end

"Checks for inconsistencies between AbstractAsset and Power Model Network"
function _check_consistency(ref::Dict{Symbol,<:Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

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
        @assert Float32.(ref[:branch][k]["rate_b"]) == branches.rate_b[k]
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
function _check_connectivity(ref::Dict{Symbol,<:Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

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

""
function calc_buspair_parameters(branches::Branches, branch_lookup::Vector{Int})
 
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)
    bp_branch = Dict((bp, Int[]) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf32) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf32) for bp in buspair_indexes)
    #bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    
    for l in branch_lookup
        i = branches.f_bus[l]
        j = branches.t_bus[l]
        bp_angmin[(i,j)] = Float32(max(bp_angmin[(i,j)], branches.angmin[l]))
        bp_angmax[(i,j)] = Float32(min(bp_angmax[(i,j)], branches.angmax[l]))
        push!(bp_branch[(i,j)], l)
        #bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    
    buspairs = Dict((i,j) => [bp_branch[(i,j)],bp_angmin[(i,j)],bp_angmax[(i,j)]] for (i,j) in buspair_indexes)
        #"tap"=>Float32(branches.tap[bp_branch[(i,j)]]),
        #"vm_fr_min"=>Float32(field(buses, :vmin)[i]),
        #"vm_fr_max"=>Float32(field(buses, :vmax)[i]),
        #"vm_to_min"=>Float32(field(buses, :vmin)[j]),
        #"vm_to_max"=>Float32(field(buses, :vmax)[j]),
    
    # add optional parameters
    #for bp in buspair_indexes
    #    buspairs[bp]["rate_a"] = branches.rate_a[bp_branch[bp]]
    #end
    
    return buspairs

end
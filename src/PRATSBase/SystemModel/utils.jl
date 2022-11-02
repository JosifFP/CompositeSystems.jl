"Extracts data from excel file"
function extract(ReliabilityDataDir::String, files::Vector{String}, asset::Type{<:AbstractAssets}, container_1::Vector{Vector}, container_2::Vector{Vector{Any}})

    if in(files).("$asset"*".xlsx") == true
        XLSX.openxlsx(ReliabilityDataDir*"/"*"$asset"*".xlsx", enable_cache=false) do io
            for i in 1:XLSX.sheetcount(io)
                if XLSX.sheetnames(io)[i] == "time series MW" 
                    dtable =  XLSX.readtable("$asset"*".xlsx", XLSX.sheetnames(io)[i])
                    container_1[2], container_1[1] = dtable.data, dtable.column_labels
                elseif XLSX.sheetnames(io)[i] == "core"
                    dtable =  XLSX.readtable("$asset"*".xlsx",XLSX.sheetnames(io)[i])
                    container_2[2], container_2[1] = dtable.data, dtable.column_labels
                end
            end
        end
    else
        if asset == Loads || asset == Generators || asset == Branches
            error("file $asset.xlsx not found in $ReliabilityDataDir/ directory")
        end
    end

    dict_timeseries = Dict{Int, Any}(parse(Int, String(container_1[1][i])) => Float16.(container_1[2][i]) for i in 2:length(container_1[1]))
    dict_core = Dict{Any, Any}(container_2[1][i] => container_2[2][i] for i in 1:length(container_2[1]))

    return dict_timeseries, dict_core

end

"Creates AbstractAsset - Buses"
function container(network::Dict{Symbol, <:Any}, asset::Type{Buses})

    tmp = sort([[i, 
        Int(comp["zone"]),
        Int(comp["bus_type"]),
        Int(comp["index"]),
        Float16(comp["vmax"]),
        Float16(comp["vmin"]),
        Float16(comp["base_kv"]),
        Float32(comp["va"]),
        Float32(comp["vm"])] for (i,comp) in network[:bus]])
    #tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:bus])]]

    keys = Int.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(keys)

    container_data = Dict{Symbol, Any}(
        :keys => keys[key_order_core],
        :zone => Int.(reduce(vcat, tmp')[:,2])[key_order_core],
        :bus_type => Int.(reduce(vcat, tmp')[:,3])[key_order_core],
        :index => Int.(reduce(vcat, tmp')[:,4])[key_order_core],
        :vmax => Float16.(reduce(vcat, tmp')[:,5])[key_order_core],
        :vmin => Float16.(reduce(vcat, tmp')[:,6])[key_order_core],
        :base_kv => Float16.(reduce(vcat, tmp')[:,7])[key_order_core],
        :va => Float32.(reduce(vcat, tmp')[:,8])[key_order_core],
        :vm => Float32.(reduce(vcat, tmp')[:,9])[key_order_core]
    )

    return container_data

end

"Creates AbstractAsset - Generators"
function container(network::Dict{Symbol, <:Any}, asset::Type{Generators})

    tmp = sort([[i, 
        Int(comp["gen_bus"]),
        Float16(comp["pg"]),
        Float16(comp["qg"]),
        Float32(comp["vg"]),
        Float16(comp["pmax"]),
        Float16(comp["pmin"]),
        Float16(comp["qmax"]),
        Float16(comp["qmin"]),
        Int(comp["mbase"]),
        Float16.(comp["cost"]),
        Bool(comp["gen_status"])] for (i,comp) in network[:gen]])
    #tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:gen])]]

    keys = Int.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(keys)

    container_data = Dict{Symbol, Any}(
        :keys => keys[key_order_core],
        :buses => Int.(reduce(vcat, tmp')[:,2])[key_order_core],
        :pg => Float16.(reduce(vcat, tmp')[:,3])[key_order_core],
        :qg => Float16.(reduce(vcat, tmp')[:,4])[key_order_core],
        :vg => Float16.(reduce(vcat, tmp')[:,5])[key_order_core],
        :pmax => Float16.(reduce(vcat, tmp')[:,6])[key_order_core],
        :pmin => Float16.(reduce(vcat, tmp')[:,7])[key_order_core],
        :qmax => Float16.(reduce(vcat, tmp')[:,8])[key_order_core],
        :qmin => Float16.(reduce(vcat, tmp')[:,9])[key_order_core],
        :mbase => Int.(reduce(vcat, tmp')[:,10])[key_order_core],
        :cost => (reduce(vcat, tmp')[:,11])[key_order_core],
        :λ => zeros(Float64, length(keys)),
        :μ => zeros(Float64, length(keys)),
        :status => Bool.(reduce(vcat, tmp')[:,12])[key_order_core]
    )

    return container_data
    
end

"Creates AbstractAsset - Generators with time-series data"
function container(dict_core::Dict{<:Any}, dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Generators}, N, baseMVA)

    container_key = [i for i in keys(dict_timeseries)]
    key_order_series = sortperm(container_key)

    container_data = container(network, asset)

    if length(container_key) ≠ length(container_data[:keys])
        for i in container_data[:keys]
            if in(container_key).(i) == false
                setindex!(dict_timeseries, [container_data[:pg][i] for k in 1:N]*baseMVA, i)
            end
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]/baseMVA) for i in keys(dict_timeseries)]

    container_λ = Float64.(values(dict_core[Symbol("failurerate[f/year]")]))
    container_μ = Vector{Float64}(undef, length(values(dict_core[Symbol("repairtime[hrs]")])))

    for i in 1:length(values(dict_core[Symbol("repairtime[hrs]")]))
        if values(dict_core[Symbol("repairtime[hrs]")])[i]≠0.0
            container_μ[i] = Float64.(8736/values(dict_core[Symbol("repairtime[hrs]")])[i])
        else
            container_μ[i] = 0.0
        end
    end

    key_order_core = sortperm(container_data[:keys])

    container_data[:pg] = reduce(vcat,transpose.(container_timeseries[key_order_series]))
    container_data[:λ] = deepcopy(container_λ[key_order_core])
    container_data[:μ] = deepcopy(container_μ[key_order_core])

    return container_data

end

"Creates AbstractAsset - Loads"
function container(network::Dict{Symbol, <:Any}, asset::Type{Loads})

    for (i,load) in network[:load]
        get!(load, "cost", Float16(0.0))
    end

    tmp = sort([[i, 
        Int(comp["load_bus"]),
        Float16(comp["pd"]),
        Float16(comp["qd"]),
        Float16(comp["cost"]),
        Bool(comp["status"])] for (i,comp) in network[:load]])
    #tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:load])]]

    keys = Int.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(keys)

    container_data = Dict{Symbol, Any}(
        :keys => keys[key_order_core],
        :buses => Int.(reduce(vcat, tmp')[:,2])[key_order_core],
        :pd => Float16.(reduce(vcat, tmp')[:,3])[key_order_core],
        :qd => Float16.(reduce(vcat, tmp')[:,4])[key_order_core],
        :cost => Float16.(reduce(vcat, tmp')[:,5])[key_order_core],
        :status => Bool.(reduce(vcat, tmp')[:,6])[key_order_core]
    )

    return container_data

end

"Creates AbstractAsset - Loads with time-series data"
function container(dict_core::Dict{<:Any}, dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Loads}, N, baseMVA)

    container_key = [i for i in keys(dict_timeseries)]
    key_order_series = sortperm(container_key)
    container_data = container(network, asset)

    tmp_cost = Dict(Int(dict_core[:key][i]) => Float16(dict_core[Symbol("customerloss[USD/MWh]")][i]) for i in eachindex(dict_core[:key]))
    for (i,load) in network[:load]
        get!(load, "cost", tmp_cost[i])
    end

    for i in eachindex(container_data[:cost])
        container_data[:cost][i] = tmp_cost[i]
    end

    if isempty(dict_timeseries) error("Load data must be provided") end

    if length(container_key) ≠ length(container_data[:keys])
        for i in container_data[:keys]
            if in(container_key).(i) == false
                setindex!(dict_timeseries, [container_data[:pd][i] for k in 1:N]*baseMVA, i)
            end
            #get!(dict_timeseries_qd, i, Float16.(dict_timeseries_pd[i]*powerfactor))
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]/baseMVA) for i in keys(dict_timeseries)]
    container_data[:pd] = reduce(vcat,transpose.(container_timeseries[key_order_series]))

    return container_data

end

"Creates AbstractAsset - Branches"
function container(network::Dict{Symbol, <:Any}, asset::Type{Branches})

    tmp = sort([[i, 
        Int(comp["f_bus"]),
        Int(comp["t_bus"]),
        Float16(comp["rate_a"]),
        Float16(comp["rate_b"]),
        Float16(comp["br_r"]),
        Float16(comp["br_x"]),
        Float16(comp["b_fr"]),
        Float16(comp["b_to"]),
        Float16(comp["g_fr"]),
        Float16(comp["g_to"]),
        Float16(comp["shift"]),
        Float16(comp["angmin"]),
        Float16(comp["angmax"]),
        Bool(comp["transformer"]),
        Float16(comp["tap"]),
        Bool(comp["br_status"])] for (i,comp) in network[:branch]])
    #tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:branch])]]

    keys = Int.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(keys)

    container_data = Dict{Symbol, Any}(
        :keys => keys[key_order_core],
        :f_bus => Int.(reduce(vcat, tmp')[:,2])[key_order_core],
        :t_bus => Int.(reduce(vcat, tmp')[:,3])[key_order_core],
        :rate_a => Float16.(reduce(vcat, tmp')[:,4])[key_order_core],
        :rate_b => Float16.(reduce(vcat, tmp')[:,5])[key_order_core],
        :r => Float16.(reduce(vcat, tmp')[:,6])[key_order_core],
        :x => Float16.(reduce(vcat, tmp')[:,7])[key_order_core],
        :b_fr => Float16.(reduce(vcat, tmp')[:,8])[key_order_core],
        :b_to => Float16.(reduce(vcat, tmp')[:,9])[key_order_core],
        :g_fr => Float16.(reduce(vcat, tmp')[:,10])[key_order_core],
        :g_to => Float16.(reduce(vcat, tmp')[:,11])[key_order_core],
        :shift => Float16.(reduce(vcat, tmp')[:,12])[key_order_core],
        :angmin => Float16.(reduce(vcat, tmp')[:,13])[key_order_core],
        :angmax => Float16.(reduce(vcat, tmp')[:,14])[key_order_core],
        :transformer => Bool.(reduce(vcat, tmp')[:,15])[key_order_core],
        :tap => Float16.(reduce(vcat, tmp')[:,16])[key_order_core],
        :λ => zeros(Float64, length(keys)),
        :μ => zeros(Float64, length(keys)),
        :status => Bool.(reduce(vcat, tmp')[:,17])[key_order_core]
    )

    return container_data

end

"Creates AbstractAsset - Branches with time-series data"
function container(dict_core::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Branches}, N, B)

    container_data = container(network, asset)
    key_order_core = sortperm(container_data[:keys])

    container_λ = Float64.(values(dict_core[Symbol("failurerate[f/year]")]))
    container_μ = Vector{Float64}(undef, length(values(dict_core[Symbol("repairtime[hrs]")])))

    for i in 1:length(values(dict_core[Symbol("repairtime[hrs]")]))
        if values(dict_core[Symbol("repairtime[hrs]")])[i]≠0.0
            container_μ[i] = Float64.(N/values(dict_core[Symbol("repairtime[hrs]")])[i])
        else
            container_μ[i] = 0.0
        end
    end

    container_data[:λ] = deepcopy(container_λ[key_order_core])
    container_data[:μ] = deepcopy(container_μ[key_order_core])

    return container_data

end

"Creates AbstractAsset - Shunts"
function container(network::Dict{Symbol, <:Any}, asset::Type{Shunts})

    tmp = [
        [i, 
        Int(comp["shunt_bus"]),
        Float16(comp["bs"]),
        Float16(comp["gs"]),
        Bool(comp["status"])] for (i,comp) in sort(network[:shunt])]
    #tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:shunt])]]

    keys = Int.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(keys)

    container_data = Dict{Symbol, Any}(
        :keys => keys[key_order_core],
        :buses => Int.(reduce(vcat, tmp')[:,2])[key_order_core],
        :bs => Float16.(reduce(vcat, tmp')[:,3])[key_order_core],
        :gs => Float16.(reduce(vcat, tmp')[:,4])[key_order_core],
        :status => Bool.(reduce(vcat, tmp')[:,5])[key_order_core]
    )

    return container_data

end

"Checks for inconsistencies between AbstractAsset and Power Model Network"
function _check_consistency(ref::Dict{Symbol,<:Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

    for k in buses.keys
        @assert haskey(ref[:bus],k) === true
        @assert Int.(ref[:bus][k]["index"]) == buses.keys[k]
        @assert Int.(ref[:bus][k]["index"]) == buses.index[k]
        @assert Int.(ref[:bus][k]["bus_type"]) == buses.bus_type[k]
        @assert Float16.(ref[:bus][k]["vmax"]) == buses.vmax[k]
        @assert Float16.(ref[:bus][k]["vmin"]) == buses.vmin[k]
        @assert Float16.(ref[:bus][k]["base_kv"]) == buses.base_kv[k]
        @assert Float32.(ref[:bus][k]["va"]) == buses.va[k]
        @assert Float32.(ref[:bus][k]["vm"]) == buses.vm[k]
    end
    
    for k in generators.keys
        @assert haskey(ref[:gen],k) == true
        @assert Int.(ref[:gen][k]["index"]) == generators.keys[k]
        @assert Int.(ref[:gen][k]["gen_bus"]) == generators.buses[k]
        @assert Float16.(ref[:gen][k]["qg"]) == generators.qg[k]
        @assert Float16.(ref[:gen][k]["vg"]) == generators.vg[k]
        @assert Float16.(ref[:gen][k]["pmax"]) == generators.pmax[k]
        @assert Float16.(ref[:gen][k]["pmin"]) == generators.pmin[k]
        @assert Float16.(ref[:gen][k]["qmax"]) == generators.qmax[k]
        @assert Float16.(ref[:gen][k]["qmin"]) == generators.qmin[k]
        @assert Int.(ref[:gen][k]["mbase"]) == generators.mbase[k]
        @assert Bool.(ref[:gen][k]["gen_status"]) == generators.status[k]
    end
    
    for k in loads.keys
        @assert haskey(ref[:load],k) == true
        @assert Int.(ref[:load][k]["index"]) == loads.keys[k]
        @assert Int.(ref[:load][k]["load_bus"]) == loads.buses[k]
        @assert Float16.(ref[:load][k]["qd"]) == loads.qd[k]
        @assert Bool.(ref[:load][k]["status"]) == loads.status[k]
    end
    
    for k in branches.keys
        @assert haskey(ref[:branch],k) == true
        @assert Int.(ref[:branch][k]["index"]) == branches.keys[k]
        @assert Int.(ref[:branch][k]["f_bus"]) == branches.f_bus[k]
        @assert Int.(ref[:branch][k]["t_bus"]) == branches.t_bus[k]
        @assert Float16.(ref[:branch][k]["rate_a"]) == branches.rate_a[k]
        @assert Float16.(ref[:branch][k]["rate_b"]) == branches.rate_b[k]
        @assert Float16.(ref[:branch][k]["br_r"]) == branches.r[k]
        @assert Float16.(ref[:branch][k]["br_x"]) == branches.x[k]
        @assert Float16.(ref[:branch][k]["b_fr"]) == branches.b_fr[k]
        @assert Float16.(ref[:branch][k]["b_to"]) == branches.b_to[k]
        @assert Float16.(ref[:branch][k]["g_fr"]) == branches.g_fr[k]
        @assert Float16.(ref[:branch][k]["g_to"]) == branches.g_to[k]
        @assert Float16.(ref[:branch][k]["shift"]) == branches.shift[k]
        @assert Float16.(ref[:branch][k]["angmin"]) == branches.angmin[k]
        @assert Float16.(ref[:branch][k]["angmax"]) == branches.angmax[k]
        @assert Bool.(ref[:branch][k]["transformer"]) == branches.transformer[k]
        @assert Float16.(ref[:branch][k]["tap"]) == branches.tap[k]
        @assert Bool.(ref[:branch][k]["br_status"]) == branches.status[k]
    end
    
    for k in shunts.keys
        @assert haskey(ref[:shunt],k) == true
        @assert Int.(ref[:shunt][k]["index"]) == shunts.keys[k]
        @assert Int.(ref[:shunt][k]["shunt_bus"]) == shunts.buses[k]
        @assert Float16.(ref[:shunt][k]["bs"]) == shunts.bs[k]
        @assert Float16.(ref[:shunt][k]["gs"]) == shunts.gs[k]
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
    active_bus_ids = Set(bus["index"] for (i,bus) in ref[:bus] if bus["bus_type"] != 4)

    for (i, gen) in ref[:gen]
        if !(gen["gen_bus"] in buses.keys) || !(generators.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(gen["gen_bus"]) in shunt $(i) is not defined")
        end
        if gen["gen_status"] != 0 && !(gen["gen_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active generator $(i) is connected to inactive bus $(gen["gen_bus"])")
        end
    end

    for (i, load) in ref[:load]
        if !(load["load_bus"] in buses.keys) || !(loads.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(load["load_bus"]) in load $(i) is not defined")
        end

        if load["status"] != 0 && !(load["load_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active load $(i) is connected to inactive bus $(load["load_bus"])")
        end       
    end

    for (i, shunt) in ref[:shunt]
        if !(shunt["shunt_bus"] in buses.keys) || !(shunts.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(shunt["shunt_bus"]) in shunt $(i) is not defined")
        end
        if shunt["status"] != 0 && !(shunt["shunt_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active shunt $(i) is connected to inactive bus $(shunt["shunt_bus"])")
        end
    end

    for (i, strg) in ref[:storage]
        if !(strg["storage_bus"] in buses.keys) || !(storages.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(strg["storage_bus"]) in shunt $(i) is not defined")
        end
        if strg["status"] != 0 && !(strg["storage_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active storage unit $(i) is connected to inactive bus $(strg["storage_bus"])")
        end
    end
    
    for (i, branch) in ref[:branch]
        if !(branch["f_bus"] in buses.keys) || !(branches.f_bus[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(branch["f_bus"]) in shunt $(i) is not defined")
        end
        if !(branch["t_bus"] in buses.keys) || !(branches.t_bus[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(branch["t_bus"]) in shunt $(i) is not defined")
        end
        if branch["br_status"] != 0 && !(branch["f_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active branch $(i) is connected to inactive bus $(branch["f_bus"])")
        end

        if branch["br_status"] != 0 && !(branch["t_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active branch $(i) is connected to inactive bus $(branch["t_bus"])")
        end

        # if dcline["br_status"] != 0 && !(dcline["f_bus"] in active_bus_ids)
        #     Memento.warn(_LOGGER, "active dcline $(i) is connected to inactive bus $(dcline["f_bus"])")
        # end

        # if dcline["br_status"] != 0 && !(dcline["t_bus"] in active_bus_ids)
        #     Memento.warn(_LOGGER, "active dcline $(i) is connected to inactive bus $(dcline["t_bus"])")
        # end
    end

end

""
function calc_buspair_parameters(branches::Branches, branch_lookup::Vector{Int})
 
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)
    
    for l in branch_lookup
        i = branches.f_bus[l]
        j = branches.t_bus[l]
        bp_angmin[(i,j)] = Float16(max(bp_angmin[(i,j)], branches.angmin[l]))
        bp_angmax[(i,j)] = Float16(min(bp_angmax[(i,j)], branches.angmax[l]))
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    
    buspairs = Dict((i,j) => [bp_branch[(i,j)],bp_angmin[(i,j)],bp_angmax[(i,j)]] for (i,j) in buspair_indexes)
        #"tap"=>Float16(branches.tap[bp_branch[(i,j)]]),
        #"vm_fr_min"=>Float16(field(buses, :vmin)[i]),
        #"vm_fr_max"=>Float16(field(buses, :vmax)[i]),
        #"vm_to_min"=>Float16(field(buses, :vmin)[j]),
        #"vm_to_max"=>Float16(field(buses, :vmax)[j]),
    
    # add optional parameters
    #for bp in buspair_indexes
    #    buspairs[bp]["rate_a"] = branches.rate_a[bp_branch[bp]]
    #end
    
    return buspairs

end

"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses, branches)

    bus_lookup = Dict(bus["index"] => bus for (i,bus) in buses if bus["bus_type"] ≠ 4)
    branch_lookup = Dict(branch["index"] => branch for (i,branch) in branches if branch["br_status"] == 1 && 
        haskey(bus_lookup, branch["f_bus"]) && haskey(bus_lookup, branch["t_bus"]))
    buspair_indexes = Set((branch["f_bus"], branch["t_bus"]) for (i,branch) in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)

    for (l,branch) in branch_lookup
        i = branch["f_bus"]
        j = branch["t_bus"]
        bp_angmin[(i,j)] = max(bp_angmin[(i,j)], branch["angmin"])
        bp_angmax[(i,j)] = min(bp_angmax[(i,j)], branch["angmax"])
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end

    buspairs = Dict((i,j) => Dict(
        "branch"=>bp_branch[(i,j)],
        "angmin"=>bp_angmin[(i,j)],
        "angmax"=>bp_angmax[(i,j)],
        "tap"=>branch_lookup[bp_branch[(i,j)]]["tap"],
        #"vm_fr_min"=>bus_lookup[i]["vmin"],
        #"vm_fr_max"=>bus_lookup[i]["vmax"],
        #"vm_to_min"=>bus_lookup[j]["vmin"],
        #"vm_to_max"=>bus_lookup[j]["vmax"]
        ) for (i,j) in buspair_indexes
    )

    # add optional parameters
    for bp in buspair_indexes
        branch = branch_lookup[bp_branch[bp]]
        if haskey(branch, "rate_a")
            buspairs[bp]["rate_a"] = branch["rate_a"]
        end
        if haskey(branch, "c_rating_a")
            buspairs[bp]["c_rating_a"] = branch["c_rating_a"]
        end
    end

    return buspairs
end
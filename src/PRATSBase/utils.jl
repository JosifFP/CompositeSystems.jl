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
        if asset == Loads || asset == Generators
            error("file $asset.xlsx not found in $ReliabilityDataDir/ directory")
        end
    end

    return Dict(parse(Int, String(container_1[1][i])) => Float16.(container_1[2][i]) for i in 2:length(container_1[1])), 
    Dict(container_2[1][i] => container_2[2][i] for i in 1:length(container_2[1]))

end

"Creates AbstractAsset - Buses"
function container(network::Dict{Symbol, <:Any}, asset::Type{Buses}, S::Int, N::Int, L::Int, T::Type{<:Period})

    tmp = [[i, 
        Int(comp["zone"]),
        Int(comp["bus_type"]),
        Int(comp["area"]),
        Int(comp["index"]),
        Float16(comp["vmax"]),
        Float16(comp["vmin"]),
        Float16(comp["base_kv"]),
        Float32(comp["va"]),
        Float32(comp["vm"])] for (i,comp) in sort(network[:bus])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:bus])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :zone => Int.(reduce(vcat, tmp')[:,2]),
        :bus_type => Int.(reduce(vcat, tmp')[:,3]),
        :area => Int.(reduce(vcat, tmp')[:,4]),
        :index => Int.(reduce(vcat, tmp')[:,5]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :vmax => Float16.(reduce(vcat, tmp')[:,6]),
        :vmin => Float16.(reduce(vcat, tmp')[:,7]),
        :base_kv => Float16.(reduce(vcat, tmp')[:,8]),
        :va => Float32.(reduce(vcat, tmp')[:,9]),
        :vm => Float32.(reduce(vcat, tmp')[:,10])
    )

    key_order_core = sortperm(container_data[:keys])

    return asset{N,L,T,S}(
        container_data[:keys][key_order_core],
        container_data[:zone][key_order_core],
        container_data[:bus_type][key_order_core],
        container_data[:area][key_order_core],
        container_data[:index][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:vmax][key_order_core],
        container_data[:vmin][key_order_core],
        container_data[:base_kv][key_order_core],
        container_data[:va][key_order_core],
        container_data[:vm][key_order_core])

end

"Creates AbstractAsset - Generators"
function container(container_key::Vector{<:Any}, key_order_series::Vector{<:Any}, dict_core::Dict{<:Any}, 
    dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Generators}, S::Int, N::Int, L::Int, T::Type{<:Period})

    tmp = [[i, 
        Int(comp["gen_bus"]),
        Float16(comp["pg"]),
        Float16(comp["qg"]),
        Float32(comp["vg"]),
        Float16(comp["pmax"]),
        Float16(comp["pmin"]),
        Float16(comp["qmax"]),
        Float16(comp["qmin"]),
        Int(comp["mbase"]),
        Bool(comp["gen_status"]),
        Float16.(comp["cost"])] for (i,comp) in sort(network[:gen])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:gen])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :buses => Int.(reduce(vcat, tmp')[:,2]),
        :pg => Float16.(reduce(vcat, tmp')[:,3]),
        :qg => Float16.(reduce(vcat, tmp')[:,4]),
        :vg => Float32.(reduce(vcat, tmp')[:,5]),
        :pmax => Float16.(reduce(vcat, tmp')[:,6]),
        :pmin => Float16.(reduce(vcat, tmp')[:,7]),
        :qmax => Float16.(reduce(vcat, tmp')[:,8]),
        :qmin => Float16.(reduce(vcat, tmp')[:,9]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :mbase => Int.(reduce(vcat, tmp')[:,10]),
        :status => Bool.(reduce(vcat, tmp')[:,11]),
        :cost => (reduce(vcat, tmp')[:,12])
    )

    key_order_core = sortperm(container_data[:keys])

    if length(container_key) ≠ length(container_data[:keys])
        for i in container_data[:keys]
            if in(container_key).(i) == false
                setindex!(dict_timeseries, [container_data[:pg][i] for k in 1:N]*S, i)
            end
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]/S) for i in keys(dict_timeseries)]

    container_λ = Float64.(values(dict_core[Symbol("failurerate[f/year]")]))
    container_μ = Vector{Float64}(undef, length(values(dict_core[Symbol("repairtime[hrs]")])))

    for i in 1:length(values(dict_core[Symbol("repairtime[hrs]")]))
        if values(dict_core[Symbol("repairtime[hrs]")])[i]≠0.0
            container_μ[i] = Float64.(8760/values(dict_core[Symbol("repairtime[hrs]")])[i])
        else
            container_μ[i] = 0.0
        end
    end

    return asset{N,L,T,S}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],
        reduce(vcat,transpose.(container_timeseries[key_order_series])),
        container_data[:qg][key_order_core],
        container_data[:vg][key_order_core],
        container_data[:pmax][key_order_core],
        container_data[:pmin][key_order_core],
        container_data[:qmax][key_order_core],
        container_data[:qmin][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:mbase][key_order_core],
        container_data[:status][key_order_core],
        container_data[:cost][key_order_core],
        container_λ[key_order_core], 
        container_μ[key_order_core])
end

"Creates AbstractAsset - Loads"
function container(container_key::Vector{<:Any}, key_order_series::Vector{<:Any}, dict_core::Dict{<:Any}, 
    dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Loads}, S::Int, N::Int, L::Int, T::Type{<:Period})

    tmp_cost = Dict(Int(dict_core[:key][i]) => Float16(dict_core[Symbol("customerloss[USD/MWh]")][i]) for i in eachindex(dict_core[:key]))
    for (i,load) in network[:load]
        get!(load, "cost", tmp_cost[i])
    end

    tmp = [[i, 
        Int(comp["load_bus"]),
        Float16(comp["pd"]),
        Float16(comp["qd"]),
        Bool(comp["status"]),
        Float16(comp["cost"])] for (i,comp) in sort(network[:load])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:load])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :buses => Int.(reduce(vcat, tmp')[:,2]),
        :pd => Float16.(reduce(vcat, tmp')[:,3]),
        :qd => Float16.(reduce(vcat, tmp')[:,4]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :status => Bool.(reduce(vcat, tmp')[:,5]),
        :cost => Float16.(reduce(vcat, tmp')[:,6])
    )

    key_order_core = sortperm(container_data[:keys])
    if isempty(dict_timeseries) error("Load data must be provided") end
    #dict_timeseries_qd = Dict{Int, Any}()
    #powerfactor = Float32.(container_data[:pd]/container_data[:qd])

    if length(container_key) ≠ length(container_data[:keys])
        for i in container_data[:keys]
            if in(container_key).(i) == false
                setindex!(dict_timeseries, [container_data[:pd][i] for k in 1:N]*S, i)
            end
            #get!(dict_timeseries_qd, i, Float16.(dict_timeseries_pd[i]*powerfactor))
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]/S) for i in keys(dict_timeseries)]
    nloads = length(container_data[:keys])

    return asset{N,L,T,S}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],    
        reduce(vcat,transpose.(container_timeseries[key_order_series])),
        container_data[:qd][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core],
        container_data[:cost][key_order_core])

end

"Creates AbstractAsset - Branches"
function container(dict_core::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Branches}, S::Int, N::Int, L::Int, T::Type{<:Period})

    tmp = [[i, 
        Int(comp["f_bus"]),
        Int(comp["t_bus"]),
        Float16(comp["rate_a"]),
        Float16(comp["rate_b"]),
        Float16(comp["rate_c"]),
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
        Bool(comp["br_status"])] for (i,comp) in sort(network[:branch])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:branch])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :f_bus => Int.(reduce(vcat, tmp')[:,2]),
        :t_bus => Int.(reduce(vcat, tmp')[:,3]),
        :rate_a => Float16.(reduce(vcat, tmp')[:,4]),
        :rate_b => Float16.(reduce(vcat, tmp')[:,5]),
        :rate_c => Float16.(reduce(vcat, tmp')[:,6]),
        :r => Float16.(reduce(vcat, tmp')[:,7]),
        :x => Float16.(reduce(vcat, tmp')[:,8]),
        :b_fr => Float16.(reduce(vcat, tmp')[:,9]),
        :b_to => Float16.(reduce(vcat, tmp')[:,10]),
        :g_fr => Float16.(reduce(vcat, tmp')[:,11]),
        :g_to => Float16.(reduce(vcat, tmp')[:,12]),
        :shift => Float16.(reduce(vcat, tmp')[:,13]),
        :angmin => Float16.(reduce(vcat, tmp')[:,14]),
        :angmax => Float16.(reduce(vcat, tmp')[:,15]),
        :transformer => Bool.(reduce(vcat, tmp')[:,16]),
        :tap => Float16.(reduce(vcat, tmp')[:,17]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :status => Bool.(reduce(vcat, tmp')[:,18])
    )

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

    return asset{N,L,T,S}(
        container_data[:keys][key_order_core],
        container_data[:f_bus][key_order_core],
        container_data[:t_bus][key_order_core],
        container_data[:rate_a][key_order_core],
        container_data[:rate_b][key_order_core],
        container_data[:rate_c][key_order_core],
        container_data[:r][key_order_core],
        container_data[:x][key_order_core],
        container_data[:b_fr][key_order_core],
        container_data[:b_to][key_order_core],
        container_data[:g_fr][key_order_core],
        container_data[:g_to][key_order_core],
        container_data[:shift][key_order_core],
        container_data[:angmin][key_order_core],
        container_data[:angmax][key_order_core],
        container_data[:transformer][key_order_core],
        container_data[:tap][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core],
        container_λ[key_order_core], 
        container_μ[key_order_core])
end

"Creates AbstractAsset - Shunts"
function container(network::Dict{Symbol, <:Any}, asset::Type{Shunts}, S::Int, N::Int, L::Int, T::Type{<:Period})

    tmp = [
        [i, 
        Int(comp["shunt_bus"]),
        Float16(comp["bs"]),
        Float16(comp["gs"]),
        Bool(comp["status"])] for (i,comp) in sort(network[:shunt])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:shunt])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :buses => Int.(reduce(vcat, tmp')[:,2]),
        :bs => Float16.(reduce(vcat, tmp')[:,3]),
        :gs => Float16.(reduce(vcat, tmp')[:,4]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :status => Bool.(reduce(vcat, tmp')[:,5])
    )

    key_order_core = sortperm(container_data[:keys])

    return asset{N,L,T,S}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],
        container_data[:bs][key_order_core],
        container_data[:gs][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core])

end

"Checks for inconsistencies between AbstractAsset and Power Model Network"
function _check_consistency(ref::Dict{Symbol,<:Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

    for k in buses.keys
        @assert haskey(ref[:bus],k) == true
        @assert Int.(ref[:bus][k]["index"]) == buses.keys[k]
        @assert Int.(ref[:bus][k]["index"]) == buses.index[k]
        @assert Int.(ref[:bus][k]["area"]) == buses.area[k]
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
        @assert Float32.(ref[:gen][k]["vg"]) == generators.vg[k]
        @assert Float16.(ref[:gen][k]["pmax"]) == generators.pmax[k]
        @assert Float16.(ref[:gen][k]["pmin"]) == generators.pmin[k]
        @assert Float16.(ref[:gen][k]["qmax"]) == generators.qmax[k]
        @assert Float16.(ref[:gen][k]["qmin"]) == generators.qmin[k]
        @assert Int.(ref[:gen][k]["mbase"]) == generators.mbase[k]
        @assert Bool.(ref[:gen][k]["gen_status"]) == generators.status[k]
        #@assert (ref[:gen][k]["cost"]) == generators.cost[k]
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
        @assert Float16.(ref[:branch][k]["rate_c"]) == branches.rate_c[k]
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